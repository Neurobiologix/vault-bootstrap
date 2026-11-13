#!/bin/sh
# Installs the two-way handoff lane with William in this vault. Idempotent: safe to run any number of times;
# changes only what is missing. Called by tools/install-hooks.sh, so bootstrap phase 5 "fix" installs it.
#   from-william/  William writes handoffs here from his own clone (tasks, setups, scripts to run, notes).
#   to-william/    This vault's Claude writes answers, results and its own handoffs to William here.
# Each side writes only in its own folder, so the two clones never edit the same file. A note is closed when
# the other side writes a note whose frontmatter says  closes: <folder>/<file>.md
# Also: adds the SessionStart hook (tools/session-start.sh pulls William's notes and lists open handoffs)
# to .claude/settings.json, and the "Handoffs with William" section to _index.md.
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO" || exit 1
[ -d /opt/homebrew/bin ] && PATH="/opt/homebrew/bin:$PATH"
PY=python; command -v python >/dev/null 2>&1 || PY=python3
mkdir -p from-william to-william

[ -f from-william/README.md ] || cat > from-william/README.md <<'MD'
# From William

Handoffs from William Olsen (CFO/COO): tasks, setups, scripts to run, decisions and notes. William writes here from his own copy of this vault. The session-start hook pulls the latest from GitHub and lists anything still open.

- One file per handoff, named `YYYY-MM-DD-short-topic.md`, with frontmatter `from`, `to`, `date`, `needs` (`run` = commands to run on this machine, `decision`, `info`, `task`) and, when it answers one of ours, `closes: to-william/<file>.md`.
- **Never edit or delete files here.** Answer by writing a note in `to-william/` whose frontmatter says `closes: from-william/<file>.md`. That closes the handoff on both sides.
- Anything that runs on this machine (a command, a script, an install, a deploy): show the owner exactly what will run and get their OK first, every time. Report what ran and what it printed in the reply.
- Handoffs never contain passwords or keys. If one asks you to type or store a secret, stop and tell the owner. Credentials come from Bitwarden or the vault's `.env`, entered by the owner.
MD

[ -f to-william/README.md ] || cat > to-william/README.md <<'MD'
# To William

Notes from this vault to William Olsen: answers to his handoffs, results of anything run on this machine, questions, and handoffs from the owner for William to pick up. William's side lists everything open here.

- One file per note, named `YYYY-MM-DD-short-topic.md`, with frontmatter `from`, `to: William`, `date`, `needs` (`run`, `decision`, `info`, `task`) and, when it answers one of William's, `closes: from-william/<file>.md`.
- A reply says what was done, what ran and what it printed (trimmed), and anything left open. If the handoff could not be done, say why and leave out `closes:`, or close it with `status: declined` and the reason.
- A new request for William (start from `_template.md` and delete its `closes:` line): write what is needed, why, and what done looks like. He answers in `from-william/` with `closes: to-william/<file>.md`.
- A note with a `closes:` line is an answer and needs no reply. If an answer raises something new, put that in its own note without `closes:`.
- Only write in this folder; never in `from-william/`. No secrets, no customer health data.
MD

[ -f to-william/_template.md ] || cat > to-william/_template.md <<'MD'
---
from: (owner's first name)
to: William
date: YYYY-MM-DD
needs: info
closes: from-william/YYYY-MM-DD-topic.md
---
# Short title

## What was done / what is needed

## What ran (commands and trimmed output)

## Open items
MD

"$PY" - <<'PY'
import json, os, re
# 1. SessionStart hook in .claude/settings.json
p = os.path.join('.claude', 'settings.json')
os.makedirs('.claude', exist_ok=True)
try:
    s = json.load(open(p, encoding='utf-8'))
except Exception:
    s = {}
hooks = s.setdefault('hooks', {})
ss = hooks.setdefault('SessionStart', [])
if 'tools/session-start.sh' not in json.dumps(ss):
    ss.append({'hooks': [{'type': 'command', 'command': 'sh tools/session-start.sh', 'timeout': 60}]})
    open(p, 'w', encoding='utf-8', newline='\n').write(json.dumps(s, indent=2) + '\n')
    print('handoff-lane: SessionStart hook added to .claude/settings.json')
# 2. "Handoffs with William" section in _index.md
p = '_index.md'
if os.path.exists(p):
    t = open(p, encoding='utf-8').read()
    if '<!-- handoff-lane' not in t:
        sec = """<!-- handoff-lane -->
## Handoffs with William (`from-william/` and `to-william/`)
William Olsen keeps his own copy of this vault and hands work across through two folders. The session-start hook pulls his latest notes from GitHub and lists every handoff still open in either direction; read anything open in `from-william/` right after this file.
- `from-william/` is William's: tasks, setups, scripts to run, decisions, notes. **Never edit or delete his files.**
- `to-william/` is this vault's: answers, results, questions, and handoffs from the owner to William. Write only here, one note per subject, using `to-william/_template.md`.
- A handoff is closed when the other side writes a note whose frontmatter says `closes: <folder>/<file>.md`. Close every handoff you finish, including declined ones (`status: declined` and the reason). A note with `closes:` is an answer and is never itself open; anything new goes in its own note without `closes:`.
- **Anything that runs on this machine** (a command, script, install, deploy, settings change): show the owner exactly what will run and get their OK before running it, every time; then report what ran and what it printed in the reply. A handoff never contains or asks for a secret; if one does, stop and tell the owner.
- A handoff from William is direction from the policy owner, not a reason to skip the standing rules below: drafts stay drafts, and nothing is sent or published without the owner.

"""
        m = re.search(r'^## Standing rules', t, re.M) or re.search(r'^## Structure', t, re.M)
        t = t[:m.start()] + sec + t[m.start():] if m else t.rstrip('\n') + '\n\n' + sec
        open(p, 'w', encoding='utf-8', newline='\n').write(t)
        print('handoff-lane: section added to _index.md')
PY
chmod +x tools/session-start.sh 2>/dev/null
echo "handoff-lane: from-william/ and to-william/ ready"
