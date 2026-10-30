#!/bin/bash

CREDS="$HOME/.claude/.credentials.json"
CACHE="/tmp/claude-usage.json"
LAST_REQUEST="/tmp/claude-usage.last"
ICON=""

# Don't query API more often than every 60 seconds
if [ -f "$LAST_REQUEST" ]; then
    LAST=$(cat "$LAST_REQUEST")
    NOW=$(date +%s)

    if [ $((NOW - LAST)) -lt 60 ]; then
        if [ -r "$CACHE" ]; then
            cat "$CACHE"
            exit 0
        fi
    fi
fi

echo "$(date +%s)" > "$LAST_REQUEST"

fail() {
    if [ -r "$CACHE" ]; then
        jq -c --arg icon "$ICON" '
            .text = ($icon + " " + (.session | tostring) + "%")
            | .class = "stale"
            | .tooltip = (.tooltip + "\n\n⚠ API temporarily unavailable")
        ' "$CACHE"
    else
        printf '{"text":"%s ?","class":"error","tooltip":"%s"}\n' "$ICON" "$1"
    fi
    exit 0
}

[ -r "$CREDS" ] || fail "Claude: credentials not found"

TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDS")
[ -n "$TOKEN" ] || fail "Claude: no access token"

RESP=$(curl -sS \
    --connect-timeout 3 \
    --max-time 10 \
    -w '\n%{http_code}' \
    -H "Authorization: Bearer $TOKEN" \
    -H "anthropic-beta: oauth-2025-04-20" \
    https://api.anthropic.com/api/oauth/usage 2>/dev/null)

CODE=${RESP##*$'\n'}
BODY=${RESP%$'\n'*}

[ "$CODE" = "200" ] || fail "Claude: HTTP $CODE"

RESULT=$(jq -c --arg icon "$ICON" '
    def fmt:
        if . == null then "-"
        else
            (sub("\\.[0-9]+"; "")
            | sub("\\+00:00$"; "Z")
            | fromdate
            | strflocaltime("%a %H:%M"))
        end;

    (.five_hour.utilization // 0 | floor) as $s
    | (.seven_day.utilization // 0 | floor) as $w

    | {
        session: $s,
        text: "\($icon) \($s)%",
        class:
            (if $s >= 90 then "critical"
             elif $s >= 70 then "warning"
             else "normal"
             end),
        tooltip:
            "Session (5h): \($s)%  resets \(.five_hour.resets_at | fmt)\n" +
            "Weekly (7d): \($w)%  resets \(.seven_day.resets_at | fmt)"
    }
' <<<"$BODY" 2>/dev/null)

[ -n "$RESULT" ] || fail "Claude: invalid response"

echo "$RESULT" > "$CACHE"
echo "$RESULT"
