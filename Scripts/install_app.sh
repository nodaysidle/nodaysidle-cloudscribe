#!/bin/bash
# install_app.sh — Package and install CloudScribe.app to /Applications
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

./Scripts/package_app.sh

SRC="$REPO_ROOT/.build/release/CloudScribe.app"
DEST="/Applications/CloudScribe.app"

echo "=== Installing CloudScribe to $DEST ==="
rm -rf "$DEST"
ditto "$SRC" "$DEST"
codesign --verify --deep --strict "$DEST"
echo "=== Install complete ==="
echo "Run: open -n $DEST"