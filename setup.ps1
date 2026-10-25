# Neurobiologix vault bootstrap for Windows (public repo Neurobiologix/vault-bootstrap; contains no secrets).
# A leader runs ONE line in PowerShell:   irm https://raw.githubusercontent.com/Neurobiologix/vault-bootstrap/main/setup.ps1 | iex
# It walks through four phases, each safe to re-run:
#   1 install   Git, Node LTS, Python 3.12, Obsidian, the Claude desktop app, Tailscale (winget; elevates once; anything
#               already installed is left exactly as it is: --no-upgrade, no reinstall, sign-ins and settings untouched)
#   2 keys      two SSH deploy keys (vault write key, NBX-shared read key), SSH config, GitHub host key; shows the
#               public keys and copies them to the clipboard for a Teams message to William
#   3 remote    OpenSSH Server on this PC + William's admin public key, so he can support this machine over SSH
#               (Tailscale joins the company network; the leader signs in to Tailscale when it opens)
#   4 clone     clones the vault William seeded, sets git name/email, installs hooks, pulls shared/, test commit
# Nothing here reads company data. Wiki: projects/leadership-claude-rollout/08-setup-sheet.md.

$ErrorActionPreference = "Stop"
$Repo = "https://raw.githubusercontent.com/Neurobiologix/vault-bootstrap/main"
$GitBin = "C:\Program Files\Git\usr\bin"
function Say($m) { Write-Host "`n== $m" -ForegroundColor Cyan }
function IsAdmin { ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
function Elevated($script) {
  # Run a block as administrator in a new window and wait for it.
  $tmp = Join-Path $env:TEMP ("nbx-elev-" + [guid]::NewGuid() + ".ps1")
  Set-Content -Path $tmp -Value $script -Encoding UTF8
  Start-Process powershell -Verb RunAs -Wait -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tmp`""
  Remove-Item $tmp -ErrorAction SilentlyContinue
}

Write-Host "Neurobiologix vault bootstrap (Windows). Phases: 1 install, 2 keys, 3 remote, 4 clone." -ForegroundColor Green
$phase = Read-Host "Which phase? (1/2/3/4, or 'all' for 1 then 2 then 3)"
if (-not $phase) { $phase = "all" }
$run = if ($phase -eq "all") { @("1","2","3") } else { @($phase) }

if ($run -contains "1") {
  Say "Phase 1: installing software with winget (an admin prompt will appear once)"
  $pk = @("Git.Git", "OpenJS.NodeJS.LTS", "Python.Python.3.12", "Obsidian.Obsidian", "Anthropic.Claude", "Tailscale.Tailscale")
  $cmd = ($pk | ForEach-Object { "winget install --id $_ --exact --silent --no-upgrade --accept-package-agreements --accept-source-agreements; " }) -join ""
  Elevated "$cmd Write-Host 'installs finished; this window closes in 5 s'; Start-Sleep 5"
  Write-Host "Installed. CLOSE this PowerShell window and open a NEW one before phase 2 (PATH refresh), then run the same one-line command again and choose 2."
  if ($run.Count -gt 1) { Write-Host "Stopping here on purpose: the new window is required." -ForegroundColor Yellow; return }
}

if ($run -contains "2") {
  Say "Phase 2: SSH keys"
  if (-not (Test-Path "$GitBin\ssh-keygen.exe")) { throw "Git for Windows is not installed (or this window predates it). Run phase 1, open a new window." }
  $vault = Read-Host "Vault name William gave you (e.g. ClaudeSales, ClaudeCEO, ClaudeCPO)"
  if ($vault -notmatch '^Claude[A-Za-z]+$') { throw "vault name should look like ClaudeSales" }
  $sshDir = Join-Path $HOME ".ssh"; New-Item -ItemType Directory -Force $sshDir | Out-Null
  $host_ = $env:COMPUTERNAME
  if (-not (Test-Path "$sshDir\$vault")) { & "$GitBin\ssh-keygen.exe" -q -t ed25519 -N '""' -C "$vault deploy key $host_" -f "$sshDir\$vault" }
  if (-not (Test-Path "$sshDir\NBX-shared")) { & "$GitBin\ssh-keygen.exe" -q -t ed25519 -N '""' -C "NBX-shared read key $host_" -f "$sshDir\NBX-shared" }
  $cfg = "$sshDir\config"
  $existing = if (Test-Path $cfg) { Get-Content $cfg -Raw } else { "" }
  if ($existing -notmatch "IdentityFile ~/.ssh/$vault") { Add-Content -Encoding ascii $cfg "`nHost github.com`n  HostName github.com`n  User git`n  IdentityFile ~/.ssh/$vault`n  IdentitiesOnly yes`n" }
  if ($existing -notmatch "Host github-shared") { Add-Content -Encoding ascii $cfg "`nHost github-shared`n  HostName github.com`n  User git`n  IdentityFile ~/.ssh/NBX-shared`n  IdentitiesOnly yes`n" }
  $kh = "$sshDir\known_hosts"
  if (-not (Test-Path $kh) -or -not (Select-String -Path $kh -Pattern "^github.com" -Quiet)) { & "$GitBin\ssh-keyscan.exe" -t ed25519 github.com 2>$null | Add-Content -Encoding ascii $kh }
  $pub1 = Get-Content "$sshDir\$vault.pub"; $pub2 = Get-Content "$sshDir\NBX-shared.pub"
  $msg = "Keys from $host_ for $vault`n`nVAULT KEY (write access on $vault):`n$pub1`n`nSHARED KEY (read-only on NBX-shared):`n$pub2`n"
  Set-Clipboard -Value $msg
  Write-Host $msg
  Write-Host "Both public keys are on your clipboard: paste them into Teams to William. Public keys are safe to share. He registers them, then you run phase 4." -ForegroundColor Green
}

if ($run -contains "3") {
  Say "Phase 3: remote support (OpenSSH Server + Tailscale)"
  $adminKey = (Invoke-RestMethod "$Repo/admin_authorized_keys").Trim()
  if ($adminKey -notmatch '^ssh-ed25519 ') { throw "could not fetch William's admin public key from the repo" }
  $user = $env:USERNAME
  $script = @"
`$ErrorActionPreference = 'Stop'
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null
Set-Service sshd -StartupType Automatic; Start-Service sshd
New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -PropertyType String -Force | Out-Null
if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)) { New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null }
`$k = '$adminKey'
`$adminFile = 'C:\ProgramData\ssh\administrators_authorized_keys'
if (-not (Test-Path `$adminFile) -or -not (Select-String -Path `$adminFile -SimpleMatch -Pattern `$k -Quiet)) { Add-Content -Encoding ascii `$adminFile `$k }
icacls `$adminFile /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F' | Out-Null
`$userDir = 'C:\Users\$user\.ssh'; New-Item -ItemType Directory -Force `$userDir | Out-Null
`$userFile = Join-Path `$userDir 'authorized_keys'
if (-not (Test-Path `$userFile) -or -not (Select-String -Path `$userFile -SimpleMatch -Pattern `$k -Quiet)) { Add-Content -Encoding ascii `$userFile `$k }
Restart-Service sshd
Write-Host 'OpenSSH Server is on; William''s key installed. Closing in 5 s'; Start-Sleep 5
"@
  Elevated $script
  Write-Host "SSH server enabled for user $user on $env:COMPUTERNAME." -ForegroundColor Green
  Write-Host "Now open Tailscale from the Start menu and sign in with your company Microsoft account when it asks; leave it running. Tell William the machine name shown in Tailscale."
  Start-Process "tailscale" -ErrorAction SilentlyContinue
}

if ($run -contains "4") {
  Say "Phase 4: clone the vault"
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "git not on PATH: open a new PowerShell window" }
  $vault = Read-Host "Vault name (e.g. ClaudeSales)"
  $name = Read-Host "Your full name (for git commits)"
  $email = Read-Host "Your @neurobiologix.com email"
  $dest = Join-Path $HOME $vault
  if (-not (Test-Path $dest)) { git clone "git@github.com:Neurobiologix/$vault.git" $dest }
  Set-Location $dest
  git config user.name "$name"; git config user.email "$email"
  & "$GitBin\sh.exe" tools/install-hooks.sh
  & "$GitBin\sh.exe" tools/refresh-shared.sh
  git commit --allow-empty -m "Setup test: hook, push and OneDrive backup"
  Write-Host "`nDone. Expect 'backup: pushed to GitHub' above. Next: open Obsidian -> Open folder as vault -> $dest; then the Claude desktop app -> Code tab -> this folder." -ForegroundColor Green
}
