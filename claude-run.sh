#!/bin/bash
# Claude Run - Execute commands through Claude Code with Slack notifications
# Even when run from terminal, you'll get real-time Slack updates!

# ============================================================================
# CONFIGURATION
# ============================================================================

# Supabase Configuration
SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

# Default Slack Channel for notifications
# Get your channel ID: Open channel in Slack, click name, scroll to "Channel ID"
# Or use DM channel ID for private notifications
DEFAULT_SLACK_CHANNEL="C09M9A33FFF"  # ⚠️ REPLACE WITH YOUR CHANNEL ID

# ============================================================================
# USAGE CHECK
# ============================================================================

if [ $# -eq 0 ]; then
    echo "🚀 Claude Run - Execute commands with Slack notifications"
    echo ""
    echo "Usage:"
    echo "  $0 <command>"
    echo ""
    echo "Examples:"
    echo "  $0 pwd"
    echo "  $0 ls -la"
    echo "  $0 'echo \"Hello World\"'"
    echo "  $0 npm test"
    echo "  $0 git status"
    echo ""
    echo "Features:"
    echo "  ✅ Real-time progress updates sent to Slack"
    echo "  ✅ Execution metrics (duration, exit code, output size)"
    echo "  ✅ Error notifications"
    echo "  ✅ Complete command history in database"
    echo ""
    echo "Configuration:"
    echo "  Default Slack Channel: $DEFAULT_SLACK_CHANNEL"
    echo "  Supabase URL: $SUPABASE_URL"
    echo ""
    echo "Setup:"
    echo "  1. Make sure start-remote-access.sh is running"
    echo "  2. Configure DEFAULT_SLACK_CHANNEL in this script"
    echo "  3. Configure SLACK_BOT_TOKEN in start-remote-access.sh"
    echo ""
    exit 1
fi

# ============================================================================
# COMMAND SUBMISSION
# ============================================================================

# Get the full command
COMMAND="$*"

# Get hostname for context
HOSTNAME=$(hostname -s)
USERNAME=$(whoami)

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Claude Run - Submitting Command${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}Command:${NC} $COMMAND"
echo -e "${YELLOW}User:${NC} $USERNAME@$HOSTNAME"
echo -e "${YELLOW}Slack Channel:${NC} $DEFAULT_SLACK_CHANNEL"
echo ""

# Check if start-remote-access.sh is running
if ! pgrep -f "start-remote-access.sh" > /dev/null; then
    echo -e "${YELLOW}⚠️  WARNING: Claude Code polling service is not running${NC}"
    echo ""
    echo "The command will be queued, but won't execute until you start the service:"
    echo "  cd /Users/christophertolleymacbook2019"
    echo "  ./start-remote-access.sh"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled"
        exit 1
    fi
fi

# Insert command into Supabase
echo -e "${BLUE}📤 Submitting to Claude Code...${NC}"

result=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/claude_commands" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"command\": $(echo "$COMMAND" | jq -Rs .),
    \"source\": \"terminal\",
    \"status\": \"pending\",
    \"user_id\": \"${USERNAME}@${HOSTNAME}\",
    \"slack_channel_id\": \"${DEFAULT_SLACK_CHANNEL}\",
    \"slack_thread_ts\": null
  }")

# Check if successful
command_id=$(echo "$result" | jq -r '.[0].id // empty')

if [ -z "$command_id" ]; then
    echo -e "${RED}❌ Failed to submit command${NC}"
    echo ""
    echo "Error response:"
    echo "$result" | jq .
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check Supabase URL and API key"
    echo "  2. Verify database table exists: claude_commands"
    echo "  3. Check network connectivity"
    exit 1
fi

echo -e "${GREEN}✅ Command submitted successfully!${NC}"
echo ""
echo "Command ID: $command_id"
echo ""
echo -e "${YELLOW}📱 Slack Notifications:${NC}"
echo "  Channel: $DEFAULT_SLACK_CHANNEL"
echo "  You'll receive updates at these stages:"
echo "    1️⃣  💻 Command detected (within 30s)"
echo "    2️⃣  🔨 Execution starting"
echo "    3️⃣  ✅ Execution complete with metrics"
echo "    4️⃣  📊 Full result posted"
echo ""
echo -e "${YELLOW}⏱️  Timeline:${NC}"
echo "  • Detection: 0-30 seconds (polling interval)"
echo "  • Execution: depends on command"
echo "  • Final result: ~15 seconds after completion"
echo "  • Total: typically 45-60 seconds"
echo ""
echo -e "${YELLOW}📊 Monitor Progress:${NC}"
echo "  • Check Slack channel: $DEFAULT_SLACK_CHANNEL"
echo "  • Check database:"
echo "    curl -s \"${SUPABASE_URL}/rest/v1/claude_commands?id=eq.${command_id}\" \\"
echo "      -H \"apikey: ${SUPABASE_KEY}\" | jq ."
echo ""

# Offer to monitor
read -p "Monitor execution in terminal? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${BLUE}🔍 Monitoring execution (60 seconds)...${NC}"
    echo ""

    for i in {1..12}; do
        sleep 5

        status=$(curl -s "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.$command_id&select=status,response,error_message" \
          -H "apikey: ${SUPABASE_KEY}" \
          -H "Authorization: Bearer ${SUPABASE_KEY}" | jq -r '.[0].status // "unknown"')

        elapsed=$((i*5))

        case $status in
            "pending")
                echo -e "[${elapsed}s] ${YELLOW}⏳ Status: pending${NC} (waiting for detection)"
                ;;
            "processing")
                echo -e "[${elapsed}s] ${BLUE}⚙️  Status: processing${NC} (executing now!)"
                ;;
            "completed")
                response=$(curl -s "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.$command_id&select=response" \
                  -H "apikey: ${SUPABASE_KEY}" \
                  -H "Authorization: Bearer ${SUPABASE_KEY}" | jq -r '.[0].response // ""')

                echo -e "[${elapsed}s] ${GREEN}✅ Status: completed${NC}"
                echo ""
                echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${GREEN}✅ COMMAND COMPLETED SUCCESSFULLY!${NC}"
                echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo ""
                echo "Response:"
                echo "---"
                echo "$response"
                echo "---"
                echo ""
                echo -e "${GREEN}✅ Check Slack for complete results and metrics!${NC}"
                exit 0
                ;;
            "error")
                error_msg=$(curl -s "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.$command_id&select=error_message" \
                  -H "apikey: ${SUPABASE_KEY}" \
                  -H "Authorization: Bearer ${SUPABASE_KEY}" | jq -r '.[0].error_message // ""')

                echo -e "[${elapsed}s] ${RED}❌ Status: error${NC}"
                echo ""
                echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${RED}❌ COMMAND FAILED${NC}"
                echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo ""
                echo "Error:"
                echo "---"
                echo "$error_msg"
                echo "---"
                echo ""
                echo -e "${YELLOW}Check Slack for detailed error information${NC}"
                exit 1
                ;;
            *)
                echo -e "[${elapsed}s] ${RED}❓ Status: $status${NC}"
                ;;
        esac
    done

    echo ""
    echo -e "${YELLOW}⏱️  Monitoring timeout (60 seconds)${NC}"
    echo "Command may still be running. Check Slack for updates."
else
    echo ""
    echo -e "${GREEN}✅ Command submitted! Check Slack for updates.${NC}"
fi

echo ""
