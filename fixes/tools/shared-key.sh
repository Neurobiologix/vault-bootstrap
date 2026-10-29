#!/bin/sh
# Create this machine's READ-ONLY deploy key for the Company Shared repo (Neurobiologix/NBX-shared)
# and the SSH alias "github-shared" that uses it. GitHub ties a deploy key to one repository, so the
# vault's own key cannot open NBX-shared; this second key can open nothing else.
# Run from the vault folder in Git Bash:  sh tools/shared-key.sh
# Then William registers the printed public key on NBX-shared -> Settings -> Deploy keys
# WITHOUT "Allow write access", and you run:  sh tools/refresh-shared.sh
SSHDIR="$HOME/.ssh"; KEY="$SSHDIR/NBX-shared"
mkdir -p "$SSHDIR"
[ -f "$KEY" ] || ssh-keygen -q -t ed25519 -N "" -C "NBX-shared read key $(hostname)" -f "$KEY"
if ! grep -q "^Host github-shared" "$SSHDIR/config" 2>/dev/null; then
  printf '\nHost github-shared\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/NBX-shared\n  IdentitiesOnly yes\n' >> "$SSHDIR/config"
  echo "added github-shared alias to $SSHDIR/config"
fi
grep -q "^github.com" "$SSHDIR/known_hosts" 2>/dev/null || ssh-keyscan -t ed25519 github.com 2>/dev/null >> "$SSHDIR/known_hosts"
echo; echo "Public key for William to register on Neurobiologix/NBX-shared (read-only):"; echo
cat "$KEY.pub"
echo; echo "Test after registration:  ssh -T git@github-shared   (expect: Hi Neurobiologix/NBX-shared! ...)"
