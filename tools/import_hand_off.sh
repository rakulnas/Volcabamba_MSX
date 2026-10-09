#!/usr/bin/env bash
set -euo pipefail
REPO_URL="https://github.com/rakulnas/Volcabamba_MSX.git"
DIR="${1:-Volcabamba_MSX}"
git clone "$REPO_URL" "$DIR"
cp -av VOLCABAMBA_GITHUB_HANDOFF/archives "$DIR/"
cp -av VOLCABAMBA_GITHUB_HANDOFF/roms "$DIR/"
cp -av VOLCABAMBA_GITHUB_HANDOFF/MANIFEST.json "$DIR/"
cp -av VOLCABAMBA_GITHUB_HANDOFF/README.md "$DIR/README_HANDOFF.md"
cd "$DIR"
git add README_HANDOFF.md MANIFEST.json archives roms
git commit -m "Archive complete Volcabamba ROMs and reproducible source snapshots"
git push origin main
echo "Verify all files are present on GitHub, then unpack latest SOURCE into src/, res/, reference/, tools/ and build/"
