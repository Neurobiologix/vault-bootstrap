#!/bin/sh
# Create (or replace) this machine's deploy key for this vault and print the public half
# for William to register on the repository (GitHub -> repo -> Settings -> Deploy keys ->
# Add deploy key -> tick "Allow write access"). Run from the vault folder:
#   sh tools/new-deploy-key.sh
# Leaders have no GitHub accounts; this key is the only thing that can push, and only to this repo.
REPO="$(cd "$(dirname "$0")/.." && pwd)"
NAME="$(basename "$REPO")"
SSHDIR="$HOME/.ssh"
KEY="$SSHDIR/$NAME"
mkdir -p "$SSHDIR"
if [ -f "$KEY" ]; then
  mv -f "$KEY" "$KEY.old" && mv -f "$KEY.pub" "$KEY.pub.old"
  echo "previous key moved to $KEY.old (delete it once the new key is registered and tested)"
fi
ssh-keygen -q -t ed25519 -N "" -C "$NAME deploy key $(hostname)" -f "$KEY"
if ! grep -q "IdentityFile ~/.ssh/$NAME" "$SSHDIR/config" 2>/dev/null; then
  printf '\nHost github.com\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/%s\n  IdentitiesOnly yes\n' "$NAME" >> "$SSHDIR/config"
  echo "added github.com entry to $SSHDIR/config"
fi
if ! grep -q "^github.com" "$SSHDIR/known_hosts" 2>/dev/null; then
  ssh-keyscan -t ed25519 github.com 2>/dev/null >> "$SSHDIR/known_hosts"
  echo "recorded GitHub's host key; verify with: ssh-keygen -lf ~/.ssh/known_hosts (compare to docs.github.com fingerprints)"
fi
echo
echo "Public key to register on github.com/Neurobiologix/$NAME (Settings -> Deploy keys, allow write access):"
echo
cat "$KEY.pub"
echo
echo "Then test:  ssh -T git@github.com   (expect: Hi Neurobiologix/$NAME! ...)"
