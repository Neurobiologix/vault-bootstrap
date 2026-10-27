#!/bin/bash
# Neurobiologix vault bootstrap for macOS (public repo Neurobiologix/vault-bootstrap; contains no secrets).
# A leader runs ONE line in Terminal:
#   bash <(curl -fsSL https://raw.githubusercontent.com/Neurobiologix/vault-bootstrap/main/setup.sh)
# Phases, each safe to re-run:
#   1 install   Homebrew (if missing), git, node, python@3.12, Obsidian, the Claude desktop app, Tailscale
#   2 keys      two SSH deploy keys + SSH config + GitHub host key; prints the public keys and copies them to the clipboard
#   3 remote    William's admin public key staged; Remote Login stays OFF (opened per support session with support.sh); Tailscale
#   4 clone     clones the vault William seeded, sets git name/email, installs hooks, pulls shared/, test commit
# Wiki: projects/leadership-claude-rollout/11-mac-notes.md.
set -e
REPO="https://raw.githubusercontent.com/Neurobiologix/vault-bootstrap/main"
say() { printf '\n\033[36m== %s\033[0m\n' "$1"; }
echo "Neurobiologix vault bootstrap (macOS). Phases: 1 install, 2 keys, 3 remote, 4 clone."
read -r -p "Which phase? (1/2/3/4, or 'all' for 1 then 2 then 3): " PHASE; PHASE="${PHASE:-all}"
runs() { [ "$PHASE" = "$1" ] || { [ "$PHASE" = "all" ] && [ "$1" != "4" ]; }; }

if runs 1; then
  say "Phase 1: Homebrew and software"
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  brew install git node python@3.12
  # Casks: skip anything already in /Applications (installed by hand or earlier); brew would otherwise stop with
  # "already an App at /Applications/...". Existing installs, sign-ins and settings are left untouched.
  cask_if_missing() { if [ -d "/Applications/$2.app" ]; then echo "$2 already installed, leaving it alone"; else brew install --cask "$1"; fi; }
  cask_if_missing obsidian Obsidian
  cask_if_missing claude Claude
  cask_if_missing tailscale Tailscale
  echo "Installed. If 'git' is not found afterwards, close Terminal and open a new one."
fi

if runs 2; then
  say "Phase 2: SSH keys"
  read -r -p "Vault name William gave you (e.g. ClaudeCPO): " VAULT
  [[ "$VAULT" =~ ^Claude[A-Za-z]+$ ]] || { echo "vault name should look like ClaudeCPO"; exit 1; }
  mkdir -p ~/.ssh && chmod 700 ~/.ssh
  HN="$(scutil --get ComputerName 2>/dev/null || hostname)"
  [ -f ~/.ssh/"$VAULT" ] || ssh-keygen -q -t ed25519 -N "" -C "$VAULT deploy key $HN" -f ~/.ssh/"$VAULT"
  [ -f ~/.ssh/NBX-shared ] || ssh-keygen -q -t ed25519 -N "" -C "NBX-shared read key $HN" -f ~/.ssh/NBX-shared
  grep -q "IdentityFile ~/.ssh/$VAULT" ~/.ssh/config 2>/dev/null || printf '\nHost github.com\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/%s\n  IdentitiesOnly yes\n' "$VAULT" >> ~/.ssh/config
  grep -q "^Host github-shared" ~/.ssh/config 2>/dev/null || printf '\nHost github-shared\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/NBX-shared\n  IdentitiesOnly yes\n' >> ~/.ssh/config
  grep -q "^github.com" ~/.ssh/known_hosts 2>/dev/null || ssh-keyscan -t ed25519 github.com 2>/dev/null >> ~/.ssh/known_hosts
  MSG="Keys from $HN for $VAULT

VAULT KEY (write access on $VAULT):
$(cat ~/.ssh/"$VAULT".pub)

SHARED KEY (read-only on NBX-shared):
$(cat ~/.ssh/NBX-shared.pub)
"
  printf '%s' "$MSG" | pbcopy
  echo "$MSG"
  echo "Both public keys are on your clipboard: paste them into Teams to William. Public keys are safe to share. He registers them, then you run phase 4."
fi

if runs 3; then
  say "Phase 3: remote support, consent per session (key staged; Remote Login stays OFF; Tailscale)"
  KEY="$(curl -fsSL "$REPO/admin_authorized_keys" | tr -d '\r')"
  [[ "$KEY" == ssh-ed25519* ]] || { echo "could not fetch William's admin public key"; exit 1; }
  mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
  grep -qF "$KEY" ~/.ssh/authorized_keys || echo "$KEY" >> ~/.ssh/authorized_keys
  echo "William's key is staged. Remote Login stays OFF until you open it for a support session:"
  echo "  System Settings -> General -> Sharing -> Remote Login (on for the session, off after), or:"
  echo "  bash <(curl -fsSL $REPO/support.sh) on      /      ... off"
  echo "Now open Tailscale (Applications) and sign in with your company Microsoft account; leave it running. Tell William the machine name shown in Tailscale."
  open -a Tailscale 2>/dev/null || true
fi

if runs 4; then
  say "Phase 4: clone the vault"
  read -r -p "Vault name (e.g. ClaudeCPO): " VAULT
  read -r -p "Your full name (for git commits): " NAME
  read -r -p "Your @neurobiologix.com email: " EMAIL
  DEST="$HOME/$VAULT"
  [ -d "$DEST/.git" ] || git clone "git@github.com:Neurobiologix/$VAULT.git" "$DEST"
  cd "$DEST"
  git config user.name "$NAME"; git config user.email "$EMAIL"
  sh tools/install-hooks.sh
  sh tools/refresh-shared.sh
  git commit --allow-empty -m "Setup test: hook, push and OneDrive backup"
  echo
  echo "Done. Expect 'backup: pushed to GitHub' above. Next: Obsidian -> Open folder as vault -> $DEST; then the Claude desktop app -> Code tab -> this folder."
fi
