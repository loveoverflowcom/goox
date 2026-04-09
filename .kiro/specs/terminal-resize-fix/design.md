# Terminal Resize Fix - Bugfix Design

## Overview

Terminal trong goox_terminal không hoạt động đúng cách do thiếu cơ chế tự động đồng bộ kích thước giữa Terminal view và PTY process. Khi terminal view thay đổi kích thước (do user resize window hoặc layout changes), PTY không được thông báo về kích thước mới, dẫn đến mất đồng bộ và terminal không hiển thị đúng.

Fix này sẽ thêm callback `terminal.onResize` vào TerminalController để tự động resize PTY mỗi khi terminal view thay đổi kích thước, theo pattern từ xterm.dart example.

## Glossary

- **Bug_Condition (C)**: Terminal view thay đổi kích thước nhưng PTY không được resize tương ứng
- **Property (P)**: Khi terminal view resize, PTY phải được tự động resize để khớp với kích thước mới
- **Preservation**: Các chức năng hiện có (input/output handling, status tracking, title parsing) phải hoạt động bình thường
- **Terminal**: Instance của xterm Terminal - xử lý terminal emulation và rendering
- **PTY (Pseudo-Terminal)**: Process backend chạy shell, được quản lý bởi flutter_pty
- **viewWidth/viewHeight**: Kích thước hiện tại của terminal view (số columns và rows)
- **onResize callback**: Callback được gọi bởi xterm khi terminal view thay đổi kích thước

## Bug Details

### Bug Condition

Bug xảy ra khi terminal view thay đổi kích thước (do user resize window, layout changes, hoặc explicit resize call) nhưng PTY process không được thông báo về kích thước mới. Điều này dẫn đến:
- Terminal view và PTY có kích thước khác nhau
- Text wrapping không đúng
- Cursor positioning sai
- Shell prompt không hiển thị đúng

**Formal Specification:**
```
FUNCTION isBugCondition(event)
  INPUT: event of type TerminalResizeEvent
  OUTPUT: boolean
  
  RETURN event.type == "terminal_view_resized"
         AND terminal.viewWidth != pty.columns
         AND terminal.viewHeight != pty.rows
         AND NOT pty.resize_called_automatically
END FUNCTION
```

### Examples

- **Example 1**: User mở terminal lần đầu
  - Expected: Terminal hiển thị shell prompt với kích thước khớp với view
  - Actual: Terminal không hiển thị gì vì PTY được khởi tạo với kích thước mặc định không khớp với view

- **Example 2**: User resize terminal window từ 80x24 sang 120x30
  - Expected: PTY được resize sang 120x30, shell prompt re-render với width mới
  - Actual: PTY vẫn ở 80x24, text bị wrap sai, cursor positioning lỗi

- **Example 3**: Terminal view thay đổi kích thước do layout change (split panel)
  - Expected: PTY tự động resize theo kích thước mới
  - Actual: PTY giữ nguyên kích thước cũ, gây mất đồng bộ

- **Edge Case**: User resize terminal rất nhanh nhiều lần liên tiếp
  - Expected: PTY được resize theo kích thước cuối cùng, không bị race condition

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- PTY output stream phải tiếp tục được decode và write vào terminal đúng cách
- Terminal input (keyboard, write()) phải tiếp tục được encode và gửi đến PTY
- Status tracking (initializing, running, exited, error) phải hoạt động bình thường
- Title parsing từ OSC escape sequences phải tiếp tục hoạt động
- Restart và dispose logic phải hoạt động đúng

**Scope:**
Tất cả các operations không liên quan đến resize phải hoạt động giống như trước. Bao gồm:
- Input/output data flow giữa terminal và PTY
- Status lifecycle management
- Error handling và recovery
- Title updates từ shell

## Hypothesized Root Cause

Dựa trên bug description và code analysis, root cause chính là:

1. **Missing onResize Callback**: TerminalController không đăng ký callback `terminal.onResize`
   - Trong xterm.dart example: `terminal.onResize = (w, h, pw, ph) { pty.resize(h, w); }`
   - Trong TerminalController hiện tại: Không có callback này
   - Kết quả: Terminal view có thể resize nhưng PTY không được thông báo

