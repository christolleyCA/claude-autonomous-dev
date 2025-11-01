#!/bin/bash
# Easy setup script for autonomous responder

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 Autonomous Slack Responder Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if API key is provided as argument
if [ -n "$1" ]; then
    ANTHROPIC_API_KEY="$1"
else
    # Prompt for API key
    echo "Please paste your Anthropic API key (starts with sk-ant-):"
    read -r ANTHROPIC_API_KEY
fi

# Validate key format
if [[ ! "$ANTHROPIC_API_KEY" =~ ^sk-ant- ]]; then
    echo ""
    echo "❌ Error: Invalid API key format"
    echo "   API keys should start with 'sk-ant-'"
    echo ""
    exit 1
fi

echo ""
echo "✅ API key validated"
echo ""

# Add to shell profile for persistence
SHELL_RC="${HOME}/.zshrc"
if [ -f "${HOME}/.bashrc" ]; then
    SHELL_RC="${HOME}/.bashrc"
fi

# Check if already exists
if grep -q "ANTHROPIC_API_KEY" "$SHELL_RC" 2>/dev/null; then
    echo "⚠️  API key already exists in $SHELL_RC"
    echo "   Updating it..."
    # Remove old line and add new one
    grep -v "ANTHROPIC_API_KEY" "$SHELL_RC" > "${SHELL_RC}.tmp"
    echo "export ANTHROPIC_API_KEY=\"${ANTHROPIC_API_KEY}\"" >> "${SHELL_RC}.tmp"
    mv "${SHELL_RC}.tmp" "$SHELL_RC"
else
    echo "📝 Adding API key to $SHELL_RC"
    echo "" >> "$SHELL_RC"
    echo "# Anthropic API Key for Slack Autonomous Responder" >> "$SHELL_RC"
    echo "export ANTHROPIC_API_KEY=\"${ANTHROPIC_API_KEY}\"" >> "$SHELL_RC"
fi

# Export for current session
export ANTHROPIC_API_KEY

echo "✅ API key saved to $SHELL_RC"
echo ""

# Check if autonomous responder is already running
AUTO_PID=$(pgrep -f autonomous-responder)
if [ -n "$AUTO_PID" ]; then
    echo "⚠️  Autonomous responder already running (PID: $AUTO_PID)"
    echo "   Stopping it to restart with new key..."
    pkill -f autonomous-responder
    sleep 1
fi

# Start autonomous responder
echo "🚀 Starting autonomous responder..."
echo ""

./autonomous-responder.sh > /tmp/autonomous-responder.log 2>&1 &
NEW_PID=$!

sleep 2

# Verify it's running
if ps -p $NEW_PID > /dev/null 2>&1; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ SUCCESS! Autonomous responder is running (PID: $NEW_PID)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🎉 Your system is now FULLY AUTONOMOUS!"
    echo ""
    echo "What happens next:"
    echo "  1. You send /cc message from Slack"
    echo "  2. Message detected within 15 seconds"
    echo "  3. Claude API generates response automatically"
    echo "  4. Response posted to Slack within 15 seconds"
    echo "  5. NO MANUAL INTERVENTION NEEDED!"
    echo ""
    echo "View the log:"
    echo "  tail -f /tmp/autonomous-responder.log"
    echo ""
    echo "Test it now:"
    echo "  Send '/cc tell me a joke' from Slack"
    echo "  Wait ~30 seconds for automatic response!"
    echo ""
else
    echo "❌ Failed to start autonomous responder"
    echo "   Check the log: tail /tmp/autonomous-responder.log"
    exit 1
fi
