#!/bin/bash
# Send message to Slack

send_to_slack() {
    local message="$1"
    local webhook_url="${SLACK_WEBHOOK_URL:-}"

    # If no webhook configured, just log it
    if [ -z "$webhook_url" ]; then
        echo "📤 Would send to Slack: $message"
        return 0
    fi

    # Send to Slack
    curl -s -X POST "$webhook_url" \
        -H 'Content-Type: application/json' \
        -d "{\"text\": \"$message\"}" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "✅ Sent to Slack"
    else
        echo "⚠️  Failed to send to Slack"
    fi
}

# Export function if sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    export -f send_to_slack
fi