2. **Initial Size Mismatch**: Khi khởi tạo, PTY được tạo với `initialSize` nhưng terminal view có thể có kích thước khác
   - PTY được tạo với `columns: _size.cols, rows: _size.rows`
   - Terminal view có kích thước thực tế là `terminal.viewWidth x terminal.viewHeight`
   - Nếu hai giá trị này không khớp ngay từ đầu, terminal sẽ không hoạt động đúng

3. **No Automatic Sync**: Không có cơ chế tự động đồng bộ kích thước
   - Method `resize()` tồn tại nhưng phải được gọi thủ công
   - Không có listener nào tự động gọi `resize()` khi terminal view thay đổi

4. **Restart Missing Callback**: Khi restart terminal, callback cũng không được đăng ký lại
   - Method `restart()` tạo PTY mới nhưng không setup onResize callback
   - Sau restart, terminal vẫn không tự động resize

## Correctness Properties

Property 1: Bug Condition - Automatic PTY Resize on Terminal View Change

_For any_ terminal view resize event where the new dimensions differ from current PTY dimensions, the fixed TerminalController SHALL automatically call `pty.resize()` with the new dimensions, ensuring PTY and terminal view stay synchronized.

**Validates: Requirements 2.1, 2.3, 2.4**

Property 2: Preservation - Input/Output Data Flow

_For any_ input or output operation that does NOT involve resize events, the fixed TerminalController SHALL produce exactly the same behavior as the original code, preserving all existing data flow, status tracking, and error handling functionality.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

## Fix Implementation

### Changes Required

Assuming root cause analysis đúng, cần thực hiện các thay đổi sau:

**File**: `packages/goox_terminal/lib/src/controllers/terminal_controller.dart`

**Function**: `initialize()` và `restart()`

**Specific Changes**:

1. **Add onResize Callback in initialize()**: Sau khi setup `terminal.onOutput`, thêm callback `terminal.onResize`
   ```dart
   // After: _terminal.onOutput = (output) { ... }
   // Add:
   _terminal.onResize = (width, height, pixelWidth, pixelHeight) {
     if (_pty != null && status == TerminalStatus.running) {
       _pty!.resize(height, width);
       _size = PtySize(rows: height, cols: width);
     }
   };
   ```

2. **Add onResize Callback in restart()**: Tương tự, thêm callback sau khi setup terminal.onOutput trong restart()
   ```dart
   // After: _terminal.onOutput = (output) { ... }
   // Add:
   _terminal.onResize = (width, height, pixelWidth, pixelHeight) {
     if (_pty != null && status == TerminalStatus.running) {
       _pty!.resize(height, width);
       _size = PtySize(rows: height, cols: width);
     }
   };
   ```

3. **Initial Size Sync**: Sau khi tạo PTY, sync kích thước với terminal view
   ```dart
   // After: _pty = Pty.start(...)
   // Add:
   if (_terminal.viewWidth > 0 && _terminal.viewHeight > 0) {
     _pty!.resize(_terminal.viewHeight, _terminal.viewWidth);
     _size = PtySize(rows: _terminal.viewHeight, cols: _terminal.viewWidth);
   }
   ```

4. **Clear onResize in dispose()**: Cleanup callback khi dispose
   ```dart
   // In dispose(), after canceling subscription:
   _terminal.onResize = null;
   ```

5. **Update resize() method documentation**: Clarify rằng method này dùng cho manual resize, còn auto resize được xử lý bởi onResize callback

**Note về parameter order**: 
- xterm `onResize` callback nhận parameters: `(width, height, pixelWidth, pixelHeight)` - width là columns, height là rows
- flutter_pty `resize()` method nhận parameters: `(rows, columns)` - rows trước, columns sau
- Cần chú ý swap order khi gọi: `pty.resize(height, width)`

## Testing Strategy

### Validation Approach

Testing strategy gồm hai phases: 
1. Exploratory testing trên UNFIXED code để confirm bug và root cause
2. Fix checking và preservation checking trên FIXED code để verify fix hoạt động đúng

### Exploratory Bug Condition Checking

