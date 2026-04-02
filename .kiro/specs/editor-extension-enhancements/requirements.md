# Requirements Document

## Introduction

Tài liệu này mô tả các yêu cầu cho việc cấu trúc lại hệ thống extension của editor trong ứng dụng Goox Desktop. Hiện tại, editor sử dụng syntax highlighting được hardcode cho các ngôn ngữ phổ biến, hiển thị documentation tooltips dạng plain text, và sử dụng font chữ mặc định. Feature này sẽ chuyển sang kiến trúc extension mới dựa trên Tree-sitter (tương tự Zed editor) với các khả năng:

1. Extensions cung cấp syntax highlighting thông qua Tree-sitter grammars và query files (.scm)
2. Extensions có thể chứa logic thực thi (WASM) và giao diện tùy chỉnh (webview)
3. Hỗ trợ markdown trong documentation tooltips từ language server
4. Cho phép người dùng tùy chỉnh font chữ trong editor
5. Hỗ trợ themes tùy chỉnh từ extensions

## Glossary

- **Editor**: Thành phần chính của ứng dụng để chỉnh sửa code, hiện được implement trong `GooxEditorCanvas`
- **Extension**: Một package có thể cài đặt được để mở rộng chức năng của editor, được quản lý qua `extension.json` manifest
- **Tree_Sitter**: Parser generator tool và incremental parsing library sử dụng để phân tích cú pháp code
- **Tree_Sitter_Grammar**: Compiled grammar file (.wasm hoặc binary) được Tree-sitter sử dụng để parse code
- **Query_File**: File .scm chứa Tree-sitter queries để extract thông tin từ syntax tree (highlights, brackets, indents, outline, injections)
- **WASM_Module**: WebAssembly module chứa logic thực thi của extension (extension.wasm)
- **Webview**: Component hiển thị HTML/CSS/JS tùy chỉnh cho rendering (ví dụ: image viewer, markdown preview)
- **Language_Server**: Một process riêng biệt cung cấp các tính năng ngôn ngữ thông qua Language Server Protocol (LSP)
- **Documentation_Tooltip**: Popup hiển thị thông tin về symbol khi hover, nhận từ LSP hover response
- **Syntax_Highlighter**: Component chịu trách nhiệm tô màu code dựa trên Tree-sitter queries
- **Font_Family**: Tên của font chữ được sử dụng trong editor (ví dụ: "Fira Code", "JetBrains Mono")
- **Google_Fonts**: Dịch vụ cung cấp web fonts miễn phí có thể tích hợp vào Flutter apps
- **Markdown_Renderer**: Component chuyển đổi markdown text thành formatted rich text
- **Extension_Manifest**: File extension.json chứa metadata và cấu hình của extension
- **Language_Config**: File config.toml trong thư mục languages/ định nghĩa cấu hình ngôn ngữ (brackets, comments, indentation)

## Requirements

### Requirement 1: Extension Manifest Structure

**User Story:** Là một extension developer, tôi muốn định nghĩa extension với manifest rõ ràng, để editor có thể load và validate extension đúng cách.

#### Acceptance Criteria

1. THE Extension SHALL use `extension.json` as the main manifest file
2. THE Extension_Manifest SHALL support fields: `id`, `name`, `version`, `description`, `author`, `repository`
3. WHERE an extension provides language support, THE Extension_Manifest SHALL reference language configurations in `languages/` directory
4. WHERE an extension provides webview rendering, THE Extension_Manifest SHALL specify `webview_entry` pointing to HTML file
5. WHERE an extension provides WASM logic, THE Extension_Manifest SHALL include `extension.wasm` file
6. WHERE an extension provides themes, THE Extension_Manifest SHALL reference theme files in `themes/` directory
7. THE Extension_Manifest SHALL specify supported file extensions via `file_types` array
8. THE Extension SHALL organize assets (icons, logos) in `assets/` directory

### Requirement 2: Tree-sitter Query Parser

**User Story:** Là một developer, tôi muốn editor có thể đọc và parse Tree-sitter query files (.scm), để có thể sử dụng các query definitions cho syntax highlighting và code analysis.

#### Acceptance Criteria

