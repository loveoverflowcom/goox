# 🦀 Goox Rust Coding Guidelines

### 1. Triết lý Code
* **Ưu tiên tính đúng đắn (Correctness):** Đối với một editor cho nhà văn, mất dữ liệu là thảm họa. Code phải rõ ràng, dễ hiểu. Hiệu suất là ưu tiên thứ hai trừ khi xử lý file cực lớn.
* **Ngôn ngữ tường minh:** Sử dụng từ đầy đủ cho tên biến (ví dụ: `buffer_index` thay vì `idx`, `repro_queue` thay vì `q`).
* **Hạn chế File nhỏ:** Chỉ tạo file mới khi đó là một thành phần logic mới hoàn toàn. Ưu tiên gom các logic liên quan vào cùng một module cho đến khi nó quá lớn.

### 2. Xử lý Lỗi & An toàn
* **Cấm Panic:** Tuyệt đối không dùng `unwrap()` hoặc `expect()`. Sử dụng toán tử `?` để lan truyền lỗi.
* **Cẩn trọng với Indexing:** Tránh truy cập mảng qua index trực tiếp `[i]`. Sử dụng `.get()` hoặc các phương thức an toàn của `Ropey`.
* **Không nuốt lỗi:** Không bao giờ dùng `let _ = ...` cho các thao tác có thể lỗi. 
    * Nếu cần bỏ qua lỗi nhưng vẫn muốn theo dõi, hãy dùng log.
    * Mọi lỗi từ Rust Core phải được chuyển đổi thành một kiểu dữ liệu mà Flutter có thể hiển thị thông báo (thông qua `flutter_rust_bridge`).

### 3. Cấu trúc Module & Crate
* **Không dùng `mod.rs`:** Ưu tiên `src/module_name.rs` thay vì `src/module_name/mod.rs`.
* **Explicit Lib Path:** Trong `Cargo.toml`, luôn chỉ định `[lib] path = "src/lib.rs"` (hoặc tên dự án như `src/goox_core.rs`) để tường minh.

### 4. Xử lý Văn bản (The Writer's Core)
* **Rope over String:** Tuyệt đối không dùng `String` làm buffer chính cho văn bản. Sử dụng `Rope` (thư viện `ropey`) để đảm bảo thao tác $O(\log n)$.
* **Atomic Updates:** Mọi thay đổi lên văn bản phải thông qua một hệ thống "Transaction" hoặc "Delta" để có thể hoàn tác (Undo/Redo) và đồng bộ hóa.

---

# 🌉 Concurrency & FFI (Flutter Bridge)

### 1. Luồng dữ liệu (Data Flow)
* **Main Thread là của Flutter:** Mọi xử lý nặng (indexing, search, linter) phải chạy trên background thread của Rust.
* **Variable Shadowing:** Sử dụng shadowing để quản lý lifetime của các biến được clone vào trong async blocks/FFI calls.
  ```rust
  // Ví dụ trong Rust code gọi từ Flutter
  let buffer = self.buffer.clone();
  runtime.spawn(async move {
      let result = buffer.search("fantasy"); // Shadowing để dùng trong async
      // Gửi kết quả về Flutter qua Stream
  });
  ```

### 2. Giao tiếp qua Bridge (`api.rs`)
* **Minimal Data Transfer:** Tránh gửi toàn bộ văn bản qua bridge. Chỉ gửi các "Deltas" (thay đổi) hoặc các đoạn văn bản đang hiển thị trên màn hình (Viewport).
* **Async by Default:** Các hàm trong `api.rs` nên là `async` để không làm nghẽn Event Loop của Flutter.

---

# 🧩 Plugin System (Wasm)

* **Isolation:** Plugins chạy trong môi trường WebAssembly (Wasmer/Wasmtime) phải được cô lập hoàn toàn.
* **Host Functions:** Chỉ cung cấp các API cần thiết cho plugin (như đọc buffer hiện tại, thêm gợi ý từ ngữ). Không cho phép plugin truy cập trực tiếp vào hệ thống file của người dùng trừ khi được cấp quyền.

---

# 🧪 Testing & Timers

* **Mocking IO:** Trong các bài test, hãy mock lại hệ thống file để đảm bảo test chạy nhanh và ổn định.
* **Async Testing:** Sử dụng `tokio::test` (hoặc runtime tương đương) và ưu tiên các cơ chế `pause/resume` thời gian để test các tính năng như "Auto-save after 5s".

---

# 🚀 Pull Request Hygiene (Quy chuẩn Đóng góp)

Mọi PR cho dự án `goox` phải tuân thủ:
* **Tiêu đề PR:** Viết ở dạng mệnh lệnh, viết hoa chữ cái đầu (Ví dụ: `Add CRDT support for buffer syncing`).
* **Không dùng Prefix:** Tránh dùng `fix:`, `feat:`.
* **Phạm vi (Scope):** Nếu PR chỉ tác động vào một phần, hãy thêm prefix bằng tên module (Ví dụ: `core: Improve rope search speed`).
* **Release Notes:** Luôn có phần này ở cuối mô tả PR:
  ```text
  Release Notes:
  - Added support for 1px vertical split lines.
  - Fixed a crash when opening files larger than 500MB.
  ```

---

# 📝 Rules Hygiene (Bảo trì Quy tắc)

* **High Signal:** Giữ cho file quy tắc này ngắn gọn và thực tế. Đừng đưa vào những nguyên lý mơ hồ.
* **Traps, not Maps:** Quy tắc này sinh ra để tránh các "bẫy" kỹ thuật (như dùng String làm buffer), không phải là bản đồ chi tiết từng bước code.
* **Cập nhật:** Nếu trong quá trình code, bạn phát hiện một pattern gây bug lặp lại (ví dụ: lag UI do FFI quá tải), hãy cập nhật vào đây ngay lập tức.

---

