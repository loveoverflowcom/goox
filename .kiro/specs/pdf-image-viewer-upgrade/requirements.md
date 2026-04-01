# Requirements Document

## Introduction

Nâng cấp extension pdf-viewer trong ứng dụng Goox Desktop (Flutter + Rust/WASM) để hỗ trợ:

1. **PDF rendering chất lượng cao** thông qua kiến trúc hybrid: WASM plugin đóng vai trò thin wrapper điều phối, còn Rust engine native (wasmtime host) thực hiện PDF rendering thực sự bằng pdfium hoặc poppler — vì pdfium là C++ library không thể compile sang `wasm32-wasip1`.
2. **Image viewer hợp nhất** cho PNG/JPG/JPEG, tận dụng image-viewer WASM plugin hiện có hoặc Flutter `Image.file` với hardware acceleration.
3. **Flutter frontend** với zoom mượt mà (pinch-to-zoom, scroll wheel) và quản lý bộ nhớ tốt (lazy loading, dispose buffer ngoài viewport, cache N pages).

### Quyết định kiến trúc quan trọng: Ai render PDF?

Vì `pdfium-render` là C++ library cần link động và **không thể compile sang `wasm32-wasip1`**, hệ thống cần một trong hai hướng:

- **Hướng A (Recommended)**: Mở rộng ERP protocol với host function `erp_render_pdf_page` — engine native (wasmtime host) tự render PDF bằng pdfium/poppler, WASM plugin chỉ là thin wrapper gọi host function đó.
- **Hướng B**: Bỏ WASM plugin cho PDF, engine native xử lý PDF trực tiếp qua một code path riêng (không qua ERP).

Requirements dưới đây theo **Hướng A** vì giữ nguyên tính nhất quán của ERP protocol và extension system.

---

## Glossary

- **ERP_Protocol**: Extension Rendering Protocol — giao thức giao tiếp giữa Flutter frontend, Rust engine native (wasmtime host), và WASM plugin. Gồm các hàm: `erp_open`, `erp_page_count`, `erp_render_page`, `erp_close` (guest exports) và `erp_set_output_buffer`, `erp_set_metadata`, `erp_report_error` (host imports).
- **WASM_Plugin**: Module `.wasm` compile từ Rust target `wasm32-wasip1`, chạy trong wasmtime sandbox. Với PDF, plugin này là thin wrapper — không tự render mà gọi host function.
- **Native_Engine**: Rust binary native (không phải WASM) chạy wasmtime, xử lý PDF rendering thực sự bằng pdfium hoặc poppler.
- **PDF_Renderer**: Component trong Native_Engine thực hiện convert PDF page → RGBA bitmap, sử dụng pdfium-render hoặc poppler-rs.
- **GooxPluginCanvas**: Flutter widget nhận RGBA pixel buffer từ ERP protocol và hiển thị lên màn hình.
- **Page_Cache**: Cơ chế lưu trữ tạm thời RGBA buffer của các page đã render trong bộ nhớ Flutter.
- **Viewport**: Vùng hiển thị hiện tại của GooxPluginCanvas, xác định page nào đang visible.
- **DPI**: Dots Per Inch — độ phân giải render. Mặc định 300 DPI cho PDF.
- **RGBA_Buffer**: Mảng byte 4 kênh (Red, Green, Blue, Alpha) đại diện cho pixel data của một page đã render.
- **Pinch_To_Zoom**: Gesture zoom bằng hai ngón tay trên trackpad/touchscreen.
- **Scroll_Wheel**: Zoom bằng cuộn chuột kết hợp Ctrl/Cmd.

---

## Requirements

### Requirement 1: Mở rộng ERP Protocol với PDF host rendering

**User Story:** Là một developer của Goox, tôi muốn ERP protocol hỗ trợ PDF rendering qua host function, để WASM plugin có thể yêu cầu Native_Engine render PDF mà không cần pdfium trong WASM.

#### Acceptance Criteria

1. THE Native_Engine SHALL export host function `erp_render_pdf_page(file_ptr: i32, file_len: i32, page_index: i32, dpi: i32, out_width_ptr: i32, out_height_ptr: i32) -> i32` cho WASM plugin import qua module `"env"`.
2. WHEN WASM plugin gọi `erp_render_pdf_page`, THE Native_Engine SHALL render page tương ứng bằng PDF_Renderer và ghi RGBA_Buffer vào output buffer thông qua `erp_set_output_buffer`.
3. WHEN `erp_render_pdf_page` thành công, THE Native_Engine SHALL trả về số byte của RGBA_Buffer (>= 0).
4. IF `erp_render_pdf_page` thất bại (file không tồn tại, page index ngoài range, lỗi render), THEN THE Native_Engine SHALL gọi `erp_report_error` với thông báo lỗi mô tả rõ nguyên nhân và trả về -1.
5. THE Native_Engine SHALL export host function `erp_get_pdf_page_count(file_ptr: i32, file_len: i32) -> i32` để WASM plugin lấy số trang của PDF.
6. IF `erp_get_pdf_page_count` thất bại, THEN THE Native_Engine SHALL gọi `erp_report_error` và trả về -1.
7. THE ERP_Protocol SHALL duy trì backward compatibility — các host function mới được thêm vào, không thay thế các function hiện có (`erp_set_output_buffer`, `erp_set_metadata`, `erp_report_error`).

