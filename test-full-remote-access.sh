#!/bin/bash
# Complete End-to-End Remote Access Test
# Tests the full Slack → Claude Code → Slack flow

echo "🧪 CLAUDE CODE REMOTE ACCESS - FULL SYSTEM TEST"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

echo -e "${YELLOW}Prerequisites Check:${NC}"
echo "-------------------"
echo ""

# Check 1: Polling service
echo -n "1. Claude Code polling service: "
if pgrep -f "start-remote-access.sh" > /dev/null; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not running${NC}"
    echo "   Start with: ./start-remote-access.sh"
    echo ""
fi

# Check 2: N8n workflows
echo "2. N8n workflows:"
echo "   - slack-cc-command (receives commands)"
echo "   - claude-responses-to-slack (sends responses)"
echo "   ${YELLOW}→ Verify both are ACTIVE in N8n UI${NC}"
echo ""

# Check 3: Slack configuration
echo "3. Slack slash command:"
echo "   - /cc command should be configured"
echo "   - Request URL: https://n8n.grantpilot.app/webhook/cc"
echo "   ${YELLOW}→ Verify in https://api.slack.com/apps${NC}"
echo ""

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
echo ""

# Test mode selection
echo "Select test mode:"
echo ""
echo "  1) Manual Database Test (insert command via Supabase)"
echo "  2) Webhook Test (simulate Slack slash command)"
echo "  3) Instructions for Real Slack Test"
echo "  4) Watch Database for Changes"
echo ""
read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}TEST 1: Manual Database Insert${NC}"
        echo "================================"
        echo ""

        test_command="echo 'Test at $(date)'"
        echo "Inserting test command: $test_command"

        result=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/claude_commands" \
          -H "apikey: ${SUPABASE_KEY}" \
          -H "Authorization: Bearer ${SUPABASE_KEY}" \
          -H "Content-Type: application/json" \
          -H "Prefer: return=representation" \
          -d "{
            \"command\": \"$test_command\",
            \"source\": \"test\",
            \"status\": \"pending\",
            \"user_id\": \"TEST_USER\",
            \"slack_channel_id\": \"C12345TEST\"
          }")

        command_id=$(echo "$result" | jq -r '.[0].id')

        if [ "$command_id" != "null" ] && [ -n "$command_id" ]; then
            echo -e "${GREEN}✓ Command inserted successfully${NC}"
            echo "  Command ID: $command_id"
            echo ""
            echo "Now watch for:"
            echo "  1. Claude Code to detect it (within 30 seconds)"
            echo "  2. Status change to 'completed'"
            echo "  3. Response written to database"
            echo ""
            echo "Monitoring for 60 seconds..."
            echo ""

            for i in {1..12}; do
                sleep 5
                status=$(curl -s "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.$command_id&select=status,response" \
                  -H "apikey: ${SUPABASE_KEY}" \
                  -H "Authorization: Bearer ${SUPABASE_KEY}" | jq -r '.[0].status')

                echo "[$((i*5))s] Status: $status"

                if [ "$status" == "completed" ]; then
                    echo ""
                    echo -e "${GREEN}✓ Command completed!${NC}"
                    response=$(curl -s "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.$command_id&select=response" \
                      -H "apikey: ${SUPABASE_KEY}" \
                      -H "Authorization: Bearer ${SUPABASE_KEY}" | jq -r '.[0].response')
                    echo "Response: $response"
                    break
                fi
            done
        else
            echo -e "${RED}✗ Failed to insert command${NC}"
        fi
        ;;

    2)
        echo ""
        echo -e "${YELLOW}TEST 2: Webhook Test${NC}"
        echo "====================="
        echo ""

        test_command="date"
        echo "Sending webhook request with command: $test_command"
        echo ""

        response=$(curl -s -X POST "https://n8n.grantpilot.app/webhook/cc" \
          -d "text=$test_command&channel_id=C12345TEST&user_id=U12345TEST")

        echo "N8n Response:"
        echo "$response" | jq . 2>/dev/null || echo "$response"
        echo ""

        echo "Check Supabase for the command..."
        sleep 2

        latest=$(curl -s "${SUPABASE_URL}/rest/v1/claude_commands?order=created_at.desc&limit=1&select=id,command,status" \
          -H "apikey: ${SUPABASE_KEY}" \
          -H "Authorization: Bearer ${SUPABASE_KEY}")

        echo "Latest command in database:"
        echo "$latest" | jq .
        ;;

    3)
        echo ""
        echo -e "${YELLOW}TEST 3: Real Slack Test Instructions${NC}"
        echo "======================================"
        echo ""
        echo "🎯 Complete End-to-End Test:"
        echo ""
        echo "1. Ensure Claude Code polling is running:"
        echo "   ${GREEN}./start-remote-access.sh${NC}"
        echo ""
        echo "2. Ensure both N8n workflows are ACTIVE:"
        echo "   - slack-cc-command"
        echo "   - claude-responses-to-slack"
        echo ""
        echo "3. In Slack, type:"
        echo "   ${GREEN}/cc echo 'Hello from remote!'${NC}"
        echo ""
        echo "4. Expected timeline:"
        echo "   - Immediate: \"🤖 Command received!\" acknowledgment"
        echo "   - ~0-30s: Claude Code detects and executes"
        echo "   - ~30-45s: Response appears in Slack"
        echo ""
        echo "5. You should see in Slack:"
        echo "   ✅ Command completed:"
        echo "   \`\`\`echo 'Hello from remote!'\`\`\`"
        echo ""
        echo "   Result:"
        echo "   \`\`\`Hello from remote!\`\`\`"
        echo ""
        echo "🎉 If you see the response, the system is working!"
        ;;

    4)
        echo ""
        echo -e "${YELLOW}TEST 4: Watch Database${NC}"
        echo "======================="
        echo ""
        echo "Monitoring claude_commands table for changes..."
        echo "Press Ctrl+C to stop"
        echo ""

        while true; do
            clear
            echo "Latest 5 commands:"
            echo ""

            curl -s "${SUPABASE_URL}/rest/v1/claude_commands?order=created_at.desc&limit=5&select=created_at,command,status,slack_sent" \
              -H "apikey: ${SUPABASE_KEY}" \
              -H "Authorization: Bearer ${SUPABASE_KEY}" | jq -r '.[] | "\(.created_at) | \(.status) | sent:\(.slack_sent // false) | \(.command)"'

            echo ""
            echo "Refreshing every 5 seconds... (Ctrl+C to stop)"
            sleep 5
        done
        ;;

    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
echo ""
echo "📚 Additional Resources:"
echo "  - Setup Guide: REMOTE-ACCESS-SETUP.md"
echo "  - Slack Setup: SLACK-SLASH-COMMAND-SETUP.md"
echo "  - Token Config: SLACK-BOT-TOKEN-NEEDED.txt"
echo ""
echo "🌐 URLs:"
echo "  - N8n: https://n8n.grantpilot.app"
echo "  - Supabase: https://hjtvtkffpziopozmtsnb.supabase.co"
echo "  - Slack Apps: https://api.slack.com/apps"
echo ""
