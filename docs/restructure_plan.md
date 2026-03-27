# Goox Restructure Plan

## Muc tieu

Tai cau truc repo thanh layout de mo rong, de tai su dung, va de duy tri pipeline Flutter <-> Rust ro rang:

```text
.
├── apps/
│   └── goox_desktop/
├── core/
│   ├── engine/
│   └── storage/
├── platform/
│   ├── flutter_bridge/
│   └── ffi/
├── packages/
│   ├── goox_editor_sdk/
│   └── goox_ui_shared/
├── examples/
│   └── simple_editor/
├── scripts/
│   ├── build_all.sh
│   ├── apply_patches.sh
│   └── sync_bridge.sh
├── Cargo.toml
└── flutter_rules.md
```

## Nguyen tac migration

- Khong di chuyen tat ca trong 1 lan. Moi phase phai giu repo o trang thai build duoc.
- Rust van la single source of truth cho buffer, revision, undo/redo, viewport query.
- Flutter app khong import truc tiep bridge hoac FFI. App chi noi chuyen voi `goox_editor_sdk`.
- Code generated phai co vi tri rieng va script tao lai ro rang.
- Example app phai chay duoc som hon app chinh de lam phong thi nghiem.

## Danh gia nhanh thiet ke de xuat

Thiet ke nay hop ly va khoa hoc hon cau truc hien tai. Diem dung nhat la them `packages/goox_editor_sdk` lam lop vo boc cap cao.

Mot dieu can chot som:

- `platform/flutter_bridge/` nen la noi chua source generated co the tai tao.
- Khong de app import truc tiep thu muc nay.
- Neu sau nay generated code phinh to, nen can nhac tach thanh Dart package rieng, nhung truoc mat chua can overengineer.

## Mapping tu cau truc hien tai

### Hien tai

- `apps/goox_flutter` -> app demo Flutter
- `crates/goox_core` -> Rust core duy nhat
- `docs/` -> tai lieu va so do

### Dich den

- `apps/goox_flutter` doi thanh `apps/goox_desktop`
- `crates/goox_core` tach thanh:
  - `core/engine`
  - `core/storage`
- Them `platform/flutter_bridge` de chua code FRB generated va helper layer
- Them `platform/ffi` de chua C-API hoac adapter cap thap neu can
- Them `packages/goox_editor_sdk` lam public surface cho app
- Them `packages/goox_ui_shared` cho widget chung
- Them `examples/simple_editor` de thu nghiem nhanh
- Them `scripts/` cho build va sync

## Kien truc sau khi tach

### 1. `core/engine`

Trach nhiem:

- text buffer
- rope / line index cache
- revision model
- operation log
- undo/redo
- viewport query
- syntax-independent editor primitives

Khong nen chua:

- SQLite
- file persistence
- bridge-specific type

### 2. `core/storage`

Trach nhiem:

- file I/O
- autosave
- SQLite metadata
- workspace state
- cache/index persistence

Nguyen tac:

- `storage` phu thuoc `engine` neu can serialize snapshot hoac persist operation log
- `engine` khong phu thuoc nguoc lai vao `storage`

### 3. `platform/flutter_bridge`

Trach nhiem:

- generated bindings tu `flutter_rust_bridge`
- DTOs phuc vu giao tiep Flutter <-> Rust
- stream/event mapping cap thap

Nguyen tac:

- khong viet business logic o day
- co script tai tao toan bo
- commit generated code chi khi team can review diff bridge; neu khong thi script phai tao lai duoc

### 4. `platform/ffi`

Trach nhiem:

- C-ABI boundary neu can mo rong desktop embedding hoac non-Flutter host
- wrapper cap thap quanh engine/storage

Nguyen tac:

- giu API nho va on dinh
- khong de Flutter app phu thuoc truc tiep

### 5. `packages/goox_editor_sdk`

Day la lop quan trong nhat ben Flutter.

Trach nhiem:

- wrap bridge thap thanh API Dart-style
- cung cap `GooxEditorController`
- quan ly lifecycle session editor
- state exposure cho UI: cursor, selection, viewport, dirty state, loading state, error state
- convert error tu Rust thanh error/object de Flutter de xu ly
- co adapter/mock de test UI khong can Rust that

Public surface de xuat:

```text
goox_editor_sdk/
  lib/
    goox_editor_sdk.dart
    data.dart
    src/
      data/
        bridge_client.dart
        editor_repository.dart
      features/editor/
        blocs/
        controllers/
        models/
        views/
```

Core API de xuat:

