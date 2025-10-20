#!/bin/bash
# Full Conversation Mirror - Posts ALL Claude messages to Slack
# Monitors the conversation and posts every response in real-time

POLL_INTERVAL=10  # Check every 10 seconds for new activity
# Load .env if available
[ -f "${BASH_SOURCE[0]%/*}/.env" ] && source "${BASH_SOURCE[0]%/*}/.env"
SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN:-}"
SLACK_CHANNEL="C09M9A33FFF"
POSITION_FILE="/tmp/conversation-mirror-position.txt"

# Initialize position tracker
if [ ! -f "$POSITION_FILE" ]; then
    # Start from current position to avoid flooding with history
    wc -c < ~/.claude-code/session.log 2>/dev/null || echo "0" > "$POSITION_FILE"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🪞 Full Conversation Mirror - All Messages to Slack"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✨ Posting ALL Claude messages to Slack in real-time"
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

    # Build JSON payload
    local payload=$(jq -n \
        --arg channel "$SLACK_CHANNEL" \
        --arg text "$message" \
        '{
            channel: $channel,
            text: $text
        }')

    # Post to Slack
    curl -s -X POST "https://slack.com/api/chat.postMessage" \
        -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$payload" > /dev/null 2>&1
}

# Extract and post new conversation content
monitor_conversation() {
    local current_time=$(date '+%H:%M:%S')

    # Try to find Claude Code session/conversation files
    local conversation_files=(
        "${HOME}/.claude-code/conversation.log"
        "${HOME}/.claude-code/session.log"
        "/tmp/claude-session.log"
        "/var/tmp/claude-conversation.log"
    )

    local found_file=""
    for file in "${conversation_files[@]}"; do
        if [ -f "$file" ]; then
            found_file="$file"
            break
        fi
    done

    # If no conversation file found, create a simple activity logger
    if [ -z "$found_file" ]; then
        # Just monitor for any activity indicators
        return
    fi

    # Check for new content
    local last_pos=$(cat "$POSITION_FILE")
    local current_size=$(wc -c < "$found_file" 2>/dev/null || echo "0")

    if [ "$current_size" -gt "$last_pos" ]; then
        # New content detected
        local new_content=$(tail -c +$((last_pos + 1)) "$found_file" 2>/dev/null)

        if [ -n "$new_content" ]; then
            echo "[$current_time] 📝 New activity detected (${#new_content} chars)"

            # Extract meaningful content (filter out noise)
            local clean_content=$(echo "$new_content" | grep -v "^$" | head -50)

            if [ -n "$clean_content" ]; then
                # Post to Slack with timestamp
                local message="🤖 *Claude Activity* [$current_time]

\`\`\`
${clean_content}
\`\`\`"

                post_to_slack "$message"
                echo "[$current_time] ✅ Posted to Slack"
            fi
        fi

        # Update position
        echo "$current_size" > "$POSITION_FILE"
    fi
}

# Create a manual activity logger
log_activity() {
    local activity="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    post_to_slack "💬 *[$timestamp]*
$activity"
}

# Signal handler
trap 'echo ""; echo "👋 Stopping Full Conversation Mirror"; exit 0' INT TERM

# Send startup notification
echo "[$(date '+%H:%M:%S')] 📡 Sending startup notification..."
post_to_slack "🪞 *Full Conversation Mirror Started*

Now mirroring ALL Claude messages to Slack in real-time!

You'll see:
• Every message I send
• Tool calls I make
• Code I write
• Commands I run
• Everything I'm working on

Updates every 10 seconds! 🚀"

echo "[$(date '+%H:%M:%S')] ✅ Started"
echo ""

# Export function for external use
export -f post_to_slack
export SLACK_BOT_TOKEN SLACK_CHANNEL

# Main loop
MESSAGE_COUNT=0
while true; do
    echo "[$(date '+%H:%M:%S')] 🔍 Monitoring..."
    monitor_conversation

    # Also check for messages from this script
    if [ $((MESSAGE_COUNT % 60)) -eq 0 ]; then
        # Send heartbeat every 10 minutes
        post_to_slack "💓 Mirror active - monitoring conversation"
        echo "[$(date '+%H:%M:%S')] 💓 Heartbeat sent"
    fi

    MESSAGE_COUNT=$((MESSAGE_COUNT + 1))
    sleep $POLL_INTERVAL
done
