#!/bin/bash
# ============================================================================
# MASTER STARTUP SCRIPT - Launch Entire Autonomous Development System
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 STARTING AUTONOMOUS DEVELOPMENT SYSTEM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Change to script directory
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# Check prerequisites
echo "✓ Checking prerequisites..."

if ! command -v git &> /dev/null; then
    echo "❌ Git not found - install git first"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "⚠️  jq not found (recommended for JSON parsing)"
fi

if ! command -v curl &> /dev/null; then
    echo "❌ curl not found - required for API calls"
    exit 1
fi

echo "✓ Prerequisites OK"
echo ""

# Start services
echo "📋 Starting services..."
echo ""

# 1. Start remote access polling with watchdog
echo "1️⃣ Starting remote access service with watchdog..."
if pgrep -f "start-with-watchdog.sh" > /dev/null; then
    echo "   ✓ Already running (PID: $(pgrep -f start-with-watchdog.sh))"
else
    if [ -f "./start-with-watchdog.sh" ]; then
        nohup ./start-with-watchdog.sh > /tmp/remote-access-startup.log 2>&1 &
        sleep 3
        if pgrep -f "start-with-watchdog.sh" > /dev/null; then
            echo "   ✓ Started (PID: $(pgrep -f start-with-watchdog.sh))"
        else
            echo "   ❌ Failed to start - check /tmp/remote-access-startup.log"
        fi
    else
        echo "   ❌ start-with-watchdog.sh not found"
    fi
fi

echo ""
echo "🔍 System Status Check..."
echo ""

# 2. Check Git status
echo "2️⃣ Checking Git repository..."
if git status &> /dev/null; then
    echo "   ✓ Git repository OK"
    echo "   Branch: $(git branch --show-current)"
    echo "   Last commit: $(git log -1 --pretty=format:'%h - %s (%cr)' 2>/dev/null || echo 'N/A')"
else
    echo "   ⚠️  Not a git repository"
fi

# 3. Check heartbeat file
echo "3️⃣ Checking service heartbeat..."
if [ -f "/tmp/claude-remote-access-heartbeat" ]; then
    local last_heartbeat=$(cat /tmp/claude-remote-access-heartbeat)
    local current_time=$(date +%s)
    local age=$((current_time - last_heartbeat))

    if [ "$age" -lt 120 ]; then
        echo "   ✓ Service is healthy (heartbeat ${age}s ago)"
    else
        echo "   ⚠️  Service may be stuck (heartbeat ${age}s ago)"
    fi
else
    echo "   ⚠️  Heartbeat file not found (service may not have started yet)"
fi

# 4. Check for running processes
echo "4️⃣ Checking running processes..."
local polling_count=$(pgrep -cf "start-remote-access.sh" || echo "0")
local watchdog_count=$(pgrep -cf "watchdog.sh" || echo "0")

echo "   Polling services: $polling_count"
echo "   Watchdog services: $watchdog_count"

# 5. Check disk space
echo "5️⃣ Checking disk space..."
local disk_usage=$(df -h . | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$disk_usage" -lt 90 ]; then
    echo "   ✓ Disk space OK (${disk_usage}% used)"
else
    echo "   ⚠️  Disk space low (${disk_usage}% used)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ SYSTEM READY!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 Remote Access:"
echo "   Test with: /cc echo \"Hello from Slack!\""
echo "   Status: /cc system-status"
echo ""
echo "🔨 Build Features:"
echo "   Use: /cc build-feature <name> \"description\""
echo ""
echo "🛑 To Stop Everything:"
echo "   Run: ./stop-everything.sh"
echo ""
echo "📝 View Logs:"
echo "   Startup: tail -f /tmp/remote-access-startup.log"
echo "   Commands: tail -f /tmp/command-execution-*.log"
echo ""
echo "💡 Quick Commands:"
echo "   ./view-solutions.sh stats    # View knowledge base"
echo "   git status                   # Check git status"
echo "   ./map-codebase.sh            # Map your codebase"
echo ""
echo "📖 Documentation:"
echo "   cat GETTING-STARTED.md       # Complete startup guide"
echo "   cat QUICK-REFERENCE.txt      # Command reference"
echo ""
