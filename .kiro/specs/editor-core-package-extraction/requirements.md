# Requirements Document

## Introduction

Tài liệu này mô tả các yêu cầu cho việc tách phần giao tiếp với language server thành một package độc lập trong thư mục packages/. Package mới sẽ chứa các interface và implementation để giao tiếp với Rust backend thông qua flutter_rust_bridge, giúp tái sử dụng code và tổ chức tốt hơn.

## Glossary

- **Editor_Core_Package**: Package mới chứa logic giao tiếp với language server
- **EditorCoreClient**: Interface trừu tượng định nghĩa các phương thức giao tiếp với editor core
- **RustEditorCoreClient**: Implementation cụ thể của EditorCoreClient sử dụng Rust backend
- **Language_Server**: Backend service xử lý các tính năng editor (syntax highlighting, autocomplete, hover, v.v.)
- **Flutter_Rust_Bridge**: Thư viện để giao tiếp giữa Flutter (Dart) và Rust
- **Model_Classes**: Các data class như EditorViewState, EditorPatch, CursorPosition, LanguageServerLocation, LanguageServerHover
- **Main_Application**: Ứng dụng Flutter chính sử dụng Editor_Core_Package

## Requirements

### Requirement 1: Package Structure Creation

**User Story:** Là một developer, tôi muốn có một package độc lập cho editor core, để có thể tái sử dụng và quản lý code dễ dàng hơn.

#### Acceptance Criteria

1. THE Editor_Core_Package SHALL be created in the packages/ directory with standard Dart package structure
2. THE Editor_Core_Package SHALL contain a pubspec.yaml file with package metadata and dependencies
3. THE Editor_Core_Package SHALL include flutter_rust_bridge as a dependency
4. THE Editor_Core_Package SHALL have a lib/ directory containing all source code
5. THE Editor_Core_Package SHALL include an analysis_options.yaml file for code quality standards

### Requirement 2: EditorCoreClient Interface Definition

**User Story:** Là một developer, tôi muốn có một interface rõ ràng cho editor core client, để có thể dễ dàng thay đổi implementation hoặc mock trong testing.

#### Acceptance Criteria

1. THE Editor_Core_Package SHALL define an abstract EditorCoreClient interface
2. THE EditorCoreClient SHALL declare methods for all editor core operations (open file, edit content, get diagnostics, v.v.)
3. THE EditorCoreClient SHALL use Model_Classes as parameter and return types
4. THE EditorCoreClient SHALL be exported from the package's main library file

### Requirement 3: RustEditorCoreClient Implementation

**User Story:** Là một developer, tôi muốn có implementation giao tiếp với Rust backend, để editor có thể sử dụng các tính năng language server.

#### Acceptance Criteria

1. THE Editor_Core_Package SHALL provide a RustEditorCoreClient class implementing EditorCoreClient
2. THE RustEditorCoreClient SHALL use Flutter_Rust_Bridge to communicate with Rust backend
3. WHEN a method is called on RustEditorCoreClient, THE RustEditorCoreClient SHALL invoke the corresponding Rust function via Flutter_Rust_Bridge
4. IF a Rust function call fails, THEN THE RustEditorCoreClient SHALL throw a descriptive exception
5. THE RustEditorCoreClient SHALL handle data conversion between Dart and Rust types

### Requirement 4: Model Classes Migration

**User Story:** Là một developer, tôi muốn các model class được tổ chức trong package mới, để dễ dàng import và sử dụng.

#### Acceptance Criteria

1. THE Editor_Core_Package SHALL include EditorViewState model class
2. THE Editor_Core_Package SHALL include EditorPatch model class
3. THE Editor_Core_Package SHALL include CursorPosition model class
4. THE Editor_Core_Package SHALL include LanguageServerLocation model class
5. THE Editor_Core_Package SHALL include LanguageServerHover model class
6. THE Model_Classes SHALL be immutable data classes with copyWith methods
7. THE Model_Classes SHALL implement Equatable for value comparison
8. THE Model_Classes SHALL be exported from the package's main library file

### Requirement 5: Package Export Organization

**User Story:** Là một developer, tôi muốn import dễ dàng các class từ package, để code gọn gàng và rõ ràng.

#### Acceptance Criteria

1. THE Editor_Core_Package SHALL provide a main library file (editor_core.dart) that exports all public APIs
2. THE Editor_Core_Package SHALL export EditorCoreClient interface
3. THE Editor_Core_Package SHALL export RustEditorCoreClient implementation
4. THE Editor_Core_Package SHALL export all Model_Classes
5. THE Editor_Core_Package SHALL NOT export internal implementation details

### Requirement 6: Dependency Management

**User Story:** Là một developer, tôi muốn package có dependencies rõ ràng, để dễ dàng quản lý và tránh conflict.

#### Acceptance Criteria

1. THE Editor_Core_Package SHALL declare flutter_rust_bridge as a dependency in pubspec.yaml
2. THE Editor_Core_Package SHALL declare equatable as a dependency for Model_Classes
3. THE Editor_Core_Package SHALL use compatible SDK version with Main_Application
4. THE Editor_Core_Package SHALL set publish_to: none to prevent accidental publishing
5. WHEN Main_Application adds Editor_Core_Package as dependency, THE Main_Application SHALL reference it using path dependency

### Requirement 7: Error Handling

**User Story:** Là một developer, tôi muốn có error handling rõ ràng, để dễ dàng debug khi có vấn đề.

#### Acceptance Criteria

1. WHEN RustEditorCoreClient encounters a Rust bridge error, THEN THE RustEditorCoreClient SHALL throw an EditorCoreException with descriptive message
2. THE Editor_Core_Package SHALL define custom exception classes for different error types
3. THE EditorCoreException SHALL include error message and optional stack trace
4. THE EditorCoreException SHALL be exported from the package

### Requirement 8: Documentation

**User Story:** Là một developer, tôi muốn có documentation đầy đủ, để hiểu cách sử dụng package.

#### Acceptance Criteria

1. THE Editor_Core_Package SHALL include a README.md file with usage examples
2. THE EditorCoreClient interface SHALL have dartdoc comments for all public methods
3. THE Model_Classes SHALL have dartdoc comments describing each field
4. THE README.md SHALL include installation instructions
5. THE README.md SHALL include basic usage examples showing how to create and use RustEditorCoreClient

### Requirement 9: Main Application Integration

**User Story:** Là một developer, tôi muốn Main_Application có thể sử dụng package mới, để thay thế code cũ.

#### Acceptance Criteria

1. WHEN Main_Application adds Editor_Core_Package to pubspec.yaml, THE Main_Application SHALL be able to import editor_core package
2. THE Main_Application SHALL be able to create instances of RustEditorCoreClient
3. THE Main_Application SHALL be able to use EditorCoreClient interface for dependency injection
4. THE Main_Application SHALL be able to import and use all Model_Classes from Editor_Core_Package

### Requirement 10: Code Quality Standards

**User Story:** Là một developer, tôi muốn package tuân thủ code quality standards, để đảm bảo code maintainable.

#### Acceptance Criteria

1. THE Editor_Core_Package SHALL pass all linter rules defined in analysis_options.yaml
2. THE Editor_Core_Package SHALL use consistent naming conventions (camelCase for variables, PascalCase for classes)
3. THE Editor_Core_Package SHALL have no unused imports or variables
4. THE Editor_Core_Package SHALL use final keyword for immutable fields
5. THE Editor_Core_Package SHALL follow Dart style guide for code formatting
