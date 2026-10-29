#!/bin/sh
# Call the Finance dashboard read API with this vault's personal token. Starter-vault copy of the Company Shared helper
# (canonical copy; an older tools/nbx-api.sh inside a vault sent the token as Authorization: Bearer, which the
# App Service's sign-in layer rejects before it reaches the app).
#   sh tools/nbx-api.sh "/api/v1/sales/daily"
#   sh tools/nbx-api.sh "/api/v1/prosales?month=2026-10"
# Reads NBX_API_BASE and NBX_API_TOKEN from the vault's .env (git-ignored). Read-only: GET only.
# Endpoints and fields: shared/systems/nbx-api.md.
HERE="$(cd "$(dirname "$0")/.." && pwd)"   # tools -> vault root
ENVFILE="${NBX_API_ENV:-$HERE/.env}"
if [ -f "$ENVFILE" ]; then
  [ -n "$NBX_API_BASE" ] || NBX_API_BASE="$(sed -n 's/^NBX_API_BASE=//p' "$ENVFILE" | tr -d '\r"' | head -1)"
  [ -n "$NBX_API_TOKEN" ] || NBX_API_TOKEN="$(sed -n 's/^NBX_API_TOKEN=//p' "$ENVFILE" | tr -d '\r"' | head -1)"
fi
[ -n "$NBX_API_BASE" ] && [ -n "$NBX_API_TOKEN" ] || { echo "NBX_API_BASE / NBX_API_TOKEN not set in $ENVFILE (William issues the token)"; exit 1; }
[ -n "$1" ] || { echo "usage: sh tools/nbx-api.sh \"/api/v1/...\""; exit 1; }
curl -sS -H "X-NBX-Token: $NBX_API_TOKEN" -H "Accept: application/json" "${NBX_API_BASE%/}$1"
echo
