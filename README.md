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
| 1 install | winget: Git, Node LTS, Python 3.12, Obsidian, Claude, Tailscale | Homebrew: git, node, python@3.12, Obsidian, Claude, Tailscale |
| 2 keys | Two ed25519 keys in `~/.ssh` (`<Vault>` with write access on your vault repo, `NBX-shared` read-only on the shared repo), SSH config, GitHub host key; public keys to clipboard | Same |
| 3 remote | Installs the built-in OpenSSH Server but leaves it **off**, stages William's public key, opens Tailscale to sign in | Stages William's public key; Remote Login stays **off**; opens Tailscale |
| 4 clone | Clones your vault over SSH, sets your git name and email, installs the backup hook, pulls the Company Shared folder, makes a test commit | Same |

Remote support is **consent per session**, like letting a help-desk person in. Nothing is open by default. When you want William to fix or finish something, you open the door for that session and close it after:

- Windows: `irm https://raw.githubusercontent.com/Neurobiologix/vault-bootstrap/main/support.ps1 | iex` and answer `on`; later `off`.
- Mac: `bash <(curl -fsSL https://raw.githubusercontent.com/Neurobiologix/vault-bootstrap/main/support.sh) on`; later `off`. (Same as System Settings → General → Sharing → Remote Login.)

While the door is open, William, and only William, with the one key listed here, can open a terminal on your machine over the company's Tailscale network. Tailscale itself is just the private route between company machines; it carries nothing on its own and you can quit it any time.

Source of truth for these files: William's CFO vault, `projects/leadership-claude-rollout/vault-bootstrap/`, published with `tools/publish-bootstrap.sh`.
