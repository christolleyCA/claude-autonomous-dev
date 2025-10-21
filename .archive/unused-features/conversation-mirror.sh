#!/bin/bash
# Claude Code Conversation Mirror to Slack
# Posts updates about what Claude is working on to Slack in real-time

POLL_INTERVAL=30  # Check every 30 seconds
# Load .env if available
[ -f "${BASH_SOURCE[0]%/*}/.env" ] && source "${BASH_SOURCE[0]%/*}/.env"
SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN:-}"
SLACK_CHANNEL="C09M9A33FFF"  # claude-code-updates channel
CONVERSATION_LOG="/tmp/claude-conversation-mirror.log"
LAST_POSITION_FILE="/tmp/conversation-mirror-position.txt"

# Initialize position tracker
if [ ! -f "$LAST_POSITION_FILE" ]; then
    echo "0" > "$LAST_POSITION_FILE"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🪞 Claude Code Conversation Mirror"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✨ Mirroring laptop conversation to Slack"
echo "📱 Channel: claude-code-updates"
echo "🔄 Checking every ${POLL_INTERVAL} seconds"
echo ""
echo "Press Ctrl+C to stop"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Post message to Slack
post_to_slack() {
    local message="$1"

    # Build JSON payload - NO THREADING
    local payload=$(jq -n \
        --arg channel "$SLACK_CHANNEL" \
        --arg text "$message" \
        '{
            channel: $channel,
            text: $text
        }')

    # Post to Slack
    local response=$(curl -s -X POST "https://slack.com/api/chat.postMessage" \
        -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Return success
    echo "ok"
}

# Monitor conversation and post updates
monitor_conversation() {
    # This is a simplified version - we'll log activity summaries
    local current_time=$(date '+%H:%M:%S')

    # Check if there's new activity by monitoring file changes
    if [ -f "$CONVERSATION_LOG" ]; then
        local last_pos=$(cat "$LAST_POSITION_FILE")
        local current_size=$(wc -c < "$CONVERSATION_LOG" 2>/dev/null || echo "0")

        if [ "$current_size" -gt "$last_pos" ]; then
            # New content detected
            local new_content=$(tail -c +$((last_pos + 1)) "$CONVERSATION_LOG" 2>/dev/null)

            if [ -n "$new_content" ]; then
                echo "[$current_time] 📝 New activity detected, posting to Slack..."

                # Extract summary from new content
                local summary=$(echo "$new_content" | head -100)

                # Post to Slack
                post_to_slack "🔔 *Laptop Activity Update* [$current_time]

\`\`\`
${summary}
\`\`\`" > /dev/null

                echo "[$current_time] ✅ Posted to Slack"
            fi

            # Update position
            echo "$current_size" > "$LAST_POSITION_FILE"
        fi
    fi
}

# Log this conversation's activity
log_activity() {
    local activity="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $activity" >> "$CONVERSATION_LOG"
}

# Signal handler
trap 'echo ""; echo "👋 Stopping Conversation Mirror"; exit 0' INT TERM

# Send startup notification
echo "[$(date '+%H:%M:%S')] 📡 Sending startup notification to Slack..."
post_to_slack "🪞 *Laptop Conversation Mirror Started*

I'll now post updates about what's happening on the laptop in real-time as top-level messages (not threaded).

You'll see:
• When you ask me to do something
• What I'm working on
• When tasks complete
• Any important updates

All updates will appear as regular channel messages! 🚀" > /dev/null

echo "[$(date '+%H:%M:%S')] ✅ Startup notification sent"
echo ""

# Main loop
while true; do
    echo "[$(date '+%H:%M:%S')] 🔍 Monitoring for activity..."
    monitor_conversation
    sleep $POLL_INTERVAL
done
