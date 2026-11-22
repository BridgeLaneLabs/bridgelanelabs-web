# Review session on Windows: live edits + a shareable Cloudflare quick-tunnel link.
#   .\review.ps1          start (or refresh) and print the link (also copied to the clipboard)
#   .\review.ps1 link     print the current link again
#   .\review.ps1 stop     close the link; the normal local site keeps running
# Same as review.sh, for PowerShell. VS Code: Ctrl+Shift+P > Run Task > Review: ...
param([string]$Action = 'start')
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$files = @('-f', 'compose.yaml', '-f', 'compose.review.yaml')

function Get-ReviewLink {
  $logs = docker compose @files logs tunnel 2>&1 | Out-String
  $found = [regex]::Matches($logs, 'https://[a-z0-9-]+\.trycloudflare\.com')
  if ($found.Count) { $found[$found.Count - 1].Value }
}

if ($Action -eq 'stop') {
  docker compose -f compose.yaml up -d --remove-orphans
  'Review link closed. Local site still at http://localhost:8100'
  exit 0
}

if ($Action -eq 'start') {
  docker compose @files up -d --build
  if ($LASTEXITCODE -ne 0) { throw 'Could not start the review session.' }
  'Waiting for the link...'
}

for ($i = 0; $i -lt 30; $i++) {
  $url = Get-ReviewLink
  if ($url) {
    try { Set-Clipboard $url; $note = ' (copied)' } catch { $note = '' }
    ''
    "Review link: $url$note"
    'Anyone with this link can see the site. Edits in site/ show on refresh.'
    exit 0
  }
  if ($Action -ne 'start') { break }
  Start-Sleep 2
}
'No link found. Is a session running? Try: Review: start session'
exit 1
