#!/bin/sh
# One-time per machine: install the post-commit hook and create the OneDrive backup folder.
# Run from the vault folder:  sh tools/install-hooks.sh
REPO="$(cd "$(dirname "$0")/.." && pwd)"
NAME="$(basename "$REPO")"
cd "$REPO" || exit 1
HOOK=".git/hooks/post-commit"
cat > "$HOOK" <<HK
#!/bin/sh
# Refresh the OneDrive cold backup and push to GitHub after every commit.
# See tools/backup-to-onedrive.sh; non-fatal if OneDrive is missing.
REPO="\$(git rev-parse --show-toplevel)"
sh "\$REPO/tools/backup-to-onedrive.sh"
HK
chmod +x "$HOOK" tools/*.sh
echo "installed $HOOK"
# OneDrive folder: Windows "OneDrive - NBX Wellness", Mac "~/Library/CloudStorage/OneDrive-NBXWellness".
ODROOT="$HOME/OneDrive - NBX Wellness"; [ -d "$ODROOT" ] || { [ -d "$HOME/Library/CloudStorage/OneDrive-NBXWellness" ] && ODROOT="$HOME/Library/CloudStorage/OneDrive-NBXWellness"; }
DEST="${CLAUDE_VAULT_BACKUP_DIR:-$ODROOT/$NAME-backup}"
if [ -d "$ODROOT" ] || [ -n "$CLAUDE_VAULT_BACKUP_DIR" ]; then
  mkdir -p "$DEST" && echo "backup folder: $DEST"
else
  echo "WARNING: no OneDrive - NBX Wellness folder found (Windows: ~/OneDrive - NBX Wellness; Mac: ~/Library/CloudStorage/OneDrive-NBXWellness). Sign in to OneDrive, or set CLAUDE_VAULT_BACKUP_DIR and re-run."
fi
git config --get user.name >/dev/null || echo "NOTE: set your name:  git config user.name \"First Last\""
git config --get user.email >/dev/null || echo "NOTE: set your email: git config user.email \"name@neurobiologix.com\""
echo "Test it:  git commit --allow-empty -m \"Setup test\""
