#!/bin/bash
# Test Script for Enhanced Slack Progress Updates
# This script tests all notification stages

echo "🧪 Testing Enhanced Claude Code Progress Updates"
echo "================================================"
echo ""

# Configuration
SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Select Test:${NC}"
echo ""
echo "  1) Quick Test - Simple echo command (fast)"
echo "  2) Duration Test - Sleep command to see timing (5 seconds)"
echo "  3) Multi-line Test - Command with lots of output"
echo "  4) Error Test - Intentional failure to test error notifications"
echo "  5) Long-Running Test - Simulate complex operation (10 seconds)"
echo ""
read -p "Enter choice (1-5): " choice

case $choice in
    1)
        test_name="Quick Echo Test"
        test_command="echo 'Progress update test successful!'"
        ;;
    2)
        test_name="Duration Test"
        test_command="sleep 5 && echo 'Sleep complete after 5 seconds'"
        ;;
    3)
        test_name="Multi-line Output Test"
        test_command="ls -la / | head -20"
        ;;
    4)
        test_name="Error Test"
        test_command="cat /nonexistent/file/path.txt"
        ;;
    5)
        test_name="Long-Running Test"
        test_command="for i in {1..10}; do echo \"Step \$i of 10\"; sleep 1; done"
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}Test:${NC} $test_name"
echo -e "${BLUE}Command:${NC} $test_command"
echo ""

# Check if start-remote-access.sh is running
if pgrep -f "start-remote-access.sh" > /dev/null; then
    echo -e "${GREEN}✓ Claude Code polling service is running${NC}"
else
    echo -e "${RED}✗ Claude Code polling service is NOT running${NC}"
    echo ""
    echo "Please start it first:"
    echo "  cd /Users/christophertolleymacbook2019"
    echo "  ./start-remote-access.sh"
    echo ""
    exit 1
fi

# Check if Slack token is configured
if grep -q "YOUR_SLACK_BOT_TOKEN_HERE" start-remote-access.sh 2>/dev/null; then
    echo -e "${YELLOW}⚠  WARNING: Slack Bot Token not configured${NC}"
    echo "   Progress notifications will be skipped"
    echo "   See: SLACK-BOT-TOKEN-SETUP.md for configuration"
    echo ""
else
    echo -e "${GREEN}✓ Slack Bot Token is configured${NC}"
fi

echo ""
read -p "Ready to insert test command? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Test cancelled"
    exit 0
fi

echo ""
echo -e "${YELLOW}Inserting test command...${NC}"

# Insert command
result=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/claude_commands" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"command\": $(echo "$test_command" | jq -Rs .),
    \"source\": \"progress_test\",
    \"status\": \"pending\",
    \"user_id\": \"TEST_USER\",
    \"slack_channel_id\": \"C12345TEST\",
    \"slack_thread_ts\": \"\"
  }")

command_id=$(echo "$result" | jq -r '.[0].id')

if [ "$command_id" = "null" ] || [ -z "$command_id" ]; then
    echo -e "${RED}✗ Failed to insert command${NC}"
    echo "$result"
    exit 1
fi

echo -e "${GREEN}✓ Command inserted${NC}"
echo "  Command ID: $command_id"
echo ""

echo -e "${YELLOW}Monitoring command execution...${NC}"
echo ""
echo "Expected notification stages in Slack:"
echo "  1️⃣  ⚙️  Command detected (immediately)"
echo "  2️⃣  🔨 Execution starting (1-2s later)"
echo "  3️⃣  ✅ Execution complete (when done)"
echo "  4️⃣  📊 Metrics included"
echo "  5️⃣  Full result from N8n (~15s after completion)"
echo ""

# Monitor for 60 seconds
for i in {1..12}; do
    sleep 5

    # Get current status
    status=$(curl -s "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.$command_id&select=status,response,error_message" \
      -H "apikey: ${SUPABASE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_KEY}" | jq -r '.[0].status')

    elapsed=$((i*5))

    case $status in
        "pending")
            echo -e "[${elapsed}s] ${YELLOW}Status: pending${NC} (waiting for Claude Code to detect)"
            ;;
        "processing")
            echo -e "[${elapsed}s] ${BLUE}Status: processing${NC} (command is executing now!)"
            ;;
        "completed")
            echo -e "[${elapsed}s] ${GREEN}Status: completed${NC} ✓"

            # Get the response
            response=$(curl -s "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.$command_id&select=response" \
              -H "apikey: ${SUPABASE_KEY}" \
              -H "Authorization: Bearer ${SUPABASE_KEY}" | jq -r '.[0].response')

            echo ""
            echo -e "${GREEN}✅ Command completed successfully!${NC}"
            echo ""
            echo "Response:"
            echo "---"
            echo "$response"
            echo "---"
            echo ""
            echo -e "${GREEN}Check Slack for all progress notifications!${NC}"
            echo ""
            echo "Timeline:"
            echo "  • Command inserted: now"
            echo "  • Detected by Claude Code: within 30s"
            echo "  • Execution: depends on command"
            echo "  • Full result posted to Slack: ~15s after completion"
            echo ""
            exit 0
            ;;
        "error")
            echo -e "[${elapsed}s] ${RED}Status: error${NC} ✗"

            # Get the error
            error=$(curl -s "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.$command_id&select=error_message" \
              -H "apikey: ${SUPABASE_KEY}" \
              -H "Authorization: Bearer ${SUPABASE_KEY}" | jq -r '.[0].error_message')

            echo ""
            echo -e "${RED}❌ Command failed${NC}"
            echo ""
            echo "Error:"
            echo "---"
            echo "$error"
            echo "---"
            echo ""
            echo -e "${YELLOW}Check Slack for error notifications!${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo -e "[${elapsed}s] ${RED}Status: unknown ($status)${NC}"
            ;;
    esac
done

echo ""
echo -e "${YELLOW}Monitoring timeout (60 seconds)${NC}"
echo "The command may still be running. Check Slack for updates."
echo ""
echo "To check status manually:"
echo "  curl -s \"${SUPABASE_URL}/rest/v1/claude_commands?id=eq.$command_id\" \\"
echo "    -H \"apikey: ${SUPABASE_KEY}\" | jq ."
echo ""
