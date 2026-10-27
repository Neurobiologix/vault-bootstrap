# Open or close the door for a support session on Windows (consent per session).
#   irm https://raw.githubusercontent.com/Neurobiologix/vault-bootstrap/main/support.ps1 | iex
# Asks "on" or "off". "on" starts the OpenSSH Server service (one admin prompt) so William can connect over Tailscale
# with his key; "off" stops it. Nothing else changes. The service is never set to start by itself.
$what = Read-Host "Support session: 'on' to let William in, 'off' to close, 'status' to check"
switch ($what) {
  "on"     { Start-Process powershell -Verb RunAs -Wait -ArgumentList "-NoProfile -Command Start-Service sshd"; Write-Host "Remote support ON: William can connect for this session. Run again and choose 'off' when done." -ForegroundColor Green }
  "off"    { Start-Process powershell -Verb RunAs -Wait -ArgumentList "-NoProfile -Command Stop-Service sshd"; Write-Host "Remote support OFF." -ForegroundColor Green }
  "status" { $s = Get-Service sshd -ErrorAction SilentlyContinue; if ($s) { "sshd is $($s.Status) (startup $($s.StartType))" } else { "OpenSSH Server not installed (run the bootstrap, phase 3)" } }
  default  { "nothing changed" }
}
