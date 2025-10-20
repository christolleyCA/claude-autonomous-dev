#!/bin/bash
# Autonomous Claude Responder
# Automatically responds to Slack messages using Claude API - NO manual intervention needed!

POLL_INTERVAL=20  # Check every 20 seconds
SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

# Anthropic API Configuration
# Get your API key from: https://console.anthropic.com/
ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  ERROR: ANTHROPIC_API_KEY not set!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "To make this service work, you need to set your Anthropic API key:"
    echo ""
    echo "1. Get your API key from: https://console.anthropic.com/"
    echo ""
    echo "2. Set it as an environment variable:"
    echo "   export ANTHROPIC_API_KEY='your-api-key-here'"
    echo ""
    echo "3. Then run this script again:"
    echo "   ./autonomous-responder.sh"
    echo ""
    echo "Or run it directly:"
    echo "   ANTHROPIC_API_KEY='your-key' ./autonomous-responder.sh &"
    echo ""
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 Autonomous Claude Responder"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✨ Automatically responding to Slack messages using Claude API"
echo "🔄 Checking every ${POLL_INTERVAL} seconds"
echo "🚀 Fully autonomous - no manual intervention needed!"
echo ""
echo "Press Ctrl+C to stop"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Generate response using Claude API
generate_response() {
    local user_message="$1"

    # Create the API request
    local api_response=$(curl -s https://api.anthropic.com/v1/messages \
        -H "x-api-key: ${ANTHROPIC_API_KEY}" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "{
            \"model\": \"claude-sonnet-4-20250514\",
            \"max_tokens\": 1024,
            \"messages\": [{
                \"role\": \"user\",
                \"content\": \"You are a helpful AI assistant responding to messages sent via Slack. The user sent: \\\"${user_message}\\\"\\n\\nProvide a helpful, friendly, and concise response. Be natural and conversational.\"
            }]
        }")

    # Extract the response text
    local response_text=$(echo "$api_response" | jq -r '.content[0].text // empty')

    if [ -z "$response_text" ]; then
        # If API call failed, return error details
        local error_message=$(echo "$api_response" | jq -r '.error.message // "Unknown error"')
        echo "ERROR: API call failed - $error_message" >&2
        return 1
    fi

    echo "$response_text"
}

# Process a pending message
process_message() {
    local message_id="$1"
    local message="$2"
    local created_at="$3"

    echo "[$(date '+%H:%M:%S')] 📨 Processing message: $message_id"
    echo "  Message: ${message:0:80}..."
    echo "  🤖 Generating response with Claude API..."

    # Generate response using Claude
    local response=$(generate_response "$message")

    if [ $? -ne 0 ]; then
        echo "  ❌ Failed to generate response"
        return 1
    fi

    echo "  ✅ Response generated (${#response} chars)"

    # Save response to database
    local payload=$(jq -n \
        --arg response "$response" \
        --arg processed_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '{
            status: "completed",
            response: $response,
            processed_at: $processed_at
        }')

    curl -s -X PATCH "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.${message_id}" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "$payload" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "  💾 Response saved to database"
        echo "  📤 Will be posted to Slack automatically within 15 seconds"
        echo ""
        return 0
    else
        echo "  ❌ Failed to save response to database"
        return 1
    fi
}

# Check for pending messages and process them
check_and_process() {
    local result=$(curl -s "${SUPABASE_URL}/rest/v1/claude_commands?status=eq.pending&order=created_at.asc" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}")

    local count=$(echo "$result" | jq '. | length' 2>/dev/null || echo "0")

    if [ "$count" -gt 0 ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🚨 Found $count pending message(s) - generating responses..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # Process each message
        for i in $(seq 0 $((count - 1))); do
            local message_id=$(echo "$result" | jq -r ".[$i].id")
            local message=$(echo "$result" | jq -r ".[$i].command")
            local created_at=$(echo "$result" | jq -r ".[$i].created_at")

            # SKIP build-feature commands - those are handled by start-remote-access.sh
            if [[ "$message" == build-feature* ]]; then
                echo "  ⏭️  Skipping build-feature command (handled by remote access service)"
                continue
            fi

            # Mark as processing before generating response
            curl -s -X PATCH "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.${message_id}" \
                -H "apikey: ${SUPABASE_KEY}" \
                -H "Authorization: Bearer ${SUPABASE_KEY}" \
                -H "Content-Type: application/json" \
                -H "Prefer: return=minimal" \
                -d '{"status": "processing"}' > /dev/null 2>&1

            process_message "$message_id" "$message" "$created_at"
        done

        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "✅ All messages processed!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
}

# Signal handler for clean shutdown
trap 'echo ""; echo "👋 Stopping Autonomous Responder"; exit 0' INT TERM

# Main loop
while true; do
    echo "[$(date '+%H:%M:%S')] 🔍 Checking for pending messages..."
    check_and_process
    sleep $POLL_INTERVAL
done
