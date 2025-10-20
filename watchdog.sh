#!/bin/bash
# Watchdog - Ensures start-remote-access.sh is always running
# Self-healing auto-restart system

# Load .env if available
[ -f "${BASH_SOURCE[0]%/*}/.env" ] && source "${BASH_SOURCE[0]%/*}/.env"
SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN:-}"
SLACK_CHANNEL="C09M9A33FFF"
SCRIPT_DIR="/Users/christophertolleymacbook2019"
SERVICE_NAME="start-remote-access.sh"
HEARTBEAT_FILE="/tmp/claude-remote-access-heartbeat"
MAX_HEARTBEAT_AGE=180  # 3 minutes

# Send Slack notification
send_slack() {
    local message="$1"
    curl -s -X POST "https://slack.com/api/chat.postMessage" \
        -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"channel\":\"${SLACK_CHANNEL}\",\"text\":\"${message}\"}" \
        > /dev/null 2>&1
}

# Check if service is running
is_service_running() {
    pgrep -f "$SERVICE_NAME" > /dev/null
    return $?
}

# Check if heartbeat is fresh
is_heartbeat_fresh() {
    if [ ! -f "$HEARTBEAT_FILE" ]; then
        return 1
    fi

    local heartbeat=$(cat "$HEARTBEAT_FILE" 2>/dev/null || echo "0")
    local now=$(date +%s)
    local age=$((now - heartbeat))

    if [ $age -gt $MAX_HEARTBEAT_AGE ]; then
        return 1
    fi

    return 0
}

# Restart the service
restart_service() {
    local reason="$1"

    echo "[$(date)] 🔄 Restarting service - Reason: $reason"

    # Kill existing instance
    pkill -f "$SERVICE_NAME" 2>/dev/null
    sleep 2

    # Start new instance
    cd "$SCRIPT_DIR"
    nohup "./$SERVICE_NAME" > /tmp/remote-access.log 2>&1 &

    sleep 5

    # Verify it started
    if is_service_running; then
        echo "[$(date)] ✅ Service restarted successfully"
        send_slack "✅ *Remote Access Service Restarted*

Reason: ${reason}
Time: $(date '+%I:%M %p')
Status: Running normally

The service is self-healing and operational again! 🚀"
        return 0
    else
        echo "[$(date)] ❌ Failed to restart service"
        send_slack "❌ *CRITICAL: Remote Access Service Failed to Restart*

Reason: ${reason}
Time: $(date '+%I:%M %p')
Status: MANUAL INTERVENTION REQUIRED

Please check the logs:
\`tail -50 /tmp/remote-access.log\`

The watchdog will keep trying..."
        return 1
    fi
}

# Main watchdog loop
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐕 Watchdog for Remote Access Service"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Service: $SERVICE_NAME"
echo "Check interval: 2 minutes"
echo "Heartbeat timeout: $MAX_HEARTBEAT_AGE seconds"
echo ""
echo "The service will automatically restart if:"
echo "  • Process crashes or stops"
echo "  • Heartbeat stops updating"
echo "  • Manual restart requested"
echo ""
echo "Press Ctrl+C to stop watchdog"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Send startup notification
send_slack "🐕 *Watchdog Started*

Now monitoring Remote Access Service.
Auto-restart enabled for crash protection.

Status: Watching... 👀"

consecutive_failures=0

while true; do
    echo "[$(date '+%H:%M:%S')] 🔍 Checking service health..."

    # Check if process is running
    if ! is_service_running; then
        echo "   ❌ Process not running"
        restart_service "Process crashed or stopped"
        consecutive_failures=$((consecutive_failures + 1))
    # Check if heartbeat is fresh
    elif ! is_heartbeat_fresh; then
        echo "   ❌ Heartbeat is stale or missing"
        restart_service "Service appears frozen (heartbeat timeout)"
        consecutive_failures=$((consecutive_failures + 1))
    else
        echo "   ✅ Service healthy"
        consecutive_failures=0
    fi

    # Alert if too many consecutive failures
    if [ $consecutive_failures -ge 5 ]; then
        send_slack "🚨 *CRITICAL ALERT*

Remote Access Service has failed to stay running $consecutive_failures times in a row!

This indicates a serious problem that may require investigation.

The watchdog will continue attempting restarts, but please review:
• /tmp/remote-access.log
• /tmp/remote-access-errors.log
• System resources (disk space, memory)

Time: $(date '+%I:%M %p')"

        # Reset counter after alert
        consecutive_failures=0
    fi

    # Wait before next check
    sleep 120  # 2 minutes
done
