#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"
: "${CAPTURE_URL:?Set CAPTURE_URL to the preview URL.}"
: "${CAPTURE_DIR:?Set CAPTURE_DIR to the screenshot output directory.}"
export RUNTIME_DIR="${RUNTIME_DIR:-/home/runner/work/_temp/omgithub-runtime}"
/usr/bin/time -p test -f "$PROJECT_DIR/scripts/capture-preview.mjs"
/usr/bin/time -p test -f "$RUNTIME_DIR/scripts/capture-start.mjs"
/usr/bin/time -p node "$PROJECT_DIR/scripts/capture-preview.mjs"
