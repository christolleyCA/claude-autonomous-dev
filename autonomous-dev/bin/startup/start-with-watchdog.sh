#!/bin/bash
# Start Claude Code Remote Access with Auto-Restart Protection
# Starts both the service and its watchdog for crash protection

SCRIPT_DIR="/Users/christophertolleymacbook2019/autonomous-dev"
SERVICE_SCRIPT="start-remote-access.sh"
WATCHDOG_SCRIPT="watchdog.sh"

cd "$SCRIPT_DIR"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting Claude Code Remote Access with Crash Protection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if already running
if pgrep -f "$SERVICE_SCRIPT" > /dev/null; then
    echo "⚠️  Service is already running!"
    echo "   PID: $(pgrep -f "$SERVICE_SCRIPT")"
    echo ""
    echo "To restart:"
    echo "  1. Stop: killall start-remote-access.sh watchdog.sh"
    echo "  2. Run this script again"
    echo ""
    exit 1
fi

# Start the main service
echo "1️⃣  Starting Remote Access Service..."
nohup "./$SERVICE_SCRIPT" > /tmp/remote-access.log 2>&1 &
SERVICE_PID=$!
echo "   ✅ Service started (PID: $SERVICE_PID)"
echo "   📝 Logs: /tmp/remote-access.log"
echo ""

# Wait a moment to ensure service starts
sleep 3

# Verify service started
if ! pgrep -f "$SERVICE_SCRIPT" > /dev/null; then
    echo "   ❌ Service failed to start!"
    echo "   Check logs: tail /tmp/remote-access.log"
    exit 1
fi

# Start the watchdog
echo "2️⃣  Starting Watchdog (Auto-Restart Protection)..."
nohup "./$WATCHDOG_SCRIPT" > /tmp/watchdog.log 2>&1 &
WATCHDOG_PID=$!
echo "   ✅ Watchdog started (PID: $WATCHDOG_PID)"
echo "   📝 Logs: /tmp/watchdog.log"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ System Started Successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 What's Running:"
echo "   • Remote Access Service (PID: $SERVICE_PID)"
echo "   • Watchdog (PID: $WATCHDOG_PID)"
echo ""
echo "🛡️  Crash Protection:"
echo "   • Automatic restart if service crashes"
echo "   • Automatic restart if service freezes"
echo "   • Slack notifications on any issues"
echo "   • Health check every 2 minutes"
echo ""
echo "📊 Monitoring:"
echo "   • Heartbeat: /tmp/claude-remote-access-heartbeat"
echo "   • Service logs: /tmp/remote-access.log"
echo "   • Watchdog logs: /tmp/watchdog.log"
echo "   • Error log: /tmp/remote-access-errors.log"
echo ""
echo "🛑 To Stop Everything:"
echo "   killall start-remote-access.sh watchdog.sh"
echo ""
echo "📱 To Check Status:"
echo "   pgrep -f start-remote-access.sh && echo 'Service: Running' || echo 'Service: Stopped'"
echo "   pgrep -f watchdog.sh && echo 'Watchdog: Running' || echo 'Watchdog: Stopped'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🚀 System is now running with crash protection!"
echo "   Send a test message: /cc test message"
echo ""
