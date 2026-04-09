# Bugfix Requirements Document

## Introduction

Terminal trong goox_terminal hiện tại không hoạt động đúng cách. Khi mở terminal lần đầu, không có gì hiển thị (không có prompt, cursor, hay text nào), không thể gõ lệnh, và khi thử resize thì báo lỗi "Failed to resize session". 

Sau khi so sánh với example từ thư viện xterm.dart gốc, phát hiện có sự khác biệt trong cách xử lý resize event. Trong xterm.dart example, terminal tự động resize PTY khi terminal view thay đổi kích thước thông qua callback `terminal.onResize`. Tuy nhiên, trong goox_terminal hiện tại, không có cơ chế tự động resize này, dẫn đến PTY và Terminal có thể không đồng bộ về kích thước.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN terminal được khởi tạo lần đầu THEN terminal không hiển thị prompt hoặc cursor

1.2 WHEN người dùng cố gắng gõ lệnh vào terminal THEN không có phản hồi nào từ terminal

1.3 WHEN người dùng thay đổi kích thước terminal view THEN PTY không được tự động resize theo kích thước mới của terminal view

1.4 WHEN người dùng gọi phương thức resize() thủ công THEN có thể gặp lỗi "Failed to resize session" do terminal chưa được khởi tạo đúng

### Expected Behavior (Correct)

2.1 WHEN terminal được khởi tạo lần đầu THEN terminal SHALL hiển thị shell prompt và cursor sẵn sàng nhận input

2.2 WHEN người dùng gõ lệnh vào terminal THEN terminal SHALL hiển thị input và thực thi lệnh

2.3 WHEN terminal view thay đổi kích thước THEN PTY SHALL được tự động resize để khớp với kích thước mới của terminal view

2.4 WHEN người dùng gọi phương thức resize() THEN terminal và PTY SHALL được resize thành công mà không có lỗi

### Unchanged Behavior (Regression Prevention)

3.1 WHEN terminal đang chạy và nhận output từ PTY THEN terminal SHALL CONTINUE TO hiển thị output đúng cách với ANSI color support

3.2 WHEN người dùng gửi input đến terminal (qua keyboard hoặc write()) THEN input SHALL CONTINUE TO được gửi đến PTY process

3.3 WHEN PTY process kết thúc THEN terminal status SHALL CONTINUE TO được cập nhật thành "exited" với exit code

3.4 WHEN terminal gặp lỗi THEN terminal status SHALL CONTINUE TO được cập nhật thành "error" và hiển thị error overlay
