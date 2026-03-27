#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT_DIR"
cargo test --workspace

for flutter_dir in \
  "platform/flutter_bridge" \
  "packages/goox_editor_sdk" \
  "packages/goox_ui_shared" \
  "apps/goox_desktop" \
  "examples/simple_editor"
do
  echo "==> flutter analyze + test: $flutter_dir"
  (
    cd "$ROOT_DIR/$flutter_dir"
    flutter analyze
    flutter test
  )
done
