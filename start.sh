#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"
PORT="${PORT:-3000}"
[[ "$PORT" =~ ^[0-9]+$ ]] || { echo 'PORT must be numeric.' >&2; exit 1; }

/usr/bin/time -p mkdir -p "$PROJECT_DIR/dist" "${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
/usr/bin/time -p bash "$PROJECT_DIR/scripts/build-preview.sh"
/usr/bin/time -p node -e 'const fs=require("node:fs"); const path=require("node:path"); const project=process.cwd(); const directory=path.join(project,"dist"); fs.writeFileSync(path.join(process.env.OPENCODE_WEB_DIR || "/home/runner/work/_temp/omgithub-web","deployment-output.json"), JSON.stringify({project,directory}, null, 2)+"\n")'
export PORT PROJECT_DIR
exec /usr/bin/time -p node "$PROJECT_DIR/scripts/serve-preview.mjs"
