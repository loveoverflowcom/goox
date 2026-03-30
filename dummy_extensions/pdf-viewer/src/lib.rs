use lopdf::Document;
use std::sync::Mutex;

// ERP host functions provided by the Goox runtime
#[link(wasm_import_module = "env")]
unsafe extern "C" {
    fn erp_set_output_buffer(ptr: *const u8, len: usize);
    fn erp_report_error(ptr: *const u8, len: usize);
}

fn report_error(msg: &str) {
    unsafe { erp_report_error(msg.as_ptr(), msg.len()); }
}

// ── State ────────────────────────────────────────────────────────────────────

struct PdfState {
    doc: Document,
    page_count: usize,
}

static STATE: Mutex<Option<PdfState>> = Mutex::new(None);
static OUTPUT: Mutex<Vec<u8>> = Mutex::new(Vec::new());

// ── ERP exports ──────────────────────────────────────────────────────────────

/// Called by the runtime to open a file.
/// `file_ptr/file_len` = filename string (e.g. "jfp.pdf").
/// The runtime preopens the file's parent directory as /data,
/// so we open /data/<filename>.
#[unsafe(no_mangle)]
pub extern "C" fn erp_open(file_ptr: *const u8, file_len: usize) -> i32 {
    if file_len == 0 {
        report_error("pdf-viewer: empty filename");
        return -1;
    }
    let filename = unsafe {
        let bytes = core::slice::from_raw_parts(file_ptr, file_len);
        match std::str::from_utf8(bytes) {
            Ok(s) => s.to_owned(),
            Err(_) => { report_error("pdf-viewer: invalid filename utf8"); return -1; }
        }
    };
    let path = format!("/data/{filename}");
    match Document::load(&path) {
        Ok(doc) => {
            let page_count = doc.get_pages().len();
            if let Ok(mut state) = STATE.lock() {
                *state = Some(PdfState { doc, page_count });
            }
            0
        }
        Err(e) => {
            let msg = format!("pdf-viewer: failed to load {path}: {e}");
            report_error(&msg);
            -1
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn erp_page_count() -> i32 {
    STATE.lock().ok()
        .and_then(|s| s.as_ref().map(|p| p.page_count as i32))
        .unwrap_or(-1)
}

/// Render page at `page_index` into an RGBA pixel buffer of `width × height`.
/// Text lines are drawn as white text on a white background using a 1-bit
/// bitmap font (8×8 per glyph). This is a best-effort software renderer —
/// it extracts plain text from the PDF page and lays it out line by line.
#[unsafe(no_mangle)]
pub extern "C" fn erp_render_page(page_index: i32, width: i32, height: i32) -> i32 {
    if page_index < 0 || width <= 0 || height <= 0 {
        report_error("pdf-viewer: invalid render arguments");
        return -1;
    }
    let w = width as usize;
    let h = height as usize;

    let text = extract_page_text(page_index as u32);

    // White background
    let mut buf = vec![255u8; w * h * 4];

    // Draw text lines
    let font_w = 6usize;
    let font_h = 10usize;
    let margin = 16usize;
    let line_height = font_h + 2;
    let max_cols = (w.saturating_sub(margin * 2)) / font_w;

    let mut row = margin;
    'outer: for line in text.lines() {
        let chars: Vec<char> = line.chars().collect();
        let mut col_start = 0;
        while col_start < chars.len() {
            let end = (col_start + max_cols).min(chars.len());
            let chunk: String = chars[col_start..end].iter().collect();
            draw_text_line(&mut buf, w, h, margin, row, &chunk, font_w, font_h);
            row += line_height;
            if row + font_h > h { break 'outer; }
            col_start = end;
        }
        row += line_height;
        if row + font_h > h { break; }
    }

    if let Ok(mut out) = OUTPUT.lock() {
        *out = buf;
        let len = out.len();
        unsafe { erp_set_output_buffer(out.as_ptr(), len); }
        len as i32
    } else {
        report_error("pdf-viewer: output buffer lock failed");
        -1
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn erp_close() {
    if let Ok(mut s) = STATE.lock() { *s = None; }
    if let Ok(mut o) = OUTPUT.lock() { o.clear(); }
}

// ── Text extraction ───────────────────────────────────────────────────────────

fn extract_page_text(page_index: u32) -> String {
    let guard = match STATE.lock() {
        Ok(g) => g,
        Err(_) => return String::new(),
    };
    let state = match guard.as_ref() {
        Some(s) => s,
        None => return String::new(),
    };

    // lopdf page numbers are 1-based
    let page_num = page_index + 1;
    let pages = state.doc.get_pages();
    let page_id = match pages.get(&page_num) {
        Some(id) => *id,
        None => return format!("[Page {} not found]", page_num),
    };

    match state.doc.extract_text(&[page_num]) {
        Ok(text) => text,
        Err(e) => format!("[Could not extract text: {e}]"),
    }
}

// ── Bitmap font renderer ──────────────────────────────────────────────────────
// Simple 6×10 bitmap font for ASCII 32–126.
// Each char is encoded as 10 rows × 6 bits (MSB = leftmost pixel).

fn draw_text_line(
    buf: &mut [u8],
    w: usize,
    h: usize,
    x: usize,
    y: usize,
    text: &str,
    font_w: usize,
    font_h: usize,
) {
    for (i, ch) in text.chars().enumerate() {
        let cx = x + i * font_w;
        if cx + font_w > w { break; }
        draw_char(buf, w, h, cx, y, ch, font_h);
    }
}

fn draw_char(buf: &mut [u8], w: usize, h: usize, x: usize, y: usize, ch: char, font_h: usize) {
    let glyph = glyph_for(ch);
    for row in 0..font_h {
        let bits = glyph[row];
        for col in 0..6usize {
            let px = x + col;
            let py = y + row;
            if px >= w || py >= h { continue; }
            let on = (bits >> (5 - col)) & 1 == 1;
            if on {
                let idx = (py * w + px) * 4;
                buf[idx] = 30;
                buf[idx + 1] = 30;
                buf[idx + 2] = 30;
                buf[idx + 3] = 255;
            }
        }
    }
}

/// Returns a 10-row × 6-bit glyph for the given ASCII character.
/// Falls back to a small rectangle for unknown chars.
fn glyph_for(ch: char) -> [u8; 10] {
    match ch {
        ' ' => [0,0,0,0,0,0,0,0,0,0],
        'A' => [0b001100,0b010010,0b100001,0b100001,0b111111,0b100001,0b100001,0b100001,0,0],
        'B' => [0b111110,0b100001,0b100001,0b111110,0b100001,0b100001,0b100001,0b111110,0,0],
        'C' => [0b011110,0b100001,0b100000,0b100000,0b100000,0b100000,0b100001,0b011110,0,0],
        'D' => [0b111100,0b100010,0b100001,0b100001,0b100001,0b100001,0b100010,0b111100,0,0],
        'E' => [0b111111,0b100000,0b100000,0b111110,0b100000,0b100000,0b100000,0b111111,0,0],
        'F' => [0b111111,0b100000,0b100000,0b111110,0b100000,0b100000,0b100000,0b100000,0,0],
        'G' => [0b011110,0b100001,0b100000,0b100000,0b100111,0b100001,0b100001,0b011111,0,0],
        'H' => [0b100001,0b100001,0b100001,0b111111,0b100001,0b100001,0b100001,0b100001,0,0],
        'I' => [0b111111,0b001100,0b001100,0b001100,0b001100,0b001100,0b001100,0b111111,0,0],
        'J' => [0b011111,0b000100,0b000100,0b000100,0b000100,0b100100,0b100100,0b011000,0,0],
        'K' => [0b100001,0b100010,0b100100,0b111000,0b101000,0b100100,0b100010,0b100001,0,0],
        'L' => [0b100000,0b100000,0b100000,0b100000,0b100000,0b100000,0b100000,0b111111,0,0],
        'M' => [0b100001,0b110011,0b101101,0b100101,0b100001,0b100001,0b100001,0b100001,0,0],
        'N' => [0b100001,0b110001,0b101001,0b100101,0b100011,0b100001,0b100001,0b100001,0,0],
        'O' => [0b011110,0b100001,0b100001,0b100001,0b100001,0b100001,0b100001,0b011110,0,0],
        'P' => [0b111110,0b100001,0b100001,0b111110,0b100000,0b100000,0b100000,0b100000,0,0],
        'Q' => [0b011110,0b100001,0b100001,0b100001,0b100101,0b100011,0b100001,0b011111,0,0],
        'R' => [0b111110,0b100001,0b100001,0b111110,0b101000,0b100100,0b100010,0b100001,0,0],
        'S' => [0b011111,0b100000,0b100000,0b011110,0b000001,0b000001,0b000001,0b111110,0,0],
        'T' => [0b111111,0b001100,0b001100,0b001100,0b001100,0b001100,0b001100,0b001100,0,0],
        'U' => [0b100001,0b100001,0b100001,0b100001,0b100001,0b100001,0b100001,0b011110,0,0],
        'V' => [0b100001,0b100001,0b100001,0b100001,0b010010,0b010010,0b001100,0b001100,0,0],
        'W' => [0b100001,0b100001,0b100001,0b100101,0b101101,0b110011,0b100001,0b100001,0,0],
        'X' => [0b100001,0b010010,0b001100,0b001100,0b001100,0b010010,0b100001,0b100001,0,0],
        'Y' => [0b100001,0b010010,0b001100,0b001100,0b001100,0b001100,0b001100,0b001100,0,0],
        'Z' => [0b111111,0b000010,0b000100,0b001000,0b010000,0b100000,0b100000,0b111111,0,0],
        'a' => [0,0,0b011110,0b000001,0b011111,0b100001,0b100011,0b011101,0,0],
        'b' => [0b100000,0b100000,0b111110,0b100001,0b100001,0b100001,0b100001,0b111110,0,0],
        'c' => [0,0,0b011110,0b100001,0b100000,0b100000,0b100001,0b011110,0,0],
        'd' => [0b000001,0b000001,0b011111,0b100001,0b100001,0b100001,0b100001,0b011111,0,0],
        'e' => [0,0,0b011110,0b100001,0b111111,0b100000,0b100000,0b011111,0,0],
        'f' => [0b001111,0b010000,0b010000,0b111110,0b010000,0b010000,0b010000,0b010000,0,0],
        'g' => [0,0,0b011111,0b100001,0b100001,0b011111,0b000001,0b111110,0,0],
        'h' => [0b100000,0b100000,0b111110,0b100001,0b100001,0b100001,0b100001,0b100001,0,0],
        'i' => [0b001100,0,0b011100,0b001100,0b001100,0b001100,0b001100,0b111111,0,0],
        'j' => [0b000110,0,0b000110,0b000110,0b000110,0b000110,0b100110,0b011100,0,0],
        'k' => [0b100000,0b100000,0b100010,0b100100,0b111000,0b101000,0b100100,0b100010,0,0],
        'l' => [0b011100,0b001100,0b001100,0b001100,0b001100,0b001100,0b001100,0b111111,0,0],
        'm' => [0,0,0b110110,0b101101,0b100101,0b100001,0b100001,0b100001,0,0],
        'n' => [0,0,0b111110,0b100001,0b100001,0b100001,0b100001,0b100001,0,0],
        'o' => [0,0,0b011110,0b100001,0b100001,0b100001,0b100001,0b011110,0,0],
        'p' => [0,0,0b111110,0b100001,0b100001,0b111110,0b100000,0b100000,0,0],
        'q' => [0,0,0b011111,0b100001,0b100001,0b011111,0b000001,0b000001,0,0],
        'r' => [0,0,0b101111,0b110000,0b100000,0b100000,0b100000,0b100000,0,0],
        's' => [0,0,0b011111,0b100000,0b011110,0b000001,0b000001,0b111110,0,0],
        't' => [0b010000,0b010000,0b111110,0b010000,0b010000,0b010000,0b010001,0b001110,0,0],
        'u' => [0,0,0b100001,0b100001,0b100001,0b100001,0b100011,0b011101,0,0],
        'v' => [0,0,0b100001,0b100001,0b010010,0b010010,0b001100,0b001100,0,0],
        'w' => [0,0,0b100001,0b100001,0b100101,0b101101,0b110011,0b100001,0,0],
        'x' => [0,0,0b100001,0b010010,0b001100,0b001100,0b010010,0b100001,0,0],
        'y' => [0,0,0b100001,0b100001,0b011111,0b000001,0b100001,0b011110,0,0],
        'z' => [0,0,0b111111,0b000010,0b000100,0b001000,0b010000,0b111111,0,0],
        '0' => [0b011110,0b100011,0b100101,0b101001,0b110001,0b100001,0b100001,0b011110,0,0],
        '1' => [0b001100,0b011100,0b001100,0b001100,0b001100,0b001100,0b001100,0b111111,0,0],
        '2' => [0b011110,0b100001,0b000001,0b000110,0b011000,0b100000,0b100000,0b111111,0,0],
        '3' => [0b111111,0b000010,0b000100,0b001110,0b000001,0b000001,0b100001,0b011110,0,0],
        '4' => [0b000110,0b001010,0b010010,0b100010,0b111111,0b000010,0b000010,0b000010,0,0],
        '5' => [0b111111,0b100000,0b100000,0b111110,0b000001,0b000001,0b100001,0b011110,0,0],
        '6' => [0b011110,0b100001,0b100000,0b111110,0b100001,0b100001,0b100001,0b011110,0,0],
        '7' => [0b111111,0b000001,0b000010,0b000100,0b001000,0b010000,0b010000,0b010000,0,0],
        '8' => [0b011110,0b100001,0b100001,0b011110,0b100001,0b100001,0b100001,0b011110,0,0],
        '9' => [0b011110,0b100001,0b100001,0b011111,0b000001,0b000001,0b100001,0b011110,0,0],
        '.' => [0,0,0,0,0,0,0b011000,0b011000,0,0],
        ',' => [0,0,0,0,0,0,0b011000,0b011000,0b010000,0],
        ':' => [0,0b011000,0b011000,0,0,0b011000,0b011000,0,0,0],
        ';' => [0,0b011000,0b011000,0,0,0b011000,0b011000,0b010000,0,0],
        '!' => [0b001100,0b001100,0b001100,0b001100,0b001100,0,0b001100,0b001100,0,0],
        '?' => [0b011110,0b100001,0b000001,0b000110,0b001100,0b001100,0,0b001100,0,0],
        '-' => [0,0,0,0b111111,0,0,0,0,0,0],
        '_' => [0,0,0,0,0,0,0,0b111111,0,0],
        '(' => [0b000110,0b001100,0b011000,0b011000,0b011000,0b011000,0b001100,0b000110,0,0],
        ')' => [0b110000,0b011000,0b001100,0b001100,0b001100,0b001100,0b011000,0b110000,0,0],
        '[' => [0b011110,0b010000,0b010000,0b010000,0b010000,0b010000,0b010000,0b011110,0,0],
        ']' => [0b011110,0b000010,0b000010,0b000010,0b000010,0b000010,0b000010,0b011110,0,0],
        '/' => [0b000001,0b000010,0b000100,0b001000,0b010000,0b100000,0b100000,0b100000,0,0],
        '\\' => [0b100000,0b100000,0b010000,0b001000,0b000100,0b000010,0b000001,0b000001,0,0],
        '"' => [0b010010,0b010010,0b010010,0,0,0,0,0,0,0],
        '\'' => [0b001100,0b001100,0b001100,0,0,0,0,0,0,0],
        '@' => [0b011110,0b100001,0b100001,0b100111,0b101001,0b100111,0b100000,0b011111,0,0],
        '#' => [0b010010,0b010010,0b111111,0b010010,0b010010,0b111111,0b010010,0b010010,0,0],
        '%' => [0b110001,0b110010,0b000100,0b001000,0b010000,0b100110,0b000110,0b000110,0,0],
        '+' => [0,0b001100,0b001100,0b111111,0b001100,0b001100,0,0,0,0],
        '=' => [0,0,0b111111,0,0b111111,0,0,0,0,0],
        '<' => [0b000110,0b001100,0b011000,0b110000,0b011000,0b001100,0b000110,0b000011,0,0],
        '>' => [0b110000,0b011000,0b001100,0b000110,0b001100,0b011000,0b110000,0b110000,0,0],
        _ => [0b111111,0b100001,0b100001,0b100001,0b100001,0b100001,0b100001,0b111111,0,0],
    }
}