---

### Requirement 2: PDF_Renderer trong Native_Engine

**User Story:** Là một người dùng Goox, tôi muốn xem file PDF với chất lượng hình ảnh cao, để đọc nội dung rõ ràng mà không bị vỡ font hay mờ.

#### Acceptance Criteria

1. THE PDF_Renderer SHALL convert một PDF page thành RGBA_Buffer với DPI tùy chỉnh, mặc định 300 DPI.
2. WHEN DPI được chỉ định trong khoảng [72, 600], THE PDF_Renderer SHALL render page ở đúng DPI đó.
3. IF DPI được chỉ định ngoài khoảng [72, 600], THEN THE PDF_Renderer SHALL clamp về giá trị gần nhất trong range và tiếp tục render.
4. THE PDF_Renderer SHALL bật anti-aliasing cho cả text và graphics khi render.
5. THE PDF_Renderer SHALL render đúng font chữ nhúng trong PDF (embedded fonts) mà không tự thay thế bằng bitmap font.
6. WHEN một PDF page được render, THE PDF_Renderer SHALL trả về RGBA_Buffer với kích thước `width * height * 4` bytes, trong đó width và height được tính từ DPI và kích thước page gốc (points).
7. THE PDF_Renderer SHALL hỗ trợ PDF version 1.0 đến 2.0.
8. IF một PDF file bị corrupt hoặc password-protected, THEN THE PDF_Renderer SHALL trả về lỗi mô tả rõ ràng thay vì crash.
9. THE PDF_Renderer SHALL sử dụng pdfium-render hoặc poppler-rs làm backend — không tự implement PDF parsing.

---

### Requirement 3: WASM Plugin PDF-Viewer (thin wrapper)

**User Story:** Là một developer của Goox, tôi muốn WASM plugin pdf-viewer hoạt động như thin wrapper trong ERP protocol, để hệ thống extension nhất quán và PDF rendering được thực hiện bởi Native_Engine.

#### Acceptance Criteria

1. THE WASM_Plugin SHALL implement `erp_open(file_ptr: i32, file_len: i32) -> i32` bằng cách gọi `erp_get_pdf_page_count` từ host để validate file và lưu page count.
2. THE WASM_Plugin SHALL implement `erp_page_count() -> i32` trả về page count đã lưu từ `erp_open`.
3. THE WASM_Plugin SHALL implement `erp_render_page(page_index: i32, width: i32, height: i32) -> i32` bằng cách tính DPI từ width/height và kích thước page gốc, sau đó gọi `erp_render_pdf_page` từ host.
4. THE WASM_Plugin SHALL implement `erp_close()` để giải phóng state nội bộ.
5. IF `erp_open` nhận filename rỗng hoặc null, THEN THE WASM_Plugin SHALL gọi `erp_report_error` và trả về -1.
6. THE WASM_Plugin SHALL compile thành công với target `wasm32-wasip1` mà không cần pdfium hay bất kỳ C++ dependency nào.
7. THE WASM_Plugin SHALL có `config.json` với `"filetypes": ["pdf"]` và `"rendering": true`.

---

### Requirement 4: Image Viewer hợp nhất (PNG/JPG)

**User Story:** Là một người dùng Goox, tôi muốn xem file PNG và JPG trực tiếp trong editor, để không cần mở ứng dụng ngoài.

#### Acceptance Criteria

1. THE WASM_Plugin (image-viewer) SHALL hỗ trợ filetypes `["png", "jpg", "jpeg", "gif", "webp", "svg"]` — giữ nguyên image-viewer hiện có, không cần tạo plugin mới.
2. WHEN một file PNG hoặc JPG được mở, THE GooxPluginCanvas SHALL hiển thị ảnh fit-to-viewport theo tỷ lệ gốc (aspect ratio preserved).
3. THE GooxPluginCanvas SHALL render ảnh PNG/JPG thông qua RGBA_Buffer từ image-viewer WASM plugin (đã có sẵn, dùng `image` crate).
4. WHERE hardware acceleration khả dụng trên platform, THE GooxPluginCanvas SHALL tận dụng Flutter's `Image.memory` với `RepaintBoundary` để tối ưu rendering.
5. IF một file ảnh bị corrupt hoặc format không hỗ trợ, THEN THE WASM_Plugin SHALL gọi `erp_report_error` với thông báo rõ ràng và `erp_open` trả về -1.

---

### Requirement 5: Flutter GooxPluginCanvas — Zoom và Navigation

**User Story:** Là một người dùng Goox, tôi muốn zoom và điều hướng trong PDF/ảnh mượt mà, để đọc nội dung chi tiết mà không bị giật lag.

