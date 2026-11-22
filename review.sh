#!/usr/bin/env bash
# Review session: live edits + a shareable Cloudflare quick-tunnel link.
#   ./review.sh          start (or refresh) and print the link
#   ./review.sh link     print the current link again
#   ./review.sh stop     close the link; the normal local site keeps running
# Windows twin: review.ps1. VS Code: Ctrl+Shift+P > Run Task > Review: ...
set -euo pipefail
cd "$(dirname "$0")"
DC="docker compose -f compose.yaml -f compose.review.yaml"
ACTION="${1:-start}"

if [ "$ACTION" = "stop" ]; then
  docker compose -f compose.yaml up -d --remove-orphans
  echo "Review link closed. Local site still at http://localhost:8100"
  exit 0
fi

if [ "$ACTION" = "start" ]; then
  git pull --ff-only 2>/dev/null || true
  $DC up -d --build
  echo "Waiting for the link..."
fi

for i in $(seq 1 30); do
  URL=$($DC logs tunnel 2>/dev/null | grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' | tail -1 || true)
  if [ -n "$URL" ]; then
    echo; echo "Review link: $URL"
    echo "Anyone with this link can see the site. Edits in site/ show on refresh."
    exit 0
  fi
  [ "$ACTION" = "start" ] || break
  sleep 2
done
echo "No link found. Is a session running? Try: ./review.sh"
exit 1
