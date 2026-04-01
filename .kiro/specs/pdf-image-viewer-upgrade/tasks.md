# Implementation Plan: PDF & Image Viewer Upgrade

## Overview

Triển khai theo kiến trúc hybrid Hướng A: Native_Engine (Rust/wasmtime host) thực hiện PDF rendering bằng pdfium-render, WASM plugin là thin wrapper, Flutter GooxPluginCanvas được nâng cấp với zoom, lazy loading và LRU page cache.

## Tasks

- [x] 1. Mở rộng ERP Protocol — thêm host functions PDF vào Native_Engine
  - [x] 1.1 Implement `erp_get_pdf_page_count` host function trong wasmtime host
    - Thêm host function vào module `"env"` mà WASM plugin import
    - Nhận `file_ptr: i32, file_len: i32`, đọc filename từ WASM memory, gọi `PDF_Renderer::get_page_count`
    - Trả về page count hoặc -1 + gọi `erp_report_error` khi thất bại
    - _Requirements: 1.5, 1.6, 1.7_

  - [x] 1.2 Implement `erp_render_pdf_page` host function trong wasmtime host
    - Thêm host function vào module `"env"`: `(file_ptr, file_len, page_index, dpi, out_width_ptr, out_height_ptr) -> i32`
    - Đọc filename từ WASM memory, gọi `PDF_Renderer::render_page`, ghi width/height vào WASM memory qua out pointers
    - Gọi `erp_set_output_buffer` với RGBA data, trả về byte count hoặc -1
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [ ]* 1.3 Viết property test cho erp_render_pdf_page success invariant
    - **Property 1: erp_render_pdf_page success invariant**
    - **Validates: Requirements 1.2, 1.3**

  - [ ]* 1.4 Viết property test cho error handling của host functions
    - **Property 2: erp_render_pdf_page và erp_get_pdf_page_count error handling**
    - **Validates: Requirements 1.4, 1.6**

- [x] 2. Implement PDF_Renderer trong Native_Engine
  - [x] 2.1 Tạo struct `PdfRenderer` và `RgbaPage`, `PdfError` trong Native_Engine
    - Thêm dependency `pdfium-render` vào `Cargo.toml` của native engine
    - Implement `PdfRenderer::get_page_count(file_path: &str) -> Result<u32, PdfError>`
    - Implement `PdfRenderer::render_page(file_path, page_index, dpi) -> Result<RgbaPage, PdfError>`
    - DPI clamp về [72, 600], bật anti-aliasing
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9_

  - [ ]* 2.2 Viết property test cho RGBA buffer size invariant
    - **Property 3: RGBA buffer size invariant**
    - **Validates: Requirements 2.6, 8.1**

  - [ ]* 2.3 Viết property test cho DPI clamping
    - **Property 4: DPI clamping**
    - **Validates: Requirements 2.3**

  - [ ]* 2.4 Viết property test cho PDF error handling — no crash
    - **Property 5: PDF error handling — no crash**
    - **Validates: Requirements 2.8**

  - [ ]* 2.5 Viết unit tests cho PDF_Renderer
    - `test_render_page_returns_correct_size()` — render page cụ thể, kiểm tra buffer size
    - `test_get_page_count_known_pdf()` — PDF có N trang, kiểm tra trả về đúng N
    - `test_corrupt_pdf_returns_error()` — bytes ngẫu nhiên, kiểm tra PdfError
    - `test_dpi_clamp_72()` và `test_dpi_clamp_600()`
    - _Requirements: 2.2, 2.3, 2.8_

