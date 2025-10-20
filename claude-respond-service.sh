#!/bin/bash
# Claude Response Posting Service
# Polls for completed responses and posts them to Slack
# Companion to claude-conversation-service.sh

# ============================================================================
# CONFIGURATION
# ============================================================================

POLL_INTERVAL=15  # Check every 15 seconds

# Supabase Configuration
SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

# Slack Bot Token - Configured and validated
# Load environment variables from .env if available
[ -f "${BASH_SOURCE[0]%/*}/.env" ] && source "${BASH_SOURCE[0]%/*}/.env"
SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN:-}"

# ============================================================================
# FUNCTIONS
# ============================================================================

# Get completed responses that haven't been sent
get_pending_responses() {
    curl -s "${SUPABASE_URL}/rest/v1/claude_commands?status=eq.completed&slack_sent=eq.false&select=id,response,slack_channel_id,slack_thread_ts" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}"
}

# Post response to Slack
post_to_slack() {
    local channel="$1"
    local text="$2"
    local thread_ts="$3"

    # Build JSON payload
    local payload=$(jq -n \
        --arg channel "$channel" \
        --arg text "$text" \
        --arg thread_ts "$thread_ts" \
        '{channel: $channel, text: $text} + if $thread_ts != "" and $thread_ts != "null" then {thread_ts: $thread_ts} else {} end')

    # Post to Slack
    local response=$(curl -s -X POST "https://slack.com/api/chat.postMessage" \
        -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Check if successful
    local ok=$(echo "$response" | jq -r '.ok')
    if [ "$ok" = "true" ]; then
        echo "success"
    else
        local error=$(echo "$response" | jq -r '.error')
        echo "error:$error"
    fi
}

# Mark message as sent
mark_as_sent() {
    local message_id="$1"

    curl -s -X PATCH "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.${message_id}" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "{\"slack_sent\": true, \"slack_sent_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}" \
        > /dev/null 2>&1
}

# Process pending responses
process_responses() {
    local responses=$(get_pending_responses)

    # DEBUG: Log raw response
    echo "  🔍 DEBUG: Database query returned:"
    echo "$responses" | jq '.' 2>/dev/null || echo "  ⚠️  Invalid JSON or empty response"

    local count=$(echo "$responses" | jq '. | length' 2>/dev/null || echo "0")

    if [ "$count" -gt 0 ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📤 Found $count response(s) to send"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Process each response
        echo "$responses" | jq -c '.[]' | while read -r response; do
            local message_id=$(echo "$response" | jq -r '.id')
            local text=$(echo "$response" | jq -r '.response')
            local channel=$(echo "$response" | jq -r '.slack_channel_id')
            local thread_ts=$(echo "$response" | jq -r '.slack_thread_ts // ""')

            echo ""
            echo "Processing message: $message_id"
            echo "  Channel: $channel"
            echo "  Thread: ${thread_ts:-none}"
            echo "  Response length: ${#text} chars"

            # Post to Slack
            echo "  📤 Posting to Slack..."
            local result=$(post_to_slack "$channel" "$text" "$thread_ts")

            if [[ "$result" == "success" ]]; then
                echo "  ✅ Posted successfully!"

                # Mark as sent
                echo "  💾 Marking as sent in database..."
                mark_as_sent "$message_id"
                echo "  ✅ Marked as sent"
            else
                local error="${result#error:}"
                echo "  ❌ Failed to post: $error"
                echo "  ⚠️  Will retry on next poll"
            fi
        done

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
        echo "  ✓ No pending responses (count: $count)"
    fi
}

# ============================================================================
# MAIN LOOP
# ============================================================================

main() {
    echo "📤 Claude Response Posting Service"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✨ This service posts Claude's responses back to Slack"
    echo "🔄 Polls database every ${POLL_INTERVAL} seconds for completed responses"
    echo "📱 Posts responses to Slack automatically"
    echo "💾 Marks messages as sent to prevent duplicates"
    echo ""
    echo "Polling interval: ${POLL_INTERVAL} seconds"
    echo ""

    # Check Slack token configuration
    if [ "$SLACK_BOT_TOKEN" = "YOUR_SLACK_BOT_TOKEN_HERE" ]; then
        echo "⚠️  WARNING: Slack Bot Token not configured!"
        echo "   Responses will NOT be posted to Slack until you add a valid token."
        echo "   Edit this script and replace SLACK_BOT_TOKEN on line 15"
        echo ""
        echo "   Get token from: https://api.slack.com/apps"
        echo "   Required scopes: chat:write, chat:write.public"
        echo ""
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    echo "Press Ctrl+C to stop"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    while true; do
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Checking for completed responses..."

        # Process any pending responses
        process_responses

        # Wait before next poll
        sleep $POLL_INTERVAL
    done
}

# ============================================================================
# SIGNAL HANDLING
# ============================================================================

trap 'echo ""; echo "👋 Shutting down Claude Response Posting Service"; exit 0' INT TERM

# ============================================================================
# START THE SERVICE
# ============================================================================

main