- `GooxEditorController.openFile(path)`
- `GooxEditorController.applyInput(command)`
- `GooxEditorController.undo()`
- `GooxEditorController.redo()`
- `GooxEditorController.scrollTo(line)`
- `GooxEditorController.dispose()`

State toi thieu:

- current revision
- cursor position
- selection range
- viewport lines
- loading/error status
- canUndo/canRedo
- file path / session id

### 6. `packages/goox_ui_shared`

Trach nhiem:

- editor toolbar widgets
- status bar widgets
- panel/frame reusable widgets
- theme token va visual primitives chung

Khong nen chua:

- editor business state
- bridge access

### 7. `examples/simple_editor`

Trach nhiem:

- minimal app import `goox_editor_sdk`
- debug nhanh input -> patch -> paint
- test integration moi khi doi engine/bridge

Scope de xuat:

- mo file demo
- go phim, undo/redo
- viewport panel
- event log

## Ke hoach trien khai theo phase

### Phase 0. Chot naming va boundary

Muc tieu:

- thong nhat ten thu muc va trach nhiem
- khong code chong cheo roi lai phai sua

Viec can lam:

1. Chot ten `goox_desktop` thay cho `goox_flutter`.
2. Chot `goox_editor_sdk` la public entry point duy nhat cho app.
3. Chot `core/engine` va `core/storage` la Rust crates rieng.
4. Chot `platform/flutter_bridge` la generated boundary.
5. Chot quy tac: app khong import `platform/flutter_bridge` truc tiep.

Deliverable:

- tai lieu plan nay duoc duyet

### Phase 1. Dung skeleton thu muc moi

Muc tieu:

- tao bo khung ma chua can di chuyen logic ngay

Viec can lam:

1. Tao thu muc:
   - `apps/goox_desktop`
   - `core/engine`
   - `core/storage`
   - `platform/flutter_bridge`
   - `platform/ffi`
   - `packages/goox_editor_sdk`
   - `packages/goox_ui_shared`
   - `examples/simple_editor`
   - `scripts`
2. Cap nhat root `Cargo.toml` thanh workspace moi.
3. Tao `pubspec.yaml` cho 2 package Flutter.
4. Tao `README.md` ngan cho tung module lon.

Deliverable:

- workspace build skeleton xong
- chua move logic

### Phase 2. Tach Rust core

Muc tieu:

- dua primitive hien tai vao `core/engine`
- dat nen cho `storage`

Viec can lam:

1. Move `crates/goox_core` -> `core/engine`.
2. Doi crate name neu can:
   - `goox_engine`
3. Giu lai API hien co:
   - `EditorBuffer`
   - operations
   - viewport
   - undo/redo
4. Tao `core/storage` crate voi API stub:
   - file load/save
   - workspace metadata
5. Neu co type chung giua `engine` va `storage`, can nhac them crate `core/model` sau nay.
   Hien tai chua can tao ngay.

Deliverable:

- `cargo test` cho `core/engine`
- `cargo check --workspace` xanh

### Phase 3. Tao bridge boundary

Muc tieu:

- xac lap lop generated doc lap voi app

Viec can lam:

1. Dat source FRB vao `platform/flutter_bridge`.
2. Tao command sync bridge trong `scripts/sync_bridge.sh`.
3. Generated types phai map ro:
   - patch batch
   - viewport snapshot
   - editor event
   - error payload
4. Dat quy tac:
   - generated file khong sua tay

Deliverable:

- bridge co the generate lai tu script
- app chua dung truc tiep

### Phase 4. Tao `goox_editor_sdk`

Muc tieu:

- app co mot public API Dart sach, on dinh, de test

Viec can lam:

1. Tao package `packages/goox_editor_sdk`.
2. Tao root export:
   - `goox_editor_sdk.dart`
   - `data.dart`
3. Tao `BridgeClient` wrap generated bridge.
4. Tao `GooxEditorController`.
5. Tao `EditorRepository` hoac abstraction tuong duong de giao tiep gian tiep.
6. Them state model:
   - `GooxEditorState`
   - `GooxCursor`
   - `GooxSelection`
   - `GooxViewport`
7. Them fake/mock implementation de widget test khong can Rust.

Deliverable:

- app demo chi import `package:goox_editor_sdk/goox_editor_sdk.dart`

### Phase 5. Doi ten va cap nhat desktop app

Muc tieu:

- `apps/goox_desktop` tro thanh app chinh

Viec can lam:

1. Doi `apps/goox_flutter` -> `apps/goox_desktop`.
2. Remove direct coupling tu app toi mock core hien tai.
3. App dung `GooxEditorController` tu SDK.
4. Chi giu UI shell, route, theme, layout trong app.

