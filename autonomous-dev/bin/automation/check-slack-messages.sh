#!/bin/bash
# Check for pending Slack messages and display them for Claude to respond to

SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📬 Checking for pending Slack messages..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Fetch messages in "processing" status
result=$(curl -s "${SUPABASE_URL}/rest/v1/claude_commands?status=eq.processing&order=created_at.asc" \
    -H "apikey: ${SUPABASE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_KEY}")

count=$(echo "$result" | jq '. | length')

if [ "$count" -eq 0 ]; then
    echo "✅ No pending messages!"
    echo ""
    exit 0
fi

echo "📨 Found $count pending message(s):"
echo ""

# Display each message
for i in $(seq 0 $((count - 1))); do
    message_id=$(echo "$result" | jq -r ".[$i].id")
    message=$(echo "$result" | jq -r ".[$i].command")
    created_at=$(echo "$result" | jq -r ".[$i].created_at")
    user_id=$(echo "$result" | jq -r ".[$i].user_id")

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Message #$((i + 1))"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "ID: $message_id"
    echo "From: $user_id"
    echo "Time: $created_at"
    echo ""
    echo "Message:"
    echo "┌─────────────────────────────────────────────────────────────────────────┐"
    echo "$message" | fold -s -w 73 | while IFS= read -r line; do
        printf "│ %-71s │\n" "$line"
    done
    echo "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Claude should respond to these messages"
echo "   Responses will be automatically posted to Slack"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
