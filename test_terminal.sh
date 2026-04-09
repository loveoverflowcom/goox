#!/bin/bash

echo "=== Testing Terminal Fix ==="
echo ""
echo "1. Cleaning build..."
flutter clean

echo ""
echo "2. Verifying entitlements..."
echo "DebugProfile.entitlements:"
grep -A 2 "allow-unsigned-executable-memory" macos/Runner/DebugProfile.entitlements
grep -A 2 "disable-library-validation" macos/Runner/DebugProfile.entitlements

echo ""
echo "3. Running app..."
echo "Watch for terminal output - should NOT see 'exit code 255'"
echo ""
flutter run -d macos
