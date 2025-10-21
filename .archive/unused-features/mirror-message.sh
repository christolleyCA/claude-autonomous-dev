#!/bin/bash
# Quick script to mirror a message to Slack immediately
# Usage: ./mirror-message.sh "Your message" ["optional title"]

MESSAGE="$1"
TITLE="${2:-Claude Activity}"
# Load .env if available
[ -f "${BASH_SOURCE[0]%/*}/.env" ] && source "${BASH_SOURCE[0]%/*}/.env"
SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN:-}"
SLACK_CHANNEL="C09M9A33FFF"

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 \"message\" [\"optional title\"]"
    exit 1
fi

# Build formatted message
FORMATTED="🤖 *${TITLE}* [$(date '+%H:%M:%S')]

${MESSAGE}"

# Build payload
PAYLOAD=$(jq -n \
    --arg channel "$SLACK_CHANNEL" \
    --arg text "$FORMATTED" \
    '{
        channel: $channel,
        text: $text
    }')

# Post to Slack
curl -s -X POST "https://slack.com/api/chat.postMessage" \
    -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" > /dev/null

echo "✅ Message mirrored to Slack"
