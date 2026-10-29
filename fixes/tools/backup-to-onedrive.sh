#!/bin/sh
# Post-commit backup: writes a git bundle (full history) plus a zip of gitignored files
# (secrets, caches) to the OneDrive backup folder, then pushes to GitHub.
# Called by .git/hooks/post-commit (installed by tools/install-hooks.sh); safe to run by hand.
# Together the bundle and the zip are a complete restore: clone the bundle, unzip the rest on top.
# Non-fatal by design: a missing OneDrive folder just skips the copy; a failed push is reported.
REPO="$(cd "$(dirname "$0")/.." && pwd)"
NAME="$(basename "$REPO")"
# Mac: git hooks run without the login shell PATH, so Homebrew tools are invisible unless added here;
# and Homebrew ships python3 (no "python"). Windows/Git Bash has both.
[ -d /opt/homebrew/bin ] && PATH="/opt/homebrew/bin:$PATH"
PY=python; command -v python >/dev/null 2>&1 || PY=python3
# OneDrive folder: Windows "OneDrive - NBX Wellness", Mac "~/Library/CloudStorage/OneDrive-NBXWellness".
ODROOT="$HOME/OneDrive - NBX Wellness"; [ -d "$ODROOT" ] || { [ -d "$HOME/Library/CloudStorage/OneDrive-NBXWellness" ] && ODROOT="$HOME/Library/CloudStorage/OneDrive-NBXWellness"; }
DEST="${CLAUDE_VAULT_BACKUP_DIR:-$ODROOT/$NAME-backup}"
cd "$REPO" || exit 0
sh tools/refresh-shared.sh
if [ -d "$DEST" ]; then
  git bundle create -q "$DEST/$NAME-latest.bundle.tmp" --all 2>/dev/null \
    && mv -f "$DEST/$NAME-latest.bundle.tmp" "$DEST/$NAME-latest.bundle"
  git ls-files -z --others --ignored --exclude-standard \
    | tr '\0' '\n' | grep -v node_modules | grep -v __pycache__ > "$DEST/.unversioned.txt"
  "$PY" - "$DEST" "$NAME" <<'PY'
import sys, os, zipfile
dest, name = sys.argv[1], sys.argv[2]
lst = os.path.join(dest, '.unversioned.txt'); tmp = os.path.join(dest, name + '-unversioned-latest.zip.tmp')
with zipfile.ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED) as z:
    for p in (l.strip() for l in open(lst, encoding='utf-8')):
        if p and os.path.isfile(p): z.write(p, p)
os.replace(tmp, os.path.join(dest, name + '-unversioned-latest.zip')); os.remove(lst)
PY
  echo "backup: bundle + unversioned zip refreshed in $DEST"
else
  echo "backup: $DEST not found, OneDrive copy skipped (run tools/install-hooks.sh or set CLAUDE_VAULT_BACKUP_DIR)"
fi
if git remote get-url origin >/dev/null 2>&1; then
  git push -q origin HEAD 2>&1 && echo "backup: pushed to GitHub" || echo "backup: PUSH FAILED - check network, or the deploy key (ssh -T git@github.com)"
fi