#### Acceptance Criteria

1. THE GooxPluginCanvas SHALL hỗ trợ Pinch_To_Zoom với scale factor trong khoảng [0.25, 8.0].
2. WHEN người dùng thực hiện Scroll_Wheel với Ctrl/Cmd giữ, THE GooxPluginCanvas SHALL zoom in/out với bước 10% mỗi tick scroll.
3. WHEN scale factor thay đổi vượt ngưỡng 20% so với lần render cuối, THE GooxPluginCanvas SHALL trigger re-render page ở DPI cao hơn tương ứng với scale mới.
4. WHILE zoom đang được tính toán lại (re-render chưa xong), THE GooxPluginCanvas SHALL hiển thị version đã scale của RGBA_Buffer cũ thay vì màn hình trắng.
5. THE GooxPluginCanvas SHALL hỗ trợ scroll dọc để điều hướng giữa các page của PDF.
6. WHEN người dùng double-tap hoặc double-click, THE GooxPluginCanvas SHALL toggle giữa fit-to-viewport và 100% zoom.
7. IF scale factor vượt quá [0.25, 8.0], THEN THE GooxPluginCanvas SHALL clamp về giá trị biên gần nhất.

---

### Requirement 6: Quản lý bộ nhớ — Lazy Loading và Page Cache

**User Story:** Là một người dùng Goox, tôi muốn mở PDF nhiều trang mà không bị tốn RAM quá mức, để ứng dụng không bị chậm hay crash khi xem tài liệu lớn.

#### Acceptance Criteria

1. THE GooxPluginCanvas SHALL chỉ render page khi page đó nằm trong hoặc gần Viewport (lazy loading) — không render tất cả pages khi mở file.
2. THE Page_Cache SHALL lưu tối đa N RGBA_Buffer trong bộ nhớ, trong đó N là giá trị cấu hình với mặc định là 5.
3. WHEN số page trong Page_Cache vượt quá N, THE Page_Cache SHALL dispose RGBA_Buffer của page xa Viewport nhất (LRU eviction).
4. WHEN một ERP session bị đóng (`erp_close` được gọi), THE GooxPluginCanvas SHALL dispose toàn bộ RGBA_Buffer trong Page_Cache của session đó.
5. THE GooxPluginCanvas SHALL pre-render tối đa 1 page trước và 1 page sau Viewport hiện tại để giảm latency khi scroll.
6. WHEN một page được request render nhưng chưa có trong Page_Cache, THE GooxPluginCanvas SHALL hiển thị loading indicator trong vùng page đó.
7. THE GooxPluginCanvas SHALL wrap mỗi page render trong `RepaintBoundary` để Flutter không repaint toàn bộ canvas khi chỉ một page thay đổi.

---

### Requirement 7: Metadata và thông tin file

**User Story:** Là một người dùng Goox, tôi muốn xem thông tin cơ bản của file PDF/ảnh đang mở, để biết số trang, kích thước, và định dạng.

#### Acceptance Criteria

1. WHEN `erp_open` thành công cho PDF, THE WASM_Plugin SHALL gọi `erp_set_metadata` với JSON chứa ít nhất: `name` (tên file), `extension` ("pdf"), `page_count` (số trang), `size_bytes` (kích thước file).
2. WHEN `erp_open` thành công cho ảnh, THE WASM_Plugin (image-viewer) SHALL gọi `erp_set_metadata` với JSON chứa ít nhất: `name`, `format`, `width`, `height`, `size_bytes`.
3. THE Native_Engine SHALL expose metadata qua `get_metadata(session_id)` API hiện có — không cần thay đổi Flutter-side API.

---

### Requirement 8: Round-trip và tính đúng đắn của RGBA_Buffer

**User Story:** Là một developer của Goox, tôi muốn đảm bảo RGBA_Buffer được truyền đúng từ Native_Engine sang Flutter, để ảnh hiển thị không bị lỗi màu hay artifact.

#### Acceptance Criteria

1. THE Native_Engine SHALL đảm bảo RGBA_Buffer có đúng `width * height * 4` bytes trước khi gọi `erp_set_output_buffer`.
2. WHEN GooxPluginCanvas nhận RGBA_Buffer, THE GooxPluginCanvas SHALL validate kích thước buffer bằng `width * height * 4` trước khi tạo `Image` object.
3. IF kích thước buffer không khớp với `width * height * 4`, THEN THE GooxPluginCanvas SHALL log lỗi và hiển thị error placeholder thay vì crash.
4. THE RGBA_Buffer SHALL sử dụng byte order RGBA (Red byte đầu tiên, Alpha byte cuối) — nhất quán với Flutter's `decodeImageFromPixels` format.
5. FOR ALL valid PDF pages, rendering page ở DPI D rồi scale xuống 50% SHALL cho kết quả tương đương với rendering ở DPI D/2 (metamorphic property — sai số cho phép ≤ 5% pixel difference do anti-aliasing).
