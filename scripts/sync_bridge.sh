#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BRIDGE_OUTPUT_DIR="$ROOT_DIR/platform/flutter_bridge/lib/src/raw_bridge"
RUST_OUTPUT="$ROOT_DIR/core/engine/src/frb_generated.rs"

if ! command -v flutter_rust_bridge_codegen >/dev/null 2>&1; then
  echo "flutter_rust_bridge_codegen is not installed."
  echo "Install it first, then rerun this script."
  exit 1
fi

flutter_rust_bridge_codegen generate \
  --rust-input crate::api \
  --rust-root "$ROOT_DIR/core/engine" \
  --dart-output "$BRIDGE_OUTPUT_DIR" \
  --rust-output "$RUST_OUTPUT"

echo "Bridge sync completed."
