#!/bin/bash
# Insert a test command directly to Supabase with Slack notifications

SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

# Default Slack channel for terminal commands
# ⚠️ REPLACE WITH YOUR CHANNEL ID
DEFAULT_SLACK_CHANNEL="C09M9A33FFF"

echo "📤 Inserting test command with Slack notifications..."
echo "   Channel: $DEFAULT_SLACK_CHANNEL"
echo ""

curl -X POST "${SUPABASE_URL}/rest/v1/claude_commands" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  --data-binary @- <<EOF
{
  "command": "echo Hello from manual test",
  "source": "manual_test",
  "status": "pending",
  "user_id": "TEST_USER",
  "slack_channel_id": "${DEFAULT_SLACK_CHANNEL}"
}
EOF

echo ""
echo "✅ Test command inserted!"
echo "💻 This will be detected as a terminal command"
echo "📱 Slack notifications will be sent to: $DEFAULT_SLACK_CHANNEL"
