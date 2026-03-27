#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/vendor"

if [[ ! -d "$VENDOR_DIR" ]]; then
  echo "No vendor directory found. Nothing to patch yet."
  exit 0
fi

echo "Vendor patch application is not implemented yet."
echo "Add idempotent patch steps here when vendor/ is introduced."
