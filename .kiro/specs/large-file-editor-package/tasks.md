# Implementation Plan: goox_editor - Large File Text Viewer/Editor

## Overview

This implementation plan follows the 6-phase roadmap outlined in the design document. The goox_editor package will be built incrementally, starting with core streaming functionality and progressing through viewport management, UI integration, optimization, advanced features, and comprehensive testing.

The package uses Dart/Flutter and implements a streaming architecture with chunk-based file reading, sliding window buffering, and viewport-based rendering to handle files from 15MB to 100MB while maintaining memory usage under 10MB.

## Tasks

- [ ] 1. Set up package structure and core interfaces
  - Create packages/goox_editor/ directory structure
  - Set up pubspec.yaml with Flutter dependencies
  - Create lib/goox_editor.dart public API file
  - Define core directory structure (core/, viewport/, controller/, widgets/, models/, utils/)
  - Create EditorConfig model with configuration presets
  - _Requirements: 8.1, 8.6_

- [ ] 2. Implement ChunkReader for streaming file I/O
  - [ ] 2.1 Create ChunkReader class with File.openRead() streaming
    - Implement readChunks() method returning Stream<List<String>>
    - Use utf8.decoder and LineSplitter for line-based streaming
    - Implement configurable chunk size (100-300 lines)
    - Add close() method for resource cleanup
    - _Requirements: 1.1, 1.2, 1.3, 8.2_
  
  - [ ]* 2.2 Write property test for ChunkReader
    - **Property 1: Chunk Size Bounds**
    - **Validates: Requirements 1.2**
  
  - [ ]* 2.3 Write unit tests for ChunkReader
    - Test streaming behavior with test files
    - Test chunk size boundaries (100, 200, 300 lines)
    - Test UTF-8 decoding with various encodings
    - Test error handling for missing files
    - Test empty file handling
    - _Requirements: 1.1, 1.2, 1.3_

