#!/bin/bash
# Claude Code Smart Summarizer
# Send periodic summaries and immediate alerts for important events

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/slack-logger.sh"

# Summary interval in seconds
SUMMARY_INTERVAL=300  # 5 minutes

# Session log file
SESSION_LOG="/tmp/claude-session-$(date +%s).log"

# Event detection patterns
PATTERNS_FILE_CREATED="created|Created|CREATE|new file|wrote"
PATTERNS_FILE_UPDATED="updated|Updated|UPDATE|modified|edited"
PATTERNS_ERROR="error|Error|ERROR|failed|Failed|FAILED"
PATTERNS_WARNING="warning|Warning|WARN"
PATTERNS_SUCCESS="success|Success|SUCCESS|completed|Completed|passed"
PATTERNS_TEST="test|Test|TEST|spec|Spec"
PATTERNS_BUILD="build|Build|BUILD|compile|Compile"
PATTERNS_DEPLOY="deploy|Deploy|DEPLOY|release|Release"

# ============================================================================
# EVENT DETECTION
# ============================================================================

detect_and_notify() {
    local line="$1"
    local channel="${2:-$DEFAULT_LOG_CHANNEL}"

    # File created
    if echo "$line" | grep -qiE "$PATTERNS_FILE_CREATED"; then
        if echo "$line" | grep -qE "\.(ts|js|json|md|sh|py|sql)"; then
            send_event "file_created" "$line" "$channel"
            return 0
        fi
    fi

    # File updated
    if echo "$line" | grep -qiE "$PATTERNS_FILE_UPDATED"; then
        if echo "$line" | grep -qE "\.(ts|js|json|md|sh|py|sql)"; then
            send_event "file_updated" "$line" "$channel"
            return 0
        fi
    fi

    # Errors (high priority)
    if echo "$line" | grep -qiE "$PATTERNS_ERROR"; then
        send_event "error" "$line" "$channel"
        return 0
    fi

    # Warnings
    if echo "$line" | grep -qiE "$PATTERNS_WARNING"; then
        send_event "warning" "$line" "$channel"
        return 0
    fi

    # Success
    if echo "$line" | grep -qiE "$PATTERNS_SUCCESS"; then
        send_event "complete" "$line" "$channel"
        return 0
    fi

    # Tests
    if echo "$line" | grep -qiE "$PATTERNS_TEST"; then
        send_event "test" "$line" "$channel"
        return 0
    fi

    # Build
    if echo "$line" | grep -qiE "$PATTERNS_BUILD"; then
        send_event "build" "$line" "$channel"
        return 0
    fi

    # Deploy
    if echo "$line" | grep -qiE "$PATTERNS_DEPLOY"; then
        send_event "deploy" "$line" "$channel"
        return 0
    fi

    return 1
}

# ============================================================================
# MONITORING FUNCTIONS
# ============================================================================

monitor_session() {
    local channel="${1:-$DEFAULT_LOG_CHANNEL}"

    echo "[MONITOR] Starting smart summarizer..." >&2
    echo "[MONITOR] Important events will be sent immediately" >&2
    echo "[MONITOR] Summaries every $SUMMARY_INTERVAL seconds" >&2

    # Monitor stdin
    while IFS= read -r line || [ -n "$line" ]; do
        # Show in terminal
        echo "$line"

        # Log to session file
        echo "$line" >> "$SESSION_LOG"

        # Detect and notify important events
        detect_and_notify "$line" "$channel"
    done
}

send_periodic_summaries() {
    local channel="${1:-$DEFAULT_LOG_CHANNEL}"
    local summary_count=0

    while true; do
        sleep $SUMMARY_INTERVAL

        if [ -f "$SESSION_LOG" ]; then
            summary_count=$((summary_count + 1))

            # Get recent activity
            local recent=$(tail -20 "$SESSION_LOG")
            local line_count=$(wc -l < "$SESSION_LOG")

            # Create summary
            local summary="📊 *Summary #${summary_count}* (${SUMMARY_INTERVAL}s interval)
Total lines logged: ${line_count}

*Recent activity (last 20 lines):*
\`\`\`
${recent}
\`\`\`"

            send_to_slack "$summary" "$channel"
        fi
    done
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    local channel="${1:-$DEFAULT_LOG_CHANNEL}"

    # Check configuration
    if [ "$SLACK_TOKEN" = "YOUR_SLACK_BOT_TOKEN_HERE" ]; then
        echo "❌ Slack bot token not configured!" >&2
        exit 1
    fi

    # Create session log
    touch "$SESSION_LOG"

    # Notify start
    notify_session_start "Claude Code Smart Monitor" "$channel"

    # Start periodic summary sender in background
    send_periodic_summaries "$channel" &
    SUMMARY_PID=$!

    # Trap exit
    trap "kill $SUMMARY_PID 2>/dev/null; notify_session_end 'Claude Code Smart Monitor' '' '$channel'; exit 0" INT TERM

    # Monitor session
    monitor_session "$channel"

    # Cleanup
    kill $SUMMARY_PID 2>/dev/null
    notify_session_end "Claude Code Smart Monitor" "" "$channel"
}

# Usage
if [ $# -eq 0 ]; then
    echo "Usage: $0 [channel_id]"
    echo ""
    echo "Pipe Claude Code output through this script:"
    echo "  claude 2>&1 | $0"
    echo "  claude 2>&1 | $0 C1234567890"
    echo ""
    echo "Or source and use functions:"
    echo "  source $0"
    echo "  echo 'output' | monitor_session"
    exit 0
fi

# If sourced, don't run main
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
