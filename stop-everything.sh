#!/bin/bash
# ============================================================================
# STOP ALL SERVICES - Graceful Shutdown
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🛑 STOPPING ALL SERVICES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Stop remote access service
echo "Stopping remote access service..."
if pkill -f "start-remote-access.sh"; then
    echo "✓ Remote access stopped"
else
    echo "⚠️  Remote access was not running"
fi

# Stop watchdog
echo "Stopping watchdog service..."
if pkill -f "watchdog.sh"; then
    echo "✓ Watchdog stopped"
else
    echo "⚠️  Watchdog was not running"
fi

# Stop any background polling scripts
echo "Stopping background processes..."
pkill -f "start-with-watchdog.sh" 2>/dev/null && echo "✓ Startup script stopped"

# Wait a moment for graceful shutdown
sleep 2

# Verify everything stopped
echo ""
echo "Verifying shutdown..."
local still_running=0

if pgrep -f "start-remote-access.sh" > /dev/null; then
    echo "⚠️  Remote access still running - forcing stop"
    pkill -9 -f "start-remote-access.sh"
    ((still_running++))
fi

if pgrep -f "watchdog.sh" > /dev/null; then
    echo "⚠️  Watchdog still running - forcing stop"
    pkill -9 -f "watchdog.sh"
    ((still_running++))
fi

echo ""
if [ "$still_running" -eq 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ ALL SERVICES STOPPED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  SOME SERVICES REQUIRED FORCE STOP"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

echo ""
echo "💡 To restart: ./start-everything.sh"
echo ""
