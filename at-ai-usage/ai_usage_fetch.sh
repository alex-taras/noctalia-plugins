#!/bin/bash
# Fetches Claude subscription rate-limit usage via the same undocumented
# endpoint Claude Code's own /status uses. Reads the OAuth access token
# straight from Claude Code's credentials file - no separate auth needed,
# but it also means: unofficial, no SLA, breaks if Anthropic changes it.

CREDS_PATH="${1/#\~/$HOME}"

if [ ! -f "$CREDS_PATH" ]; then
    echo '{"error":"credentials_not_found"}'
    exit 0
fi

TOKEN=$(grep -o '"accessToken"[[:space:]]*:[[:space:]]*"[^"]*"' "$CREDS_PATH" | sed -E 's/.*"([^"]+)"$/\1/')

if [ -z "$TOKEN" ]; then
    echo '{"error":"no_token"}'
    exit 0
fi

RESPONSE=$(curl -s --max-time 5 "https://api.anthropic.com/api/oauth/usage" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json")

if [ -z "$RESPONSE" ]; then
    echo '{"error":"no_response"}'
    exit 0
fi

echo "$RESPONSE"
