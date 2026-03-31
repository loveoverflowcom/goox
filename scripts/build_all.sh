#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXTENSIONS_DEST="$HOME/Library/Application Support/dev.goox.goox/extensions"

cd "$ROOT_DIR"

# ── Build WASM plugins (wasm32-wasip1) ────────────────────────────────────────
echo "==> Building WASM plugins for wasm32-wasip1"

for plugin in image-viewer pdf-viewer; do
  echo "  Building $plugin..."
  cargo build \
    --manifest-path "$ROOT_DIR/dummy_extensions/$plugin/Cargo.toml" \
    --target wasm32-wasip1 \
    --release

  # Determine output filename (Cargo uses underscores in output)
  wasm_name="${plugin//-/_}.wasm"
  src="$ROOT_DIR/dummy_extensions/$plugin/target/wasm32-wasip1/release/$wasm_name"
  dst="$ROOT_DIR/dummy_extensions/$plugin/plugin.wasm"
  cp "$src" "$dst"
  echo "  Copied $wasm_name → $dst"

  # Deploy to app support directory if it exists
  if [ -d "$EXTENSIONS_DEST/$plugin" ]; then
    cp "$dst" "$EXTENSIONS_DEST/$plugin/plugin.wasm"
    echo "  Deployed → $EXTENSIONS_DEST/$plugin/plugin.wasm"
  fi
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