- [x] 3. Checkpoint — Đảm bảo Native_Engine build và tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Viết lại WASM Plugin pdf-viewer (thin wrapper)
  - [x] 4.1 Thay thế implementation hiện tại trong `dummy_extensions/pdf-viewer/src/lib.rs`
    - Xóa toàn bộ logic lopdf, bitmap font renderer
    - Khai báo host imports: `erp_render_pdf_page`, `erp_get_pdf_page_count`, `erp_set_output_buffer`, `erp_set_metadata`, `erp_report_error`
    - Implement `erp_open`: gọi `erp_get_pdf_page_count`, lưu filename + page_count vào state, gọi `erp_set_metadata` với JSON đầy đủ
    - Implement `erp_page_count`: trả về page_count từ state
    - Implement `erp_render_page`: tính DPI từ width, gọi `erp_render_pdf_page`
    - Implement `erp_close`: clear state
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

  - [ ]* 4.2 Viết property test cho plugin lifecycle round-trip
    - **Property 6: Plugin lifecycle round-trip**
    - **Validates: Requirements 3.2, 3.4**

  - [ ]* 4.3 Viết property test cho metadata completeness
    - **Property 12: Metadata completeness**
    - **Validates: Requirements 7.1, 7.2**

  - [ ]* 4.4 Viết unit tests cho WASM plugin
    - `test_erp_open_empty_filename()` — kiểm tra trả về -1
    - `test_erp_close_clears_state()` — open rồi close, kiểm tra page_count = -1
    - _Requirements: 3.5_

- [x] 5. Nâng cấp image-viewer WASM plugin (error handling)
  - [x] 5.1 Cập nhật `erp_open` trong image-viewer để gọi `erp_report_error` khi file corrupt/unsupported
    - Đảm bảo trả về -1 với thông báo lỗi mô tả rõ ràng
    - Cập nhật `erp_set_metadata` với đầy đủ fields: `name`, `format`, `width`, `height`, `size_bytes`
    - _Requirements: 4.1, 4.5, 7.2_

  - [ ]* 5.2 Viết property test cho image error handling
    - **Property 7: Image error handling**
    - **Validates: Requirements 4.5**

- [x] 6. Checkpoint — Đảm bảo cả hai WASM plugins compile sang wasm32-wasip1
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Implement PageCache (LRU) trong Flutter
  - [x] 7.1 Tạo class `PageCache` trong Flutter với LRU eviction
    - Dùng `LinkedHashMap<int, ui.Image>` để track access order
    - Implement `get(pageIndex)`, `put(pageIndex, image)`, `evictFarthestFrom(currentPage)`, `clear()`
    - Khi evict: gọi `image.dispose()` để giải phóng GPU texture
    - _Requirements: 6.2, 6.3, 6.4_

  - [ ]* 7.2 Viết property test cho page cache size invariant với LRU eviction
    - **Property 10: Page cache size invariant with LRU eviction**
    - **Validates: Requirements 6.2, 6.3**

  - [ ]* 7.3 Viết property test cho session close clears cache
    - **Property 11: Session close clears cache**
    - **Validates: Requirements 6.4**

  - [ ]* 7.4 Viết unit tests cho PageCache
    - `test_page_cache_eviction()` — thêm N+1 pages, kiểm tra LRU eviction
    - `test_cache_clear_disposes_images()` — kiểm tra dispose được gọi
    - _Requirements: 6.2, 6.3, 6.4_

