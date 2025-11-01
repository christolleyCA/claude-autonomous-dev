#!/bin/bash
# Claude Response Helper
# Allows Claude to respond to messages from Slack

SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

PENDING_MESSAGE_FILE="${HOME}/.claude-pending-message.txt"
MESSAGE_METADATA_FILE="${HOME}/.claude-message-metadata.json"

# ============================================================================
# MAIN FUNCTION
# ============================================================================

respond_to_message() {
    local response="$1"

    # Check if there's a pending message
    if [ ! -f "$MESSAGE_METADATA_FILE" ]; then
        echo "❌ No pending message found."
        echo "   Metadata file not found: $MESSAGE_METADATA_FILE"
        return 1
    fi

    # Read metadata
    local message_id=$(jq -r '.message_id' "$MESSAGE_METADATA_FILE")
    local channel_id=$(jq -r '.channel_id' "$MESSAGE_METADATA_FILE")
    local original_message=$(jq -r '.message' "$MESSAGE_METADATA_FILE")

    echo "📤 Sending response to Slack..."
    echo "   Message ID: $message_id"
    echo "   Channel: $channel_id"
    echo ""

    # Update database with response
    local update_result=$(curl -s -X PATCH "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.${message_id}" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "{
            \"status\": \"completed\",
            \"response\": $(echo "$response" | jq -Rs .),
            \"processed_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
        }")

    echo "✅ Response saved to database"
    echo "   The N8n workflow will post it to Slack within ~15 seconds"
    echo ""

    # Clean up pending files
    rm -f "$PENDING_MESSAGE_FILE"
    rm -f "$MESSAGE_METADATA_FILE"

    echo "🧹 Cleaned up pending message files"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✨ Response sent! Check Slack in ~15 seconds."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================================================
# SHOW PENDING MESSAGE
# ============================================================================

show_pending_message() {
    if [ ! -f "$MESSAGE_METADATA_FILE" ]; then
        echo "📭 No pending messages"
        return 0
    fi

    local message=$(jq -r '.message' "$MESSAGE_METADATA_FILE")
    local user_id=$(jq -r '.user_id' "$MESSAGE_METADATA_FILE")
    local received_at=$(jq -r '.received_at' "$MESSAGE_METADATA_FILE")

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📬 PENDING MESSAGE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "From: $user_id"
    echo "Received: $received_at"
    echo ""
    echo "Message:"
    echo "┌─────────────────────────────────────────────────────────────────────────┐"
    echo "$message" | fold -s -w 73 | while IFS= read -r line; do
        printf "│ %-71s │\n" "$line"
    done
    echo "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""
}

# ============================================================================
# CLI
# ============================================================================

if [ "$1" = "show" ]; then
    show_pending_message
elif [ "$1" = "clear" ]; then
    rm -f "$PENDING_MESSAGE_FILE"
    rm -f "$MESSAGE_METADATA_FILE"
    echo "✅ Cleared pending message"
elif [ -n "$1" ]; then
    respond_to_message "$*"
else
    echo "Claude Response Helper"
    echo ""
    echo "Usage:"
    echo "  $0 show                    - Show pending message"
    echo "  $0 clear                   - Clear pending message"
    echo "  $0 <response>              - Send response to Slack"
    echo ""
    echo "Examples:"
    echo "  $0 show"
    echo "  $0 \"I've added error handling to the email function!\""
    echo ""
fi
