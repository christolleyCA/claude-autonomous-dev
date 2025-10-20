#!/bin/bash
# Automated monitor for pending Slack messages
# Continuously checks for messages and displays them for Claude to respond to

POLL_INTERVAL=30  # Check every 30 seconds
SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

# Track which messages we've already displayed
SEEN_MESSAGES_FILE="/tmp/.slack-monitor-seen.txt"
touch "$SEEN_MESSAGES_FILE"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔔 Slack Message Monitor"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✨ Monitoring for pending Slack messages..."
echo "🔄 Checking every ${POLL_INTERVAL} seconds"
echo "📢 New messages will be displayed prominently"
echo ""
echo "Press Ctrl+C to stop"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_for_messages() {
    local result=$(curl -s "${SUPABASE_URL}/rest/v1/claude_commands?status=eq.processing&order=created_at.asc" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}")

    local count=$(echo "$result" | jq '. | length' 2>/dev/null || echo "0")

    if [ "$count" -gt 0 ]; then
        # Check for new messages we haven't seen yet
        local new_messages=0

        for i in $(seq 0 $((count - 1))); do
            local message_id=$(echo "$result" | jq -r ".[$i].id")

            # Check if we've already displayed this message
            if ! grep -q "$message_id" "$SEEN_MESSAGES_FILE"; then
                new_messages=$((new_messages + 1))
                echo "$message_id" >> "$SEEN_MESSAGES_FILE"
            fi
        done

        if [ "$new_messages" -gt 0 ]; then
            # Terminal bell to get attention
            echo -e "\a"

            echo ""
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${RED}🚨 NEW SLACK MESSAGE(S) DETECTED! 🚨${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo -e "${YELLOW}📬 Found $new_messages new message(s) waiting for response${NC}"
            echo ""

            # Display each new message
            for i in $(seq 0 $((count - 1))); do
                local message_id=$(echo "$result" | jq -r ".[$i].id")
                local message=$(echo "$result" | jq -r ".[$i].command")
                local created_at=$(echo "$result" | jq -r ".[$i].created_at")
                local user_id=$(echo "$result" | jq -r ".[$i].user_id")

                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo -e "${BLUE}Message #$((i + 1))${NC}"
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
            echo -e "${GREEN}💡 Claude should respond to these messages now!${NC}"
            echo -e "${GREEN}   Responses will automatically post to Slack${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo ""
        fi
    fi
}

# Signal handler for clean shutdown
trap 'echo ""; echo "👋 Stopping Slack Message Monitor"; exit 0' INT TERM

# Main monitoring loop
while true; do
    echo "[$(date '+%H:%M:%S')] Monitoring..."
    check_for_messages
    sleep $POLL_INTERVAL
done
