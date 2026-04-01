#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXTENSIONS_DEST="$HOME/Library/Application Support/dev.goox.goox/extensions"

cd "$ROOT_DIR"

# ── Sync renderer extensions into the app support directory ──────────────────
echo "==> Syncing renderer extensions"

for plugin in image-viewer pdf-viewer; do
  echo "  Syncing $plugin..."
  src="$ROOT_DIR/dummy_extensions/$plugin"
  dst="$EXTENSIONS_DEST/$plugin"
  mkdir -p "$dst"
  cp -R "$src"/. "$dst"/
  echo "  Deployed → $dst"
done

# ── Rust tests ────────────────────────────────────────────────────────────────
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
