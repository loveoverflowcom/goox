# Requirements Document

## Introduction

Tài liệu này mô tả các yêu cầu cho tính năng cải tiến File Explorer trong ứng dụng Goox Editor. Tính năng này bổ sung khả năng tạo file/folder mới, menu ngữ cảnh (context menu) khi nhấp chuột phải, và cải thiện trải nghiệm người dùng khi làm việc với editor.

## Glossary

- **File_Explorer**: Component hiển thị cấu trúc thư mục và file của workspace
- **Context_Menu**: Menu xuất hiện khi người dùng nhấp chuột phải vào một item
- **File_Node**: Đại diện cho một file hoặc folder trong cây thư mục
- **Editor**: Vùng chỉnh sửa nội dung file
- **Workspace**: Thư mục gốc đang được mở trong ứng dụng
- **Toolbar**: Thanh công cụ chứa các nút action
- **Cursor**: Con trỏ văn bản trong editor

## Requirements

### Requirement 1: Toolbar với nút tạo File và Folder

**User Story:** Là một developer, tôi muốn có các nút tạo file mới và folder mới trên toolbar của File Explorer, để tôi có thể nhanh chóng tạo các file và folder mới mà không cần rời khỏi ứng dụng.

#### Acceptance Criteria

1. THE File_Explorer SHALL hiển thị một Toolbar ở phía trên cùng
2. THE Toolbar SHALL chứa một nút "New File" với icon phù hợp
3. THE Toolbar SHALL chứa một nút "New Folder" với icon phù hợp
4. WHEN người dùng click vào nút "New File", THE File_Explorer SHALL hiển thị dialog để nhập tên file mới
5. WHEN người dùng click vào nút "New Folder", THE File_Explorer SHALL hiển thị dialog để nhập tên folder mới
6. WHEN người dùng xác nhận tạo file mới, THE File_Explorer SHALL tạo file tại vị trí được chọn hoặc tại thư mục gốc nếu không có folder nào được chọn
7. WHEN người dùng xác nhận tạo folder mới, THE File_Explorer SHALL tạo folder tại vị trí được chọn hoặc tại thư mục gốc nếu không có folder nào được chọn
8. IF tên file hoặc folder đã tồn tại, THEN THE File_Explorer SHALL hiển thị thông báo lỗi và không tạo file/folder
9. IF tên file hoặc folder chứa ký tự không hợp lệ, THEN THE File_Explorer SHALL hiển thị thông báo lỗi và không tạo file/folder

### Requirement 2: Context Menu cho File Explorer

**User Story:** Là một developer, tôi muốn có menu ngữ cảnh khi nhấp chuột phải vào file, folder, hoặc vùng trống của File Explorer, để tôi có thể thực hiện các thao tác phổ biến một cách nhanh chóng.

#### Acceptance Criteria

1. WHEN người dùng nhấp chuột phải vào một File_Node kiểu file, THE File_Explorer SHALL hiển thị Context_Menu với các action dành cho file
2. THE Context_Menu cho file SHALL chứa các action: "Rename", "Delete", "Copy Path"
3. WHEN người dùng nhấp chuột phải vào một File_Node kiểu folder, THE File_Explorer SHALL hiển thị Context_Menu với các action dành cho folder
4. THE Context_Menu cho folder SHALL chứa các action: "New File", "New Folder", "Rename", "Delete", "Copy Path"
5. WHEN người dùng nhấp chuột phải vào vùng trống của File_Explorer, THE File_Explorer SHALL hiển thị Context_Menu với các action chung
6. THE Context_Menu cho vùng trống SHALL chứa các action: "New File", "New Folder", "Refresh"
7. WHEN người dùng chọn action "Rename" từ Context_Menu, THE File_Explorer SHALL hiển thị dialog để nhập tên mới
8. WHEN người dùng chọn action "Delete" từ Context_Menu, THE File_Explorer SHALL hiển thị dialog xác nhận trước khi xóa
9. WHEN người dùng chọn action "Copy Path" từ Context_Menu, THE File_Explorer SHALL sao chép đường dẫn đầy đủ của file/folder vào clipboard
10. WHEN người dùng chọn action "Refresh" từ Context_Menu, THE File_Explorer SHALL tải lại cấu trúc thư mục từ hệ thống file