Deliverable:

- desktop app chay qua SDK

### Phase 6. Tach UI shared

Muc tieu:

- dua widget co kha nang tai su dung ra khoi app

Viec can lam:

1. Move reusable widgets sang `packages/goox_ui_shared`.
2. Giu lai trong app:
   - page composition
   - app-specific shell
3. Chua tach qua som cac widget con thuoc editor internals neu chi co 1 noi dung.

Deliverable:

- widget chung duoc reuse boi app va example

### Phase 7. Tao example app

Muc tieu:

- co phong thi nghiem nho, chay nhanh

Viec can lam:

1. Tao `examples/simple_editor`.
2. Example chi phu thuoc:
   - `goox_editor_sdk`
   - co the them `goox_ui_shared`
3. Luong toi thieu:
   - open sample text
   - type
   - undo/redo
   - viewport info

Deliverable:

- `flutter run` cho example

### Phase 8. Them scripts automation

Muc tieu:

- giam thao tac tay va giam sai sot

Can co:

#### `scripts/build_all.sh`

Nhiem vu:

- chay `cargo test --workspace`
- chay `flutter analyze` cho package/app can thiet
- chay `flutter test` cho package/app can thiet

#### `scripts/sync_bridge.sh`

Nhiem vu:

- chay codegen FRB
- copy/refresh generated output vao `platform/flutter_bridge`
- co log that bai ro rang

#### `scripts/apply_patches.sh`

Nhiem vu:

- apply customization vao source vendor neu sau nay co `vendor/`
- script phai idempotent het muc co the
- khong overwrite mu quang

Luu y:

- hien tai repo chua co `vendor/`, nen script nay co the o muc stub + convention doc.

### Phase 9. Don dep va khoa boundary

Muc tieu:

- tranh con duong import cu

Viec can lam:

1. Remove import path cu tu app sang bridge/mock.
2. Remove `crates/goox_core` sau khi move xong.
3. Cap nhat docs va diagram.
4. Cap nhat CI de build theo cau truc moi.

Deliverable:

- khong con dependency cheo sai boundary

## Thu tu implement toi uu

Thu tu an toan nhat:

1. Phase 0
2. Phase 1
3. Phase 2
4. Phase 4
5. Phase 5
6. Phase 3
7. Phase 7
8. Phase 8
9. Phase 6
10. Phase 9

Ly do:

- can tach `engine` som.
- can co `SDK` truoc khi doi app sang layout moi.
- bridge that co the den sau khi public Dart API da ro.
- UI shared nen tach sau cung de tranh split qua som.

## Rui ro chinh

### 1. App van le thuoc vao bridge

Neu app import truc tiep generated layer, sau nay rat kho thay doi protocol.

Giai phap:

- enforce import boundary qua review va docs

### 2. Tach `storage` qua som

Neu persistence chua on, co the tao crate rong va vo ich.

Giai phap:

- bat dau bang API stub, khong dua qua nhieu logic vao ngay

### 3. SDK bi phinh thanh mini app

Neu dua qua nhieu widget vao SDK, package nay se kho giu sach.

Giai phap:

- SDK chi giu state + controller + data adapter
- widget chung dua sang `goox_ui_shared`

### 4. Example app bi bo quen

Neu example khong duoc chay thuong xuyen, no se rot nhanh.

Giai phap:

- dua example vao `build_all.sh`

## Definition of Done cho dot tai cau truc nay

- Co `apps/goox_desktop`
- Co `core/engine` va `core/storage`
- Co `platform/flutter_bridge`
- Co `packages/goox_editor_sdk`
- App chinh import SDK, khong import bridge truc tiep
- Co `examples/simple_editor`
- Co `scripts/build_all.sh` va `scripts/sync_bridge.sh`
- Workspace test/analyze pass

## De xuat file/folder se tao trong dot tiep theo

```text
apps/goox_desktop/
core/engine/
core/storage/
platform/flutter_bridge/
platform/ffi/
packages/goox_editor_sdk/
packages/goox_ui_shared/
examples/simple_editor/
scripts/build_all.sh
scripts/sync_bridge.sh
scripts/apply_patches.sh
```

## Ghi chu cuoi

Neu muon di nhanh ma van an toan, dot tiep theo nen chi lam 3 viec:

1. Dung skeleton thu muc moi.
2. Move `crates/goox_core` sang `core/engine`.
3. Tao `packages/goox_editor_sdk` voi `GooxEditorController` mock-backed.

Sau khi 3 buoc nay on, moi bat dau wire bridge that.
