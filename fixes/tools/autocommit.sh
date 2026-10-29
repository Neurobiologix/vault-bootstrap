#!/bin/sh
# Claude Code Stop hook: after each Claude turn, commit any change in the vault and push.
# Together with the post-commit hook (OneDrive bundle + push) this is the near-real-time
# backup the company AI policy describes. Quiet and non-fatal: a failure never blocks Claude.
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO" || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
[ -n "$(git status --porcelain)" ] || exit 0
git add -A >/dev/null 2>&1
git -c core.hooksPath=.git/hooks commit -q -m "Auto-save $(date '+%Y-%m-%d %H:%M') (Claude session)" >/dev/null 2>&1 || exit 0
exit 0