1. THE Query_Parser SHALL parse .scm files with Tree-sitter query syntax
2. THE Query_Parser SHALL support query files: `highlights.scm`, `brackets.scm`, `indents.scm`, `outline.scm`, `injections.scm`
3. WHEN a query file contains capture names (e.g., @keyword, @function, @variable), THE Query_Parser SHALL extract and map them to semantic tokens
4. WHEN a query file contains predicates (e.g., #match?, #eq?), THE Query_Parser SHALL parse and evaluate them correctly
5. THE Query_Parser SHALL handle nested patterns and alternations in queries
6. IF a query file contains syntax errors, THEN THE Query_Parser SHALL return a descriptive error message with line and column information
7. THE Query_Parser SHALL validate that capture names follow Tree-sitter naming conventions
8. FOR ALL valid Query_Files, parsing then serializing then parsing SHALL produce an equivalent query structure (round-trip property)

### Requirement 3: Tree-sitter Query Pretty Printer

**User Story:** Là một extension developer, tôi muốn có công cụ để format và validate Tree-sitter query files, để đảm bảo query files của tôi đúng chuẩn.

#### Acceptance Criteria

1. THE Pretty_Printer SHALL format Query_File objects back into valid .scm files
2. THE Pretty_Printer SHALL preserve all semantic information including patterns, captures, and predicates
3. THE Pretty_Printer SHALL use consistent indentation and formatting
4. WHEN a query is parsed and then pretty-printed, THE output SHALL be valid .scm syntax that can be parsed again

### Requirement 4: Language Configuration Parser

**User Story:** Là một developer, tôi muốn extensions có thể định nghĩa cấu hình ngôn ngữ (brackets, comments, indentation), để editor hỗ trợ các tính năng editing cơ bản cho ngôn ngữ đó.

#### Acceptance Criteria

1. THE Language_Config parser SHALL parse config.toml files in `languages/{language_name}/` directories
2. THE Language_Config SHALL extract fields: `name`, `grammar`, `path_suffixes`, `line_comments`, `block_comment`, `brackets`, `autoclose_before`
3. WHEN brackets are defined, THE Editor SHALL support auto-closing and matching bracket highlighting
4. WHEN line_comments are defined, THE Editor SHALL support comment toggling with keyboard shortcuts
5. WHEN indentation patterns are defined, THE Editor SHALL apply auto-indentation rules
6. THE Language_Config SHALL support bracket definitions with `start`, `end`, `close`, `newline`, and `not_in` fields
7. IF config.toml is missing or invalid, THEN THE Editor SHALL use default language configuration
8. THE Language_Config parser SHALL validate that referenced grammar names exist

### Requirement 5: Tree-sitter Based Syntax Highlighting

**User Story:** Là một developer, tôi muốn syntax highlighting sử dụng Tree-sitter queries, để có highlighting chính xác và hiệu năng cao hơn regex-based approaches.

#### Acceptance Criteria

1. WHEN an extension includes highlights.scm, THE Syntax_Highlighter SHALL use Tree-sitter to parse code and apply query matches
2. THE Syntax_Highlighter SHALL map Tree-sitter captures (@keyword, @function, @variable, etc.) to theme colors
3. THE Syntax_Highlighter SHALL support all standard Tree-sitter capture names following Zed conventions
4. WHEN a file is opened, THE Syntax_Highlighter SHALL incrementally parse and highlight visible regions
5. THE Syntax_Highlighter SHALL update highlighting incrementally when code is edited
6. THE Syntax_Highlighter SHALL cache parse trees and reuse them for unchanged regions
7. IF Tree-sitter parsing fails, THEN THE Editor SHALL display the code without highlighting and log the error
8. THE Syntax_Highlighter SHALL support syntax injections via injections.scm for embedded languages

### Requirement 6: Markdown Support in Documentation Tooltips

#### Acceptance Criteria

1. WHEN the Language_Server returns hover information with markdown content, THE Documentation_Tooltip SHALL render the markdown as formatted text
2. THE Markdown_Renderer SHALL support common markdown syntax including bold, italic, code blocks, inline code, and links
3. THE Markdown_Renderer SHALL support fenced code blocks with triple backticks (```)
4. THE Markdown_Renderer SHALL preserve code formatting within code blocks using monospace font
5. WHEN markdown content contains Dart-style doc comments (```dart), THE Markdown_Renderer SHALL apply syntax highlighting to the code block
6. THE Documentation_Tooltip SHALL maintain readable contrast ratios in both light and dark themes
7. IF the Language_Server returns plain text without markdown, THEN THE Documentation_Tooltip SHALL display it as plain text
8. THE Documentation_Tooltip SHALL automatically adjust its size based on the rendered markdown content

### Requirement 7: Configurable Editor Font

**User Story:** Là một developer, tôi muốn thay đổi font chữ trong editor, để có trải nghiệm tương tự như VSCode hoặc Sublime Text với các font lập trình chuyên dụng.

#### Acceptance Criteria

1. THE Editor SHALL support a configurable `fontFamily` setting in addition to existing `fontSize` and `fontWeight`
2. THE App_Settings SHALL persist the selected font family across application restarts
3. THE Editor SHALL apply the selected font family to all code editing areas
4. WHEN a font family is not available on the system, THE Editor SHALL fall back to the default monospace font
5. THE Editor SHALL display a preview of the selected font in the settings UI
6. THE Editor SHALL support common programming fonts including "Fira Code", "JetBrains Mono", "Source Code Pro", and "Cascadia Code"

### Requirement 8: Google Fonts Integration

**User Story:** Là một developer, tôi muốn sử dụng fonts từ Google Fonts trong editor, để có nhiều lựa chọn font chữ đẹp mà không cần cài đặt thủ công.

#### Acceptance Criteria

1. THE Editor SHALL integrate with Google Fonts API to provide a list of monospace fonts
2. THE Settings_UI SHALL display available Google Fonts in a searchable list
3. WHEN a user selects a Google Font, THE Editor SHALL download and cache the font locally
4. THE Editor SHALL load cached fonts on startup to avoid network delays
5. IF a Google Font fails to download, THEN THE Editor SHALL show an error message and keep the current font
6. THE Editor SHALL support font variants including different weights (Light, Regular, Medium, Bold)
7. WHERE the user has an internet connection, THE Editor SHALL check for font updates periodically

### Requirement 9: Extension Manifest Validation

**User Story:** Là một extension developer, tôi muốn nhận được thông báo rõ ràng khi extension.json của extension có lỗi, để dễ dàng sửa chữa và đảm bảo extension hoạt động đúng.

#### Acceptance Criteria

1. THE Extension_Manager SHALL validate the `extension.json` schema when loading extensions
2. THE Extension_Manager SHALL verify required fields: `id`, `name`, `version`
3. WHEN `languages/` directory exists, THE Extension_Manager SHALL validate that config.toml and required .scm files are present
4. WHEN `webview/` directory exists, THE Extension_Manager SHALL verify that index.html exists
5. IF any file path is absolute or contains path traversal (".."), THEN THE Extension_Manager SHALL reject the extension
6. THE Extension_Manager SHALL provide descriptive error messages for invalid configurations
7. THE Extension_Manager SHALL log validation errors to help extension developers debug issues
8. WHEN an extension is imported, THE Extension_Manager SHALL validate the configuration before copying files

### Requirement 10: Syntax Highlighting Performance

**User Story:** Là một developer, tôi muốn syntax highlighting hoạt động mượt mà ngay cả với files lớn, để không bị lag khi chỉnh sửa code.

#### Acceptance Criteria

1. THE Syntax_Highlighter SHALL highlight visible lines incrementally rather than the entire document
2. WHEN scrolling through a large file, THE Syntax_Highlighter SHALL highlight new visible lines within 16ms (60 FPS)
3. THE Syntax_Highlighter SHALL cache parse trees and highlighting results for unchanged regions
4. WHEN the document is edited, THE Syntax_Highlighter SHALL only re-parse and re-highlight affected regions
5. THE Syntax_Highlighter SHALL use Tree-sitter's incremental parsing to minimize re-parsing overhead
6. IF parsing takes longer than 100ms for a visible region, THEN THE Syntax_Highlighter SHALL skip highlighting for that region and log a warning

### Requirement 11: Theme-Aware Syntax Colors

**User Story:** Là một developer, tôi muốn syntax colors tự động thay đổi khi chuyển giữa light và dark theme, để code luôn dễ đọc trong mọi điều kiện.

#### Acceptance Criteria

1. THE Syntax_Highlighter SHALL maintain separate color mappings for light and dark themes
2. WHEN the theme changes, THE Editor SHALL immediately re-apply syntax highlighting with the new color scheme
3. THE color mappings SHALL follow Zed's color conventions for Tree-sitter captures
4. THE Syntax_Highlighter SHALL map Tree-sitter captures to semantic color categories (keyword, type, string, comment, function, variable, etc.)
5. WHERE an extension provides custom theme colors in `themes/theme.json`, THE Syntax_Highlighter SHALL use those colors instead of defaults
6. THE Editor SHALL ensure all syntax colors meet WCAG AA contrast requirements for readability

### Requirement 12: Extension Hot Reload

**User Story:** Là một extension developer, tôi muốn thay đổi trong extension được áp dụng ngay lập tức mà không cần restart app, để tăng tốc độ phát triển extension.

#### Acceptance Criteria

1. WHEN an extension's .scm query files are modified, THE Editor SHALL detect the change and reload the queries
2. WHEN an extension is enabled or disabled, THE Editor SHALL refresh syntax highlighting for all open files
3. THE Extension_Manager SHALL watch for file changes in enabled extensions
4. WHEN a query reload fails, THE Editor SHALL keep using the previous valid queries and show an error notification
5. THE Editor SHALL re-apply syntax highlighting to all open files after a successful query reload

### Requirement 13: Dual-Mode Extension Support

**User Story:** Là một developer, tôi muốn extensions có thể hỗ trợ cả language editing và webview rendering, để có thể chỉnh sửa code với syntax highlighting và preview kết quả trong cùng một extension.

#### Acceptance Criteria

1. WHEN an extension has only `languages/` directory, THE Editor SHALL classify it as language support extension
2. WHEN an extension has only `webview/` directory, THE Editor SHALL classify it as renderer extension
3. WHEN an extension has both `languages/` and `webview/` directories, THE Editor SHALL support dual-mode operation
4. IN dual-mode, THE Editor SHALL display code with syntax highlighting by default
5. IN dual-mode, THE Editor SHALL provide a "Preview" button to switch to webview rendering
6. WHEN switching between modes, THE Editor SHALL preserve the current scroll position and cursor location
7. THE Editor SHALL allow users to configure default mode (editor or preview) for dual-mode extensions

### Requirement 14: WASM Extension Logic Execution

**User Story:** Là một extension developer, tôi muốn viết logic thực thi bằng Rust và compile sang WASM, để extension có thể thực hiện các tác vụ phức tạp một cách hiệu quả.

#### Acceptance Criteria

1. WHEN an extension includes `extension.wasm`, THE Extension_Manager SHALL load and initialize the WASM module
2. THE WASM_Module SHALL have access to a sandboxed API for file reading, event handling, and UI updates
3. THE Extension_Manager SHALL provide a secure communication channel between Dart and WASM via message passing
4. IF WASM module initialization fails, THEN THE Extension_Manager SHALL log the error and disable the extension
5. THE WASM_Module SHALL be able to register event handlers for file open, save, and edit events
6. THE Extension_Manager SHALL enforce resource limits (memory, CPU time) for WASM execution
7. THE WASM_Module SHALL be able to send notifications and UI updates to the editor

### Requirement 15: Webview Integration

**User Story:** Là một developer, tôi muốn extensions có thể hiển thị custom UI bằng HTML/CSS/JS, để tạo các trải nghiệm tùy chỉnh như image viewer, markdown preview, hoặc diagram renderer.

#### Acceptance Criteria

1. WHEN an extension has `webview/index.html`, THE Editor SHALL load and display the webview in an embedded browser
2. THE Webview SHALL have access to extension assets via relative paths
3. THE Webview SHALL be able to communicate with the editor via a message passing API
4. THE Editor SHALL provide webview API for: reading file content, receiving file change events, sending UI updates
5. THE Webview SHALL be sandboxed and cannot access arbitrary file system paths
6. WHEN a file is opened with a webview extension, THE Editor SHALL pass the file content to the webview
7. THE Webview SHALL support responsive layouts that adapt to editor panel size

### Requirement 16: Theme Support

**User Story:** Là một extension developer, tôi muốn cung cấp custom themes cho editor, để người dùng có thể tùy chỉnh màu sắc theo sở thích.

#### Acceptance Criteria

1. WHEN an extension includes `themes/theme.json`, THE Extension_Manager SHALL register the theme
2. THE theme.json SHALL define color mappings for Tree-sitter captures, UI elements, and editor components
3. THE Editor SHALL allow users to select and apply extension-provided themes
4. WHEN a theme is applied, THE Editor SHALL update all syntax highlighting and UI colors immediately
5. THE theme.json SHALL support both light and dark variants
6. IF theme.json is invalid, THEN THE Extension_Manager SHALL log the error and skip theme registration
7. THE Editor SHALL validate that theme colors meet WCAG AA contrast requirements before applying
