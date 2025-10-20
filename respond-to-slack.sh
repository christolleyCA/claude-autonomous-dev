#!/bin/bash
# Helper script to respond to a specific Slack message by ID

if [ $# -lt 2 ]; then
    echo "Usage: $0 <message_id> <response>"
    echo ""
    echo "Example:"
    echo "  $0 abc123 'Here is my response to your message'"
    exit 1
fi

MESSAGE_ID="$1"
RESPONSE="$2"

SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📤 Sending response to Slack..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Message ID: $MESSAGE_ID"
echo "Response: $RESPONSE"
echo ""

# Create JSON payload
payload=$(jq -n \
    --arg response "$RESPONSE" \
    --arg processed_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    '{
        status: "completed",
        response: $response,
        processed_at: $processed_at
    }')

# Update the database
curl -s -X PATCH "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.${MESSAGE_ID}" \
    -H "apikey: ${SUPABASE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_KEY}" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d "$payload"

if [ $? -eq 0 ]; then
    echo "✅ Response saved to database!"
    echo "📬 The response posting service will send it to Slack within 15 seconds"
else
    echo "❌ Failed to save response"
fi

echo ""