- [ ] 3. Implement LineBuffer for sliding window management
  - [ ] 3.1 Create LineBuffer class with circular buffer
    - Implement buffer with configurable capacity (500-2000 lines)
    - Add loadChunks() method to consume ChunkReader stream
    - Implement getRange() method for line retrieval
    - Track startLine, endLine, and totalLines properties
    - _Requirements: 2.1, 2.2, 2.3, 8.3_
  
  - [ ] 3.2 Implement updateWindow() for buffer centering
    - Center buffer around target line
    - Maintain ~300 lines before viewport
    - Maintain ~300 lines after viewport
    - Discard lines outside buffer window
    - _Requirements: 2.2, 2.3, 2.4_
  
  - [ ]* 3.3 Write property test for LineBuffer size invariant
    - **Property 2: Buffer Size Invariant**
    - **Validates: Requirements 2.1, 2.4**
  
  - [ ]* 3.4 Write property test for buffer centering
    - **Property 3: Buffer Centering Around Viewport**
    - **Validates: Requirements 2.2, 2.3**
  
  - [ ]* 3.5 Write unit tests for LineBuffer
    - Test sliding window behavior with specific scenarios
    - Test buffer capacity limits (500, 2000 lines)
    - Test line range retrieval boundary cases
    - Test buffer updates when scrolling
    - Test empty buffer and small files
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 4. Checkpoint - Verify core streaming and buffering
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement ViewportManager for scroll tracking
  - [ ] 5.1 Create ViewportManager class with ScrollController integration
    - Implement initialize() method to set up scroll listener
    - Track startLine and endLine based on scroll position
    - Calculate visible line range using lineHeight
    - Implement visibleLineCount getter
    - _Requirements: 3.1, 3.3, 3.4_
  
  - [ ] 5.2 Implement edge detection and buffer update triggering
    - Implement needsBufferUpdate() method
    - Trigger updates when within 100 lines of buffer edge
    - Emit ViewportChange events via stream
    - _Requirements: 3.2, 3.3_
  
  - [ ]* 5.3 Write property test for edge detection
    - **Property 4: Edge Detection Triggers Update**
    - **Validates: Requirements 3.2**
  
  - [ ]* 5.4 Write property test for viewport calculation
    - **Property 5: Viewport Calculation Correctness**
    - **Validates: Requirements 3.3**
  
  - [ ]* 5.5 Write unit tests for ViewportManager
    - Test viewport calculation from scroll position
    - Test edge detection logic (at threshold, before, after)
    - Test viewport change event emission
    - Test viewport at file start and end
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 6. Implement TextControllerUpdater for efficient UI updates
  - [ ] 6.1 Create TextControllerUpdater class with debouncing
    - Implement updateVisibleText() with debounce timer
    - Format visible lines using join('\n')
    - Implement setScrolling() for scroll state tracking
    - Add forceUpdate() method to bypass debounce
    - Configure debounce duration (16-50ms)
    - _Requirements: 4.1, 4.2, 4.4_
  
  - [ ] 6.2 Implement scroll throttling and update skipping
    - Skip updates when isScrolling flag is true
    - Detect scroll velocity from ScrollController
    - Update only when scrolling stops (>50ms idle)
    - _Requirements: 4.5, 4.6, 7.2, 7.3, 7.4_
  
  - [ ]* 6.3 Write property test for visible lines only
    - **Property 6: Visible Lines Only in Controller**
    - **Validates: Requirements 4.1, 4.3, 9.2**
  
  - [ ]* 6.4 Write property test for skip updates while scrolling
    - **Property 7: Skip Updates While Scrolling**
    - **Validates: Requirements 4.5**
  
  - [ ]* 6.5 Write property test for fast scroll skip
    - **Property 10: Skip Updates During Fast Scroll**
    - **Validates: Requirements 7.2, 7.3**
  
  - [ ]* 6.6 Write unit tests for TextControllerUpdater
    - Test debouncing behavior with specific delays
    - Test scroll throttling and update skipping
    - Test visible text formatting
    - Test force update bypasses debounce
    - Test empty visible range
    - _Requirements: 4.1, 4.2, 4.4, 4.5, 4.6_

- [ ] 7. Checkpoint - Verify viewport and controller integration
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Create data models and error handling
  - [ ] 8.1 Create FileContent model
    - Define FileContent class with file, totalLines, totalBytes, isIndexed
    - _Requirements: 10.1_
  
  - [ ] 8.2 Create BufferState model
    - Define BufferState class with lines, startLine, endLine, capacity
    - Implement contains() and helper methods
    - _Requirements: 10.3_
  
  - [ ] 8.3 Create ViewportState model
    - Define ViewportState class with startLine, endLine, scrollOffset, isScrolling
    - Implement visibleLineCount getter
    - _Requirements: 10.4_
  
  - [ ] 8.4 Create EditorException and error types
    - Define EditorException class with message, type, originalError
    - Define EditorErrorType enum (fileNotFound, permissionDenied, encodingError, etc.)
    - _Requirements: 8.6_
  
  - [ ]* 8.5 Write unit tests for data models
    - Test model creation and getters
    - Test helper methods (contains, visibleLineCount)
    - Test error exception creation
    - _Requirements: 10.1, 10.3, 10.4_

