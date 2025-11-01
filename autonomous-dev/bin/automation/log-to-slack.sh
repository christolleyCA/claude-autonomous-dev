#!/bin/bash
# Helper script to log activity to Slack mirror
# Usage: ./log-to-slack.sh "message to post"

MESSAGE="$1"
# Load .env if available
[ -f "${BASH_SOURCE[0]%/*}/.env" ] && source "${BASH_SOURCE[0]%/*}/.env"
SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN:-}"
SLACK_CHANNEL="C09M9A33FFF"

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 \"message to post\""
    exit 1
fi

# Build payload - NO THREADING, post as top-level message
PAYLOAD=$(jq -n \
    --arg channel "$SLACK_CHANNEL" \
    --arg text "$MESSAGE" \
    '{
        channel: $channel,
        text: $text
    }')

# Post to Slack
curl -s -X POST "https://slack.com/api/chat.postMessage" \
    -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" > /dev/null

echo "✅ Posted to Slack"
