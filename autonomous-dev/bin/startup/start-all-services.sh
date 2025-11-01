#!/bin/bash
# Start all Slack automation services

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting Slack Automation Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check which services are already running
CONV_PID=$(pgrep -f claude-conversation-service)
RESP_PID=$(pgrep -f claude-respond-service)
MON_PID=$(pgrep -f slack-message-monitor)
AUTO_PID=$(pgrep -f autonomous-responder)

# Start conversation service
if [ -n "$CONV_PID" ]; then
    echo "✓ Conversation service already running (PID: $CONV_PID)"
else
    ./claude-conversation-service.sh > /tmp/claude-conversation.log 2>&1 &
    echo "✓ Started conversation service (PID: $!)"
fi

# Start response posting service
if [ -n "$RESP_PID" ]; then
    echo "✓ Response posting service already running (PID: $RESP_PID)"
else
    ./claude-respond-service.sh > /tmp/claude-respond.log 2>&1 &
    echo "✓ Started response posting service (PID: $!)"
fi

# Start message monitor
if [ -n "$MON_PID" ]; then
    echo "✓ Message monitor already running (PID: $MON_PID)"
else
    ./slack-message-monitor.sh > /tmp/slack-monitor.log 2>&1 &
    echo "✓ Started message monitor (PID: $!)"
fi

# Start autonomous responder (if API key is set)
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  Autonomous responder NOT started"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "To enable fully autonomous responses, set your Anthropic API key:"
    echo ""
    echo "  export ANTHROPIC_API_KEY='sk-ant-your-key-here'"
    echo "  ./autonomous-responder.sh > /tmp/autonomous-responder.log 2>&1 &"
    echo ""
    echo "Or see AUTONOMOUS-SETUP.md for full instructions"
    echo ""
else
    if [ -n "$AUTO_PID" ]; then
        echo "✓ Autonomous responder already running (PID: $AUTO_PID)"
    else
        ./autonomous-responder.sh > /tmp/autonomous-responder.log 2>&1 &
        echo "✓ Started autonomous responder (PID: $!)"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🎉 FULLY AUTONOMOUS MODE ENABLED!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Your system will now automatically respond to all Slack messages!"
        echo "No manual intervention needed - just send /cc messages and get responses!"
        echo ""
    fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Service startup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "View logs:"
echo "  tail -f /tmp/claude-conversation.log     # Incoming messages"
echo "  tail -f /tmp/claude-respond.log          # Outgoing responses"
echo "  tail -f /tmp/slack-monitor.log           # Message alerts"
echo "  tail -f /tmp/autonomous-responder.log    # Auto-responses"
echo ""