- [x] 8. Nâng cấp GooxPluginCanvas — Zoom và Navigation
  - [x] 8.1 Cập nhật `GooxPluginCanvas` widget với `InteractiveViewer` và `ZoomController`
    - Thêm `InteractiveViewer` với `minScale: 0.25`, `maxScale: 8.0`
    - Implement scroll wheel + Ctrl/Cmd zoom 10% mỗi tick (`Listener` widget)
    - Implement double-tap toggle fit-to-viewport / 100%
    - Clamp scale factor về [0.25, 8.0]
    - _Requirements: 5.1, 5.2, 5.6, 5.7_

  - [ ]* 8.2 Viết property test cho scale factor clamping
    - **Property 8: Scale factor clamping**
    - **Validates: Requirements 5.7**

  - [x] 8.3 Implement re-render threshold và lazy loading trong GooxPluginCanvas
    - Track `_lastRenderScale`; khi `|newScale - lastRenderScale| / lastRenderScale > 0.20` thì trigger re-render
    - Trong khi chờ re-render: hiển thị scaled version của buffer cũ
    - Dùng `ScrollController` để track viewport, chỉ render pages trong viewport ± 1
    - Pre-fetch 1 page trước và 1 page sau viewport
    - Wrap mỗi page trong `RepaintBoundary`
    - Hiển thị loading indicator khi page chưa có trong cache
    - _Requirements: 5.3, 5.4, 5.5, 6.1, 6.5, 6.6, 6.7_

  - [ ]* 8.4 Viết property test cho re-render threshold
    - **Property 9: Re-render threshold**
    - **Validates: Requirements 5.3**

  - [x] 8.5 Tích hợp PageCache vào GooxPluginCanvas
    - Khởi tạo `PageCache` khi session mở, gọi `cache.clear()` khi `erp_close`
    - Dùng `cache.get(pageIndex)` trước khi gọi `onRenderPage`
    - Sau khi render xong: `cache.put(pageIndex, image)`, gọi `evictFarthestFrom(currentPage)`
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 9. Implement RGBA buffer validation trong GooxPluginCanvas
  - [x] 9.1 Thêm buffer size validation trước khi gọi `decodeImageFromPixels`
    - Validate `buffer.length == width * height * 4`
    - Nếu không khớp: log lỗi, hiển thị error placeholder widget thay vì crash
    - Đảm bảo dùng `PixelFormat.rgba8888` nhất quán với byte order RGBA
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

  - [ ]* 9.2 Viết property test cho buffer size validation — no crash
    - **Property 14: Buffer size validation — no crash**
    - **Validates: Requirements 8.2, 8.3**

  - [ ]* 9.3 Viết property test cho RGBA byte order
    - **Property 13: RGBA byte order**
    - **Validates: Requirements 8.4**

  - [ ]* 9.4 Viết unit tests cho buffer validation
    - `test_buffer_size_mismatch_shows_placeholder()` — truyền buffer sai size
    - `test_metadata_parsing_pdf()` và `test_metadata_parsing_image()`
    - _Requirements: 8.2, 8.3_

- [x] 10. Implement ImageViewerShell cho PNG/JPG
  - [x] 10.1 Tạo `ImageViewerShell` widget sử dụng GooxPluginCanvas với image-viewer session
    - Hiển thị ảnh fit-to-viewport với aspect ratio preserved
    - Tận dụng `RepaintBoundary` và `Image.memory` cho hardware acceleration
    - _Requirements: 4.2, 4.3, 4.4_

  - [ ]* 10.2 Viết unit test cho ImageViewerShell
    - `test_image_viewer_shell_renders_rgba()` — integration test với mock `onRenderPage`
    - _Requirements: 4.2, 4.3_

- [x] 11. Checkpoint — Đảm bảo tất cả tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 12. Integration và wiring
  - [x] 12.1 Kết nối Native_Engine host functions với `PdfRenderer` instance
    - Đảm bảo `PdfRenderer` được khởi tạo một lần và shared qua wasmtime store
    - Wire `erp_get_pdf_page_count` và `erp_render_pdf_page` vào `PdfRenderer`
    - _Requirements: 1.1, 1.5, 2.1_

  - [x] 12.2 Kết nối Flutter `EditorPage` với `GooxPluginCanvas` nâng cấp
    - Truyền `sessionId`, `pageCount`, `onRenderPage` callback vào `GooxPluginCanvas`
    - Đảm bảo `erp_close` được gọi khi widget dispose
    - _Requirements: 5.1, 6.4_

  - [ ]* 12.3 Viết integration tests end-to-end
    - Mở PDF thật → render page 0 → kiểm tra buffer size và byte order
    - Mở PNG thật → render → kiểm tra metadata fields
    - Session lifecycle: open → render multiple pages → close → kiểm tra cache cleared
    - _Requirements: 1.2, 1.3, 7.1, 7.2, 6.4_

  - [ ]* 12.4 Viết property test cho metamorphic DPI scaling
    - **Property 15: Metamorphic DPI scaling**
    - **Validates: Requirements 8.5**

- [x] 13. Final checkpoint — Đảm bảo tất cả tests pass và build thành công
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks đánh dấu `*` là optional, có thể bỏ qua để MVP nhanh hơn
- Mỗi task tham chiếu requirements cụ thể để traceability
- Property tests dùng `proptest` (Rust) cho Native_Engine và WASM plugin; `dart_test` với custom generators cho Flutter
- Mỗi property test chạy tối thiểu 100 iterations
- Tag format cho property tests: `// Feature: pdf-image-viewer-upgrade, Property {N}: {property_text}`
