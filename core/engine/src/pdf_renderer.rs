/// PDF_Renderer — converts PDF pages to RGBA pixel buffers using pdfium-render.
///
/// Requirements: 2.1–2.9
use pdfium_render::prelude::*;
use std::fmt;

// ── Error type ────────────────────────────────────────────────────────────────

#[derive(Debug)]
pub enum PdfError {
    FileNotFound(String),
    PageOutOfRange { page: u32, total: u32 },
    PasswordProtected,
    Corrupt(String),
    RenderFailed(String),
    PdfiumInit(String),
}

impl fmt::Display for PdfError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            PdfError::FileNotFound(path) => write!(f, "file not found: {path}"),
            PdfError::PageOutOfRange { page, total } => {
                write!(f, "page {page} out of range (total: {total})")
            }
            PdfError::PasswordProtected => write!(f, "password-protected PDF"),
            PdfError::Corrupt(msg) => write!(f, "corrupt PDF: {msg}"),
            PdfError::RenderFailed(msg) => write!(f, "render failed: {msg}"),
            PdfError::PdfiumInit(msg) => write!(f, "pdfium init error: {msg}"),
        }
    }
}

// ── Output type ───────────────────────────────────────────────────────────────

pub struct RgbaPage {
    /// RGBA bytes, len == width * height * 4
    pub data: Vec<u8>,
    pub width: u32,
    pub height: u32,
}

// ── DPI helpers ───────────────────────────────────────────────────────────────

const DPI_MIN: u32 = 72;
const DPI_MAX: u32 = 600;

fn clamp_dpi(dpi: i32) -> u32 {
    if dpi < DPI_MIN as i32 {
        DPI_MIN
    } else if dpi > DPI_MAX as i32 {
        DPI_MAX
    } else {
        dpi as u32
    }
}

// ── PdfRenderer ───────────────────────────────────────────────────────────────

pub struct PdfRenderer {
    pdfium: Pdfium,
}

impl PdfRenderer {
    /// Create a new PdfRenderer, loading pdfium from the system library path.
    pub fn new() -> Result<Self, PdfError> {
        let pdfium = Pdfium::new(
            Pdfium::bind_to_system_library().map_err(|e| PdfError::PdfiumInit(e.to_string()))?,
        );
        Ok(Self { pdfium })
    }

    /// Return the number of pages in the PDF at `file_path`.
    ///
    /// Requirements: 1.5, 1.6, 2.7, 2.8
    pub fn get_page_count(&self, file_path: &str) -> Result<u32, PdfError> {
        if !std::path::Path::new(file_path).exists() {
            return Err(PdfError::FileNotFound(file_path.to_string()));
        }
        let doc = self.load_document(file_path)?;
        Ok(doc.pages().len() as u32)
    }

    /// Render `page_index` (0-based) of the PDF at `file_path` to an RGBA buffer.
    ///
    /// `dpi` is clamped to [72, 600]. Anti-aliasing is always enabled.
    ///
    /// Requirements: 2.1–2.9
    pub fn render_page(
        &self,
        file_path: &str,
        page_index: u32,
        dpi: i32,
    ) -> Result<RgbaPage, PdfError> {
        if !std::path::Path::new(file_path).exists() {
            return Err(PdfError::FileNotFound(file_path.to_string()));
        }

        let doc = self.load_document(file_path)?;
        let total = doc.pages().len() as u32;

        if page_index >= total {
            return Err(PdfError::PageOutOfRange {
                page: page_index,
                total,
            });
        }

        let effective_dpi = clamp_dpi(dpi);
        let page = doc
            .pages()
            .get(page_index as u16)
            .map_err(|e| PdfError::RenderFailed(e.to_string()))?;

        // Calculate pixel dimensions from page size (points) and DPI.
        // 1 point = 1/72 inch, so pixels = points * dpi / 72
        let page_width_pts = page.width().value;
        let page_height_pts = page.height().value;
        let width = ((page_width_pts * effective_dpi as f32) / 72.0).round() as u32;
        let height = ((page_height_pts * effective_dpi as f32) / 72.0).round() as u32;

        let width = width.max(1);
        let height = height.max(1);

        // Render with anti-aliasing enabled (pdfium default)
        let bitmap = page
            .render_with_config(
                &PdfRenderConfig::new()
                    .set_target_width(width as i32)
                    .set_target_height(height as i32)
                    .set_maximum_width(width as i32)
                    .render_annotations(true)
                    .render_form_data(true),
            )
            .map_err(|e| PdfError::RenderFailed(e.to_string()))?;

        // pdfium-render returns BGRA by default; convert to RGBA
        let bgra = bitmap.as_raw_bytes();
        let mut rgba = vec![0u8; bgra.len()];
        for i in (0..bgra.len()).step_by(4) {
            rgba[i] = bgra[i + 2]; // R ← B
            rgba[i + 1] = bgra[i + 1]; // G
            rgba[i + 2] = bgra[i]; // B ← R
            rgba[i + 3] = bgra[i + 3]; // A
        }

        // Validate buffer size invariant (Requirement 8.1)
        debug_assert_eq!(
            rgba.len(),
            (width * height * 4) as usize,
            "RGBA buffer size mismatch"
        );

        Ok(RgbaPage {
            data: rgba,
            width,
            height,
        })
    }

