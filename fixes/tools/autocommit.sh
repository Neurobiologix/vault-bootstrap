#!/bin/sh
# Claude Code Stop hook: after each Claude turn, commit any change in the vault and push.
# Together with the post-commit hook (OneDrive bundle + push) this is the near-real-time
# backup the company AI policy describes. Quiet and non-fatal: a failure never blocks Claude.
# Supervised vaults (a .vault-profile file containing "supervised", e.g. ClaudeIT) also export
# this vault's Claude Code transcripts into transcripts/ first, so the session itself is saved
# with the work (readable copies committed, raw JSONL in the OneDrive zip only).
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO" || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
if [ "$(cat .vault-profile 2>/dev/null | tr -d '[:space:]')" = "supervised" ]; then
  [ -d /opt/homebrew/bin ] && PATH="/opt/homebrew/bin:$PATH"
  PY=python; command -v python >/dev/null 2>&1 || PY=python3
  "$PY" tools/export-transcripts.py transcripts >/dev/null 2>&1 || true
fi
[ -n "$(git status --porcelain)" ] || exit 0
git add -A >/dev/null 2>&1
git -c core.hooksPath=.git/hooks commit -q -m "Auto-save $(date '+%Y-%m-%d %H:%M') (Claude session)" >/dev/null 2>&1 || exit 0
exit 0
