#!/bin/bash
# System Verification Script
# Checks that all components are properly configured and ready to use

echo "🔍 Claude Code Remote Access & Monitoring - System Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Check function
check_file() {
    local file=$1
    local description=$2

    if [ -f "$file" ]; then
        if [ -x "$file" ]; then
            echo -e "${GREEN}✅${NC} $description - Found and executable"
        else
            echo -e "${YELLOW}⚠️${NC}  $description - Found but not executable"
            echo "   Fix: chmod +x $file"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo -e "${RED}❌${NC} $description - NOT FOUND"
        ERRORS=$((ERRORS + 1))
    fi
}

check_config() {
    local file=$1
    local line_num=$2
    local pattern=$3
    local description=$4

    if [ -f "$file" ]; then
        if grep -q "$pattern" "$file"; then
            echo -e "${YELLOW}⚠️${NC}  $description - NOT CONFIGURED"
            echo "   Fix: Edit $file line $line_num"
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "${GREEN}✅${NC} $description - Configured"
        fi
    fi
}

check_process() {
    local process_name=$1
    local description=$2

    if pgrep -f "$process_name" > /dev/null; then
        echo -e "${GREEN}✅${NC} $description - Running"
    else
        echo -e "${YELLOW}⚠️${NC}  $description - Not running"
        echo "   To start: ./$process_name &"
        WARNINGS=$((WARNINGS + 1))
    fi
}

echo "📋 Checking Remote Access Scripts..."
echo ""
check_file "start-remote-access.sh" "Main polling service"
check_file "claude-poll-commands.sh" "Command fetcher"
check_file "claude-run.sh" "Terminal command wrapper"
check_file "insert-test-command.sh" "Test script"
check_file "test-progress-updates.sh" "Progress update tester"

echo ""
echo "📋 Checking Conversation Mirroring Scripts..."
echo ""
check_file "slack-logger.sh" "Core notification library"
check_file "claude-with-slack.sh" "Full session mirroring"
check_file "claude-summary.sh" "Smart event detection"
check_file "claude-ping.sh" "Manual notifications"

echo ""
echo "📋 Checking Configuration..."
echo ""
check_config "slack-logger.sh" "11" "YOUR_SLACK_BOT_TOKEN_HERE" "Slack token (slack-logger.sh)"
check_config "slack-logger.sh" "16" "C09M9A33FFF" "Default channel (slack-logger.sh)"
check_config "start-remote-access.sh" "10" "YOUR_SLACK_BOT_TOKEN_HERE" "Slack token (start-remote-access.sh)"

echo ""
echo "📋 Checking Running Services..."
echo ""
check_process "start-remote-access.sh" "Remote access polling service"

echo ""
echo "📋 Checking Documentation..."
echo ""
check_file "COMPLETE-SYSTEM-OVERVIEW.md" "System overview"
check_file "REMOTE-ACCESS-SETUP.md" "Remote access setup"
check_file "SLACK-BOT-TOKEN-SETUP.md" "Token setup guide"
check_file "PROGRESS-UPDATES-README.md" "Progress updates guide"
check_file "TERMINAL-COMMANDS-README.md" "Terminal commands quick start"
check_file "TERMINAL-COMMANDS-GUIDE.md" "Terminal commands guide"
check_file "CONVERSATION-MIRRORING-README.md" "Mirroring quick start"
check_file "CONVERSATION-MIRRORING-GUIDE.md" "Mirroring guide"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 System fully operational! Everything is ready to use.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Configure Slack tokens (see warnings above if any)"
    echo "2. Start polling service: ./start-remote-access.sh &"
    echo "3. Test remote execution: Send '/cc echo test' in Slack"
    echo "4. Try conversation mirroring: ./claude-with-slack.sh"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  System operational with $WARNINGS warning(s).${NC}"
    echo ""
    echo "Please address the warnings above for full functionality."
    echo "Most warnings are configuration-related and easy to fix."
else
    echo -e "${RED}❌ System has $ERRORS error(s) and $WARNINGS warning(s).${NC}"
    echo ""
    echo "Please fix the errors above before using the system."
fi

echo ""
echo "📚 Documentation: Read COMPLETE-SYSTEM-OVERVIEW.md for full details"
echo ""

exit $ERRORS