### Requirement 3: Cải thiện hành vi Cursor trong Editor

**User Story:** Là một developer, tôi muốn con trỏ chuột tự động di chuyển đến dòng cuối cùng khi tôi click vào vùng trống bên dưới nội dung trong Editor, để tôi có thể bắt đầu gõ ngay lập tức mà không cần phải click chính xác vào dòng cuối.

#### Acceptance Criteria

1. WHEN người dùng click vào vùng trống bên dưới dòng cuối cùng của nội dung trong Editor, THE Editor SHALL di chuyển Cursor đến cuối dòng cuối cùng
2. WHEN người dùng click vào vùng trống bên dưới dòng cuối cùng của nội dung trong Editor, THE Editor SHALL focus vào text field
3. THE Editor SHALL cho phép người dùng bắt đầu gõ ngay sau khi Cursor được di chuyển đến dòng cuối
4. WHEN người dùng click vào một dòng cụ thể trong Editor, THE Editor SHALL di chuyển Cursor đến vị trí click như bình thường
5. THE Editor SHALL duy trì hành vi click chuẩn cho các vùng có nội dung văn bản

### Requirement 4: Xử lý lỗi và Validation

**User Story:** Là một developer, tôi muốn hệ thống xử lý các lỗi và validate input một cách rõ ràng, để tôi hiểu được vấn đề và biết cách khắc phục.

#### Acceptance Criteria

1. WHEN thao tác tạo file/folder thất bại do lỗi hệ thống file, THE File_Explorer SHALL hiển thị thông báo lỗi với mô tả cụ thể
2. WHEN thao tác xóa file/folder thất bại do quyền truy cập, THE File_Explorer SHALL hiển thị thông báo lỗi với mô tả cụ thể
3. WHEN thao tác đổi tên file/folder thất bại, THE File_Explorer SHALL hiển thị thông báo lỗi với mô tả cụ thể
4. THE File_Explorer SHALL validate tên file/folder không chứa các ký tự: / \ : * ? " < > |
5. THE File_Explorer SHALL validate tên file/folder không rỗng và không chỉ chứa khoảng trắng
6. WHEN validation thất bại, THE File_Explorer SHALL hiển thị thông báo lỗi cụ thể về ký tự không hợp lệ
7. THE File_Explorer SHALL giữ nguyên trạng thái hiện tại khi thao tác thất bại

### Requirement 5: Cập nhật UI sau thao tác

**User Story:** Là một developer, tôi muốn File Explorer tự động cập nhật sau khi tôi thực hiện các thao tác, để tôi thấy được kết quả ngay lập tức mà không cần refresh thủ công.

#### Acceptance Criteria

1. WHEN file mới được tạo thành công, THE File_Explorer SHALL tự động hiển thị file mới trong cây thư mục
2. WHEN folder mới được tạo thành công, THE File_Explorer SHALL tự động hiển thị folder mới trong cây thư mục
3. WHEN file hoặc folder được xóa thành công, THE File_Explorer SHALL tự động loại bỏ item đó khỏi cây thư mục
4. WHEN file hoặc folder được đổi tên thành công, THE File_Explorer SHALL tự động cập nhật tên mới trong cây thư mục
5. WHEN file mới được tạo, THE File_Explorer SHALL tự động chọn file đó và mở trong Editor
6. WHEN folder mới được tạo, THE File_Explorer SHALL tự động expand folder cha và chọn folder mới
7. THE File_Explorer SHALL duy trì trạng thái expand/collapse của các folder khác sau khi cập nhật
