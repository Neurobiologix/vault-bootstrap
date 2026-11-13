#!/bin/sh
# Claude Code SessionStart hook for any vault with the handoff lane (a from-william/ folder; installed by
# tools/handoff-lane.sh, and always present in supervised vaults such as ClaudeIT).
# Brings in whatever William's clone pushed before Claude reads anything, then lists the handoffs still
# open in both directions. A note is closed when the other side's folder has a note saying
# "closes: <folder>/<file>.md". Non-fatal; a no-op in a vault without the lane.
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO" || exit 0
[ -d from-william ] || exit 0
if git remote get-url origin >/dev/null 2>&1; then
  BR="$(git rev-parse --abbrev-ref HEAD)"
  if VAULT_SYNCING=1 git pull -q --no-rebase --no-edit --autostash origin "$BR" >/dev/null 2>&1; then
    echo "vault: synced with GitHub ($(git log -1 --format='%h %an %cd' --date=format:'%Y-%m-%d %H:%M'))"
  else
    VAULT_SYNCING=1 git merge --abort >/dev/null 2>&1
    echo "vault: SYNC FAILED (network, deploy key, or a conflict with William's clone). Tell the owner; work can continue, the next save puts it on a conflict/ branch for William."
  fi
fi
# open <folder> <other folder>: notes in <folder> that are not answers (no closes:) and that no note in <other folder> closes
open_notes() {
  for f in "$1"/*.md; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in README.md|_template.md) continue;; esac
    grep -qs "^closes:" "$f" && continue   # an answer closes something; it is never itself open
    grep -qs "^closes:.*$f" "$2"/*.md && continue
    echo "  $f  ($(sed -n 's/^needs: *//p' "$f" | head -1))"
  done
}
OPEN_IN="$(open_notes from-william to-william)"
OPEN_OUT="$(open_notes to-william from-william)"
if [ -n "$OPEN_IN" ]; then
  echo "from-william/: OPEN handoffs from William. Read each before other work; get the owner's OK before running anything; answer in to-william/ with closes:"
  echo "$OPEN_IN"
else
  echo "from-william/: nothing open from William."
fi
[ -n "$OPEN_OUT" ] && { echo "to-william/: waiting on William:"; echo "$OPEN_OUT"; }
exit 0
