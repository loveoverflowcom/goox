#!/bin/bash

echo "=== Dart LSP Test Script ==="
echo ""

# Check if Dart is installed
echo "1. Checking Dart installation..."
if command -v dart &> /dev/null; then
    echo "✓ Dart is installed"
    dart --version
else
    echo "✗ Dart is NOT installed"
    echo ""
    echo "To install Dart:"
    echo "  macOS:   brew install dart"
    echo "  Linux:   sudo apt-get install dart"
    echo "  Windows: Download from https://dart.dev/get-dart"
    exit 1
fi

echo ""
echo "2. Testing Dart language server..."
# Test if dart language-server command works
if dart language-server --help &> /dev/null; then
    echo "✓ Dart language server is available"
else
    echo "✗ Dart language server command failed"
    echo "Your Dart SDK might be outdated"
    exit 1
fi

echo ""
echo "3. Creating test Dart file..."
cat > /tmp/test_dart_lsp.dart << 'EOF'
import 'dart:io';

void main() {
  print('Hello, World!');
  Directory dir = Directory('/tmp');
  print(dir.path);
}
EOF

echo "✓ Test file created at /tmp/test_dart_lsp.dart"

echo ""
echo "=== All checks passed! ==="
echo ""
echo "Your Dart LSP should work in Goox editor."
echo "Try:"
echo "  1. Open a .dart file"
echo "  2. Right-click on 'Directory' or other symbols"
echo "  3. Select 'Go to Definition'"
echo "  4. Hover over symbols to see documentation"