**Goal**: Demonstrate bug trên unfixed code và confirm root cause analysis

**Test Plan**: Tạo terminal instance, observe initial state và resize behavior trên unfixed code

**Test Cases**:
1. **Initial Display Test**: Khởi tạo terminal và check xem prompt có hiển thị không (will fail on unfixed code)
   - Create TerminalController với initialSize = 80x24
   - Check terminal.viewWidth và terminal.viewHeight
   - Check PTY columns và rows
   - Expected counterexample: viewWidth/viewHeight khác với PTY dimensions

2. **Manual Resize Test**: Gọi resize() method và check xem có lỗi không (may fail on unfixed code)
   - Initialize terminal
   - Call controller.resize(30, 120)
   - Expected counterexample: Có thể gặp lỗi hoặc resize không có effect

3. **View Resize Test**: Simulate terminal view resize và check PTY có được resize không (will fail on unfixed code)
   - Initialize terminal
   - Trigger terminal view resize (thông qua layout change)
   - Check PTY dimensions
   - Expected counterexample: PTY dimensions không thay đổi

4. **Restart Resize Test**: Restart terminal và check resize behavior (will fail on unfixed code)
   - Initialize terminal
   - Restart terminal
   - Trigger resize
   - Expected counterexample: Resize không hoạt động sau restart

**Expected Counterexamples**:
- Terminal view và PTY có kích thước khác nhau ngay từ đầu
- PTY không được resize khi terminal view thay đổi kích thước
- Possible causes: missing onResize callback, initial size mismatch, no auto-sync mechanism

### Fix Checking

**Goal**: Verify rằng với mọi resize event, PTY được tự động resize đúng

**Pseudocode:**
```
FOR ALL resizeEvent WHERE isBugCondition(resizeEvent) DO
  result := handleResize_fixed(resizeEvent)
  ASSERT pty.columns == terminal.viewWidth
  ASSERT pty.rows == terminal.viewHeight
  ASSERT terminal displays correctly with new size
END FOR
```

### Preservation Checking

**Goal**: Verify rằng các operations không liên quan đến resize vẫn hoạt động giống như trước

**Pseudocode:**
```
FOR ALL operation WHERE NOT isResizeOperation(operation) DO
  ASSERT handleOperation_original(operation) == handleOperation_fixed(operation)
END FOR
```

**Testing Approach**: Property-based testing được recommend vì:
- Tự động generate nhiều test cases với different inputs
- Catch edge cases mà manual tests có thể miss
- Provide strong guarantees về behavior preservation

**Test Plan**: Observe behavior trên UNFIXED code cho non-resize operations, sau đó write property tests để verify behavior không thay đổi

**Test Cases**:
1. **Input/Output Preservation**: Observe rằng terminal input/output hoạt động đúng trên unfixed code, verify tiếp tục hoạt động sau fix
2. **Status Tracking Preservation**: Observe status transitions (initializing → running → exited) trên unfixed code, verify không thay đổi
3. **Title Parsing Preservation**: Observe title updates từ OSC sequences trên unfixed code, verify tiếp tục hoạt động
4. **Error Handling Preservation**: Observe error handling behavior trên unfixed code, verify không thay đổi

### Unit Tests

- Test onResize callback được đăng ký đúng trong initialize()
- Test onResize callback được đăng ký đúng trong restart()
- Test PTY được resize với đúng dimensions khi callback được gọi
- Test initial size sync sau khi tạo PTY
- Test onResize callback được cleared trong dispose()
- Test edge case: resize với invalid dimensions
- Test edge case: resize khi terminal không running
- Test edge case: multiple rapid resizes

### Property-Based Tests

- Generate random terminal sizes và verify PTY luôn được resize đúng
- Generate random sequences of operations (input, output, resize) và verify behavior consistency
- Generate random resize events và verify không có race conditions
- Test preservation: generate random non-resize operations và verify behavior unchanged

### Integration Tests

- Test full terminal lifecycle với resize events: initialize → resize → input/output → dispose
- Test terminal trong real Flutter widget tree với layout changes
- Test multiple terminals với independent resize events
- Test terminal restart với resize events
- Test terminal với rapid window resizing