    /// Render `page_index` using an explicit target size.
    pub fn render_page_to_size(
        &self,
        file_path: &str,
        page_index: u32,
        target_width: u32,
        target_height: u32,
    ) -> Result<RgbaPage, PdfError> {
        if !std::path::Path::new(file_path).exists() {
            return Err(PdfError::FileNotFound(file_path.to_string()));
        }

        let doc = self.load_document(file_path)?;
        let total = doc.pages().len() as u32;

        if page_index >= total {
            return Err(PdfError::PageOutOfRange {
                page: page_index,
                total,
            });
        }

        let width = target_width.max(1);
        let height = target_height.max(1);
        let page = doc
            .pages()
            .get(page_index as u16)
            .map_err(|e| PdfError::RenderFailed(e.to_string()))?;

        let bitmap = page
            .render_with_config(
                &PdfRenderConfig::new()
                    .set_target_width(width as i32)
                    .set_target_height(height as i32)
                    .set_maximum_width(width as i32)
                    .render_annotations(true)
                    .render_form_data(true),
            )
            .map_err(|e| PdfError::RenderFailed(e.to_string()))?;

        let bgra = bitmap.as_raw_bytes();
        let mut rgba = vec![0u8; bgra.len()];
        for i in (0..bgra.len()).step_by(4) {
            rgba[i] = bgra[i + 2];
            rgba[i + 1] = bgra[i + 1];
            rgba[i + 2] = bgra[i];
            rgba[i + 3] = bgra[i + 3];
        }

        debug_assert_eq!(
            rgba.len(),
            (width * height * 4) as usize,
            "RGBA buffer size mismatch"
        );

        Ok(RgbaPage {
            data: rgba,
            width,
            height,
        })
    }

    fn load_document<'a>(&'a self, file_path: &str) -> Result<PdfDocument<'a>, PdfError> {
        self.pdfium
            .load_pdf_from_file(file_path, None)
            .map_err(|e| {
                let msg = e.to_string();
                if msg.contains("password") || msg.contains("Password") {
                    PdfError::PasswordProtected
                } else {
                    PdfError::Corrupt(msg)
                }
            })
    }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    fn make_renderer() -> Option<PdfRenderer> {
        PdfRenderer::new().ok()
    }

    #[test]
    fn dpi_clamp_lower_bound() {
        assert_eq!(clamp_dpi(0), 72);
        assert_eq!(clamp_dpi(-100), 72);
        assert_eq!(clamp_dpi(72), 72);
    }

    #[test]
    fn dpi_clamp_upper_bound() {
        assert_eq!(clamp_dpi(601), 600);
        assert_eq!(clamp_dpi(9999), 600);
        assert_eq!(clamp_dpi(600), 600);
    }

    #[test]
    fn dpi_in_range_unchanged() {
        assert_eq!(clamp_dpi(150), 150);
        assert_eq!(clamp_dpi(300), 300);
    }

    #[test]
    fn corrupt_pdf_returns_error() {
        let Some(renderer) = make_renderer() else {
            return; // pdfium not available in CI
        };
        // Write random bytes to a temp file
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("corrupt.pdf");
        std::fs::write(&path, b"not a pdf at all \x00\x01\x02").unwrap();
        let result = renderer.get_page_count(path.to_str().unwrap());
        assert!(result.is_err(), "expected error for corrupt PDF, got Ok");
    }

    #[test]
    fn file_not_found_returns_error() {
        let Some(renderer) = make_renderer() else {
            return;
        };
        let result = renderer.get_page_count("/nonexistent/path/file.pdf");
        assert!(matches!(result, Err(PdfError::FileNotFound(_))));
    }
}

#[cfg(test)]
mod property_tests {
    use super::*;
    use proptest::prelude::*;

    // Feature: pdf-image-viewer-upgrade, Property 4: DPI clamping
    proptest! {
        #[test]
        fn prop_dpi_clamp_never_errors(dpi in i32::MIN..=i32::MAX) {
            let clamped = clamp_dpi(dpi);
            prop_assert!(clamped >= 72 && clamped <= 600);
        }
    }

    // Feature: pdf-image-viewer-upgrade, Property 5: PDF error handling — no crash
    proptest! {
        #[test]
        fn prop_corrupt_bytes_no_crash(bytes in proptest::collection::vec(any::<u8>(), 0..1024)) {
            let Some(renderer) = PdfRenderer::new().ok() else {
                return Ok(());
            };
            let dir = tempfile::tempdir().unwrap();
            let path = dir.path().join("fuzz.pdf");
            std::fs::write(&path, &bytes).unwrap();
            // Must not panic — result can be Ok or Err
            let _ = renderer.get_page_count(path.to_str().unwrap());
        }
    }
}
