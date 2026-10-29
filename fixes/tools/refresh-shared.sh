#!/bin/sh
# Refresh the Company Shared folder (shared/, a read-only clone of Neurobiologix/NBX-shared).
# Called by tools/backup-to-onedrive.sh before every backup; safe to run by hand:
#   sh tools/refresh-shared.sh
# Non-fatal by design. If shared/ is missing it clones it (needs the NBX-shared deploy key,
# see tools/shared-key.sh).
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO" || exit 0
if [ -d shared/.git ]; then
  if git -C shared pull -q --ff-only 2>/dev/null; then echo "shared: up to date ($(git -C shared log -1 --format=%cd --date=short))"
  else echo "shared: pull failed (network or deploy key; try: ssh -T git@github-shared)"; fi
elif git ls-remote -q git@github-shared:Neurobiologix/NBX-shared.git >/dev/null 2>&1; then
  git clone -q git@github-shared:Neurobiologix/NBX-shared.git shared && echo "shared: cloned"
else
  echo "shared: not present and github-shared not reachable (run tools/shared-key.sh and have William register the key)"
fi
exit 0