- [ ] 9. Implement GooxEditor main widget
  - [ ] 9.1 Create GooxEditor StatefulWidget
    - Define widget constructor with file, config, textStyle, showLineNumbers
    - Add onLoadComplete and onError callbacks
    - _Requirements: 6.3, 8.5, 8.6_
  
  - [ ] 9.2 Implement _GooxEditorState with component initialization
    - Initialize TextEditingController and ScrollController
    - Create ChunkReader, LineBuffer, ViewportManager, TextControllerUpdater instances
    - Wire up component dependencies
    - Set up viewport change listener
    - _Requirements: 10.1, 10.2, 10.5_
  
  - [ ] 9.3 Implement file loading logic
    - Implement _loadFile() method using ChunkReader
    - Load chunks into LineBuffer
    - Initialize ViewportManager
    - Handle errors and call callbacks
    - _Requirements: 1.1, 1.2, 1.3, 9.5_
  
  - [ ] 9.4 Implement build() method with TextField rendering
    - Create Row with optional LineNumberColumn
    - Add TextField with TextEditingController
    - Configure TextField as read-only with monospace font
    - Apply textStyle from widget properties
    - _Requirements: 6.1, 6.2, 6.3, 6.4_
  
  - [ ] 9.5 Implement dispose() for resource cleanup
    - Close ChunkReader
    - Dispose ViewportManager, TextControllerUpdater
    - Dispose TextEditingController and ScrollController
    - _Requirements: 8.6_
  
  - [ ]* 9.6 Write integration tests for GooxEditor
    - Test widget creation and initialization
    - Test file loading and display
    - Test error handling and callbacks
    - Test resource cleanup on dispose
    - _Requirements: 6.3, 8.5, 8.6, 9.5_

- [ ] 10. Implement LineNumberColumn widget
  - [ ] 10.1 Create LineNumberColumn widget
    - Synchronize with main editor scroll position
    - Display line numbers with fixed width
    - Use monospace font for alignment
    - Calculate visible line numbers from scroll offset
    - _Requirements: 6.3_
  
  - [ ]* 10.2 Write unit tests for LineNumberColumn
    - Test line number display
    - Test scroll synchronization
    - Test with different total line counts
    - _Requirements: 6.3_

- [ ] 11. Checkpoint - Verify basic UI functionality
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 12. Implement scroll performance optimizations
  - [ ] 12.1 Add scroll velocity detection
    - Track scroll velocity in ViewportManager
    - Implement velocity threshold configuration
    - Detect fast scroll vs slow scroll
    - _Requirements: 7.1, 7.2, 7.3_
  
  - [ ] 12.2 Implement update throttling during fast scroll
    - Skip TextControllerUpdater updates when velocity exceeds threshold
    - Queue final update when scrolling stops
    - Add configurable throttle duration
    - _Requirements: 7.2, 7.3, 7.4_
  
  - [ ]* 12.3 Write performance tests for scroll optimization
    - Measure FPS during continuous scrolling
    - Test fast scroll (fling gestures)
    - Test slow scroll (drag)
    - Verify frame rate stays above 30 FPS
    - _Requirements: 7.5, 9.4_

- [ ] 13. Implement utility classes
  - [ ] 13.1 Create Debouncer utility
    - Implement generic debouncer with configurable duration
    - Support cancel and force execution
    - _Requirements: 4.4_
  
  - [ ] 13.2 Create MemoryMonitor utility (optional)
    - Monitor memory usage during operations
    - Log warnings if approaching 10MB limit
    - _Requirements: 2.5, 9.3_
  
  - [ ]* 13.3 Write unit tests for utilities
    - Test debouncer timing and cancellation
    - Test memory monitor thresholds
    - _Requirements: 4.4, 9.3_

- [ ] 14. Checkpoint - Verify optimization and utilities
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 15. Implement LineIndex for random access (optional advanced feature)
  - [ ] 15.1 Create LineIndex class
    - Implement sparse index storing byte offsets every N lines
    - Add buildIndex() method for incremental index building
    - Implement getOffsetForLine() and getLineForOffset() methods
    - Track totalLines, isComplete, and progress properties
    - _Requirements: 5.1, 5.2_
  
  - [ ] 15.2 Integrate LineIndex with ChunkReader
    - Add seekToOffset() method to ChunkReader using RandomAccessFile
    - Build index incrementally during initial file read
    - _Requirements: 5.1, 5.2_
  
  - [ ] 15.3 Implement jump-to-line functionality
    - Add jumpToLine() method in ViewportManager
    - Update buffer to include lines around target position
    - Update viewport and trigger UI refresh
    - _Requirements: 5.3_
  
  - [ ]* 15.4 Write property test for index storage
    - **Property 8: Index Stores Offsets**
    - **Validates: Requirements 5.1**
  
  - [ ]* 15.5 Write property test for jump buffer update
    - **Property 9: Jump Updates Buffer Correctly**
    - **Validates: Requirements 5.3**
  
  - [ ]* 15.6 Write unit tests for LineIndex
    - Test index building with various file sizes
    - Test offset retrieval for indexed lines
    - Test seeking with ChunkReader
    - Test jump-to-line with buffer updates
    - _Requirements: 5.1, 5.2, 5.3_

