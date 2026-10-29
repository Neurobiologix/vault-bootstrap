# Neurobiologix vault bootstrap

Public on purpose. These scripts set up a leader's computer for their Claude vault (second brain). They install standard software, generate SSH keys on the leader's own machine, enable remote support, and clone a repository the leader has been given a key for. They contain no secrets, no credentials and no company data; the only identity in here is William Olsen's SSH **public** key (`admin_authorized_keys`), which lets him support a machine that has opted in.

## Windows
Open PowerShell (not as administrator; the script elevates when it needs to) and run:
```powershell
irm https://raw.githubusercontent.com/Neurobiologix/vault-bootstrap/main/setup.ps1 | iex
```
Choose `all` the first time (installs, keys, remote support), open a **new** PowerShell window when it tells you to and run the line again for phase 2, then paste your two public keys to William. After he registers them, run the line again and choose `4`.

## macOS
Open Terminal and run:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Neurobiologix/vault-bootstrap/main/setup.sh)
```
Same phases.

Already have some of this installed (the Claude app, Obsidian, Git)? Phase 1 leaves existing installs alone: on Windows winget runs with `--no-upgrade`, on a Mac an app already in `/Applications` is skipped. Nothing is reinstalled or reset; your sign-ins and settings stay.

## What the phases do
| Phase | Windows | Mac |
|---|---|---|
| 1 install | winget: Git, Node LTS, Python 3.12, Obsidian, Claude | Homebrew: git, node, python@3.12, Obsidian, Claude |
| 2 keys | Two ed25519 keys in `~/.ssh` (`<Vault>` with write access on your vault repo, `NBX-shared` read-only on the shared repo), SSH config, GitHub host key; public keys to clipboard | Same |
| 3 remote | Installs the built-in OpenSSH Server but leaves it **off** and stages William's public key (used only on the office network or VPN, only when you open the door) | Stages William's public key; Remote Login stays **off** |
| 4 clone | Clones your vault over SSH, sets your git name and email, installs the backup hook, pulls the Company Shared folder, makes a test commit | Same |
| 5 fix | When William says "run the fix": refreshes the vault's helper scripts from this repo, reinstalls the hook, pulls the shared folder, commits. Nothing else is touched | Same |

Remote support is **consent per session** and mostly does not happen at all: most fixes ship as the `fix` phase above, which you run yourself and can read first. For a live problem, William uses a Teams screen share, or a one-time session-code tool (Windows Quick Assist, or Chrome Remote Desktop support mode on a Mac) where you read him a code and the session ends when either of you closes it. The SSH door from phase 3 is only for the rare case where he is on the same office network or VPN; you open it for that session and close it after:

- Windows: `irm https://raw.githubusercontent.com/Neurobiologix/vault-bootstrap/main/support.ps1 | iex` and answer `on`; later `off`.
- Mac: `bash <(curl -fsSL https://raw.githubusercontent.com/Neurobiologix/vault-bootstrap/main/support.sh) on`; later `off`.

There is no always-on network agent. If an earlier version of this bootstrap installed Tailscale on your machine, you can uninstall it.

Source of truth for these files: William's CFO vault, `projects/leadership-claude-rollout/vault-bootstrap/`, published with `tools/publish-bootstrap.sh`.
