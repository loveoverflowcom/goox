# AI Instructions for This Monorepo

Tài liệu này được trích xuất từ chính cấu trúc và style hiện tại của repo. Khi AI sinh code Flutter/Dart cho dự án này, ưu tiên tuân theo các quy ước dưới đây thay vì áp dụng pattern chung chung từ bên ngoài.

## Cấu trúc package

- Package public entry point dùng `library ...` ở file gốc.
- File gốc thường export `data.dart` và các feature/public bloc cần thiết.
- `data.dart` chỉ export các barrel nội bộ và model/entity public.
- Barrel nội bộ gom export theo nhóm:
  - `src/data/..._barrel.dart`
  - `src/features/<feature>/<feature>.dart`
  - `src/features/<feature>/blocs.dart`
  - `src/features/<feature>/views.dart`
- Nếu thêm module mới, ưu tiên tạo một barrel riêng thay vì export lẻ tẻ nhiều file.

## Cách thêm module mới

- Nếu là logic domain/data, đặt trong `packages/<module>/lib/src/data/...`.
- Nếu là UI/flow trong mobile app, đặt trong `apps/thus_mobile_app/lib/features/<feature>/...`.
- Nếu là phần dùng chung giữa nhiều màn, đặt trong `apps/thus_mobile_app/lib/widgets/` hoặc `theme/`.
- Nếu tính tái sử dụng chưa rõ, đừng tách thành design system package quá sớm.
- Chỉ extract design system khi component/token được dùng ở nhiều feature hoặc nhiều app.

## Quy ước Flutter app

- App mobile dùng feature-first:
  - `features/auth`
  - `features/chat`
  - `features/chat_list`
  - `features/personal`
  - `features/splash`
- Mỗi feature nên có `views.dart` để export view chính.
- Navigation đặt ở `routing/routes.dart` với `go_router` typed routes.
- Shell/layout dùng widget riêng trong `widgets/`.
- Theme/state global đặt trong `theme/`.

## 6. Bloc + Freezed

- Bloc/state/event trong project này ưu tiên `freezed`.
- Event thường theo mẫu:
  - `@Freezed(copyWith: false)`
  - `sealed class ...Event with _$...`
  - factory constructors cho từng event.
- State thường theo mẫu:
  - `@freezed`
  - `sealed class ...State with _$...`
  - `@Default(...)` cho status mặc định.
  - field data nullable hoặc immutable list.
- Bloc class nên là `final class`.
- Bloc nhận repository trực tiếp qua constructor.
- Không tạo use case chỉ để forward một lời gọi repository.

## Export và import

- Export từ root package phải tối thiểu và có chủ đích.
- Không export toàn bộ `src/`.
- Khi package đã có barrel, import barrel thay vì import file rời.
- Dùng `package:` imports cho code giữa các package.
- Trong cùng package, có thể dùng `package:<pkg>/src/...` khi cần truy cập internal code, nhưng vẫn ưu tiên barrel nếu đủ dùng.

## 9. Naming và style

- Tên file, folder, package: `lowercase_with_underscores`.
- Class, enum, typedef, extension: `UpperCamelCase`.
- Biến, hàm, tham số: `lowerCamelCase`.
- Dùng `final` hoặc `const` khi có thể.
- Ưu tiên immutable list và `toList(growable: false)` cho dữ liệu không đổi.
- Dùng `switch` expression và helper private method khi giúp code ngắn gọn hơn.
- Function Style: Ưu tiên Arrow function (=>) cho các hàm hoặc getter chỉ có một dòng code để tăng độ súc tích.
- Shorthand Syntax: Sử dụng Dot shorthand syntax cho các constructor hoặc static members khi context đã rõ ràng (ví dụ: .zero, .all(8), .none()).

## Generated code

- Các file như `*.freezed.dart`, `*.g.dart`, `routes.g.dart` là generated.
- Không sửa trực tiếp các file này.
- Sau khi thay đổi source, chạy codegen tương ứng:
  - `dart run build_runner build --delete-conflicting-outputs`
  - hoặc command tương đương của package/app đang sửa.

## Khi thêm feature mới

- Tạo feature folder riêng.
- Tạo barrel export riêng cho feature.
- Chỉ export những gì màn khác hoặc app cần dùng.
- Gắn route vào router typed route nếu feature có màn mới.
- Nếu có state dùng chung, cân nhắc shared widget/theme trước khi tách package mới.

## Dependency Injection & BLoC Architecture
Repository Injection: - Tất cả Repository nên được cung cấp thông qua RepositoryProvider ở cấp cao nhất có thể trong widget tree.

Bloc hoặc Cubit phải nhận Repository thông qua Constructor Injection.

Bloc-to-Bloc Communication:

Hạn chế tối đa việc các Bloc lắng nghe (listen) trực tiếp lẫn nhau để tránh phụ thuộc vòng (circular dependency).

Cơ chế Event Stream: Các Bloc nên giao tiếp gián tiếp thông qua các Stream sự kiện hoặc BehaviorSubject được export từ trong Repository.

Bloc A tác động vào Repository -> Repository phát ra signal qua Stream -> Bloc B lắng nghe Stream đó và tự cập nhật State tương ứng.
