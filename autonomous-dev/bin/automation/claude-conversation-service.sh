#!/bin/bash
# Claude Code Conversation Service
# Receives conversational messages from Slack and displays them for Claude to respond to

# ============================================================================
# CONFIGURATION
# ============================================================================

POLL_INTERVAL=15  # Check every 15 seconds for new messages
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Supabase Configuration
SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

# Slack Bot Token
SLACK_BOT_TOKEN="YOUR_SLACK_BOT_TOKEN_HERE"  # ⚠️ REPLACE WITH YOUR ACTUAL TOKEN

# Pending message file (where Claude can find new messages)
PENDING_MESSAGE_FILE="${HOME}/.claude-pending-message.txt"
MESSAGE_METADATA_FILE="${HOME}/.claude-message-metadata.json"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Mark message as processing
mark_processing() {
    local message_id=$1
    curl -s -X PATCH "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.${message_id}" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "{\"status\": \"processing\", \"processed_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}" \
        > /dev/null 2>&1
}

# Send Slack notification
send_slack_notification() {
    local channel_id="$1"
    local message="$2"
    local thread_ts="$3"

    if [ "$SLACK_BOT_TOKEN" = "YOUR_SLACK_BOT_TOKEN_HERE" ]; then
        return 0
    fi

    local body="{\"channel\": \"${channel_id}\", \"text\": $(echo "$message" | jq -Rs .)}"

    if [ -n "$thread_ts" ] && [ "$thread_ts" != "null" ]; then
        body=$(echo "$body" | jq ". + {\"thread_ts\": \"${thread_ts}\"}")
    fi

    curl -s -X POST "https://slack.com/api/chat.postMessage" \
        -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$body" > /dev/null 2>&1
}

# Display message banner
display_message_banner() {
    local message="$1"
    local from="$2"

    # Terminal bell
    echo -e "\a"

    # Clear any previous pending message display
    clear

    # Display prominent banner
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📱 NEW MESSAGE FROM SLACK"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "From: ${from}"
    echo "Time: $(date '+%I:%M:%S %p')"
    echo ""
    echo "Message:"
    echo "┌─────────────────────────────────────────────────────────────────────────┐"
    echo "│                                                                         │"

    # Word wrap the message to 73 characters
    echo "$message" | fold -s -w 73 | while IFS= read -r line; do
        printf "│ %-71s │\n" "$line"
    done

    echo "│                                                                         │"
    echo "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "💡 Claude will see this message and can respond to it."
    echo "   The response will automatically be sent back to Slack."
    echo ""
}

# Save message to pending file
save_pending_message() {
    local message_id="$1"
    local message="$2"
    local channel_id="$3"
    local thread_ts="$4"
    local user_id="$5"

    # Save the message text
    echo "$message" > "$PENDING_MESSAGE_FILE"

    # Save metadata for response routing
    cat > "$MESSAGE_METADATA_FILE" <<EOF
{
  "message_id": "${message_id}",
  "channel_id": "${channel_id}",
  "thread_ts": "${thread_ts}",
  "user_id": "${user_id}",
  "received_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "message": $(echo "$message" | jq -Rs .)
}
EOF

    echo "📝 Message saved to: $PENDING_MESSAGE_FILE"
    echo "📋 Metadata saved to: $MESSAGE_METADATA_FILE"
}

# Check for pending messages
check_for_messages() {
    local result=$(curl -s "${SUPABASE_URL}/rest/v1/claude_commands?status=eq.pending&order=created_at.asc&limit=1" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}")

    local count=$(echo "$result" | jq '. | length')

    if [ "$count" -gt 0 ]; then
        # Extract message details
        local message_id=$(echo "$result" | jq -r '.[0].id')
        local message=$(echo "$result" | jq -r '.[0].command')
        local channel_id=$(echo "$result" | jq -r '.[0].slack_channel_id // "unknown"')
        local thread_ts=$(echo "$result" | jq -r '.[0].slack_thread_ts // ""')
        local user_id=$(echo "$result" | jq -r '.[0].user_id // "unknown"')
        local source=$(echo "$result" | jq -r '.[0].source // "slack"')

        echo "MESSAGE_FOUND|${message_id}|${message}|${channel_id}|${thread_ts}|${user_id}|${source}"
    else
        echo "NO_MESSAGES"
    fi
}

# Process incoming message
process_message() {
    local message_id="$1"
    local message="$2"
    local channel_id="$3"
    local thread_ts="$4"
    local user_id="$5"
    local source="$6"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📨 Processing new message..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Message ID: ${message_id}"
    echo "Source: ${source}"
    echo "From: ${user_id}"
    echo ""

    # Mark as processing
    mark_processing "$message_id"

    # Send acknowledgment to Slack
    if [ "$channel_id" != "null" ] && [ -n "$channel_id" ]; then
        local ack_message="👀 *Message received!*
I'm reviewing your message and will respond shortly.

_Your message:_
> ${message}"
        send_slack_notification "$channel_id" "$ack_message" "$thread_ts"
    fi

    # Display in terminal
    display_message_banner "$message" "$user_id"

    # Save to pending file
    save_pending_message "$message_id" "$message" "$channel_id" "$thread_ts" "$user_id"

    echo ""
    echo "⏳ Waiting for Claude's response..."
    echo "   (Claude will see this message and respond to it)"
    echo ""
}

# ============================================================================
# MAIN POLLING LOOP
# ============================================================================

main() {
    echo "🤖 Claude Code Conversation Service"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✨ This service monitors for conversational messages from Slack"
    echo "💬 When you send /cc <message> from Slack, it will appear here"
    echo "🤖 Claude will see the message and can respond to it"
    echo "📤 Responses are automatically sent back to Slack"
    echo ""
    echo "Polling interval: ${POLL_INTERVAL} seconds"
    echo "Pending message file: ${PENDING_MESSAGE_FILE}"
    echo ""

    # Check Slack configuration
    if [ "$SLACK_BOT_TOKEN" = "YOUR_SLACK_BOT_TOKEN_HERE" ]; then
        echo "⚠️  WARNING: Slack Bot Token not configured!"
        echo "   Notifications will not be sent to Slack."
        echo "   Edit this script and replace SLACK_BOT_TOKEN"
        echo ""
    fi

    echo "Press Ctrl+C to stop"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    while true; do
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Checking for new messages..."

        # Check for messages
        local result=$(check_for_messages)

        if [[ "$result" == MESSAGE_FOUND* ]]; then
            # Parse the result
            IFS='|' read -r _ message_id message channel_id thread_ts user_id source <<< "$result"

            # Process the message
            process_message "$message_id" "$message" "$channel_id" "$thread_ts" "$user_id" "$source"
        fi

        # Wait before next poll
        sleep $POLL_INTERVAL
    done
}

# ============================================================================
# SIGNAL HANDLING
# ============================================================================

trap 'echo ""; echo "👋 Shutting down Claude Code Conversation Service"; exit 0' INT TERM

# ============================================================================
# START THE SERVICE
# ============================================================================

main
