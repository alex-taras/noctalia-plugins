#!/bin/bash

SONARR_URL="$1"
API_KEY="$2"
TODAY=$(date -u +"%Y-%m-%dT00:00:00Z")
TODAY_END=$(date -u +"%Y-%m-%dT23:59:59Z")
TOMORROW=$(date -u -d "tomorrow" +"%Y-%m-%dT00:00:00Z")
TOMORROW_END=$(date -u -d "tomorrow" +"%Y-%m-%dT23:59:59Z")

today_response=$(curl -s -X GET "${SONARR_URL}/api/v3/calendar?start=${TODAY}&end=${TODAY_END}&includeSeries=true" -H "X-Api-Key: ${API_KEY}")
tomorrow_response=$(curl -s -X GET "${SONARR_URL}/api/v3/calendar?start=${TOMORROW}&end=${TOMORROW_END}&includeSeries=true" -H "X-Api-Key: ${API_KEY}")

process_episodes() {
    local response="$1"
    local output=""
    local count=0

    if [ -n "$response" ] && [ "$response" != "[]" ]; then
        while IFS= read -r episode; do
            series=$(printf '%s' "$episode" | jq -r '.series.title')
            season=$(printf '%s' "$episode" | jq -r '.seasonNumber')
            ep=$(printf '%s' "$episode" | jq -r '.episodeNumber')
            hasFile=$(printf '%s' "$episode" | jq -r '.hasFile')

            if [ "$hasFile" = "true" ]; then
                status="✅"
            else
                monitored=$(printf '%s' "$episode" | jq -r '.monitored')
                [ "$monitored" = "true" ] && status="⏬" || status="❌"
            fi

            [ $count -gt 0 ] && output+="\n"
            output+="${status}  ${series} - S${season}E${ep}"
            ((count++))
        done < <(printf '%s' "$response" | jq -c '.[]')
        output+="\n"
    fi

    [ -z "$output" ] && output="No shows scheduled\n"
    printf '%s' "$output"
}

today_count=$(printf '%s' "$today_response" | jq '. | length')
today_list=$(process_episodes "$today_response")
tomorrow_list=$(process_episodes "$tomorrow_response")

printf '{"count":%s,"today":"%s","tomorrow":"%s"}' \
    "$today_count" \
    "$(printf '%b' "$today_list" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')" \
    "$(printf '%b' "$tomorrow_list" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')"
