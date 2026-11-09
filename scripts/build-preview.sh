#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="$PROJECT_DIR/scripts/preview"
OUTPUT_DIR="$PROJECT_DIR/dist"

/usr/bin/time -p test -f "$SOURCE_DIR/index.html"
/usr/bin/time -p test -f "$SOURCE_DIR/styles.css"
/usr/bin/time -p test -f "$SOURCE_DIR/app.js"
/usr/bin/time -p mkdir -p "$OUTPUT_DIR"
/usr/bin/time -p cp "$SOURCE_DIR/index.html" "$SOURCE_DIR/styles.css" "$SOURCE_DIR/app.js" "$OUTPUT_DIR/"
/usr/bin/time -p find "$OUTPUT_DIR" -maxdepth 1 -type f -print