- [ ] 16. Create example application
  - [ ] 16.1 Create example/lib/main.dart demo app
    - Implement file picker for selecting large files
    - Display GooxEditor with selected file
    - Show loading indicator during file load
    - Display error messages using SnackBar
    - _Requirements: 8.5_
  
  - [ ] 16.2 Create test files for example app
    - Generate small_file.txt (1MB)
    - Generate medium_file.txt (15MB)
    - Generate large_file.txt (50MB)
    - _Requirements: 8.5_
  
  - [ ]* 16.3 Test example app with various file sizes
    - Test with 15MB, 50MB, 100MB files
    - Verify smooth scrolling performance
    - Verify memory stays under 10MB
    - _Requirements: 9.1, 9.3, 9.4_

- [ ] 17. Checkpoint - Verify advanced features and example
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 18. Comprehensive integration and performance testing
  - [ ]* 18.1 Write end-to-end file loading tests
    - Test loading 15MB, 50MB, 100MB files
    - Verify initial display within 500ms
    - Verify memory stays under 10MB
    - Verify smooth scrolling performance
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_
  
  - [ ]* 18.2 Write scroll performance integration tests
    - Measure FPS during continuous scrolling
    - Test rapid scroll up and down
    - Test jump-to-line with LineIndex
    - Test extended editing session (30 minutes)
    - _Requirements: 7.5, 9.4_
  
  - [ ]* 18.3 Write memory stability tests
    - Monitor memory usage during file operations
    - Test memory stability over extended use
    - Test buffer cleanup and garbage collection
    - Verify memory stays under 10MB
    - _Requirements: 2.5, 9.3_
  
  - [ ]* 18.4 Run performance benchmarks
    - Benchmark initial load time (target <500ms)
    - Benchmark scroll FPS (target >30 FPS)
    - Benchmark memory usage (target <10MB)
    - Benchmark buffer update latency (target <100ms)
    - _Requirements: 9.1, 9.3, 9.4, 9.5_

- [ ] 19. Documentation and package finalization
  - [ ] 19.1 Write comprehensive README.md
    - Document package purpose and features
    - Provide installation instructions
    - Include usage examples
    - Document configuration options
    - List performance characteristics
    - _Requirements: 8.6_
  
  - [ ] 19.2 Write API documentation
    - Add dartdoc comments to all public classes
    - Document all public methods and properties
    - Include code examples in documentation
    - Document error handling and exceptions
    - _Requirements: 8.6_
  
  - [ ] 19.3 Create CHANGELOG.md
    - Document initial release features
    - List known limitations
    - Outline future enhancement plans
    - _Requirements: 8.6_
  
  - [ ] 19.4 Finalize pubspec.yaml
    - Set version to 0.1.0
    - Add package description
    - List all dependencies with versions
    - Add repository and issue tracker URLs
    - _Requirements: 8.1, 8.6_

- [ ] 20. Final checkpoint - Package ready for use
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- Integration tests verify component interactions and performance targets
- The implementation follows the 6-phase roadmap: Core Streaming → Viewport Management → UI Integration → Optimization → Advanced Features → Testing & Documentation
- Memory target: <10MB during normal operation
- Performance target: >30 FPS during scrolling, <500ms initial load
- File size support: 15MB - 100MB
