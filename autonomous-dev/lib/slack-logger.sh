#!/bin/bash
# Slack Logger - Send messages from Claude Code to Slack
# Source this file to use the logging functions

# ============================================================================
# CONFIGURATION
# ============================================================================

# Slack Bot Token (get from: https://api.slack.com/apps → OAuth & Permissions)
SLACK_TOKEN="${SLACK_BOT_TOKEN:-YOUR_SLACK_BOT_TOKEN_HERE}"

# Default channel for conversation logs
# Get channel ID: Open channel → Click name → "Channel ID"
# Or use DM channel ID for private logging
DEFAULT_LOG_CHANNEL="${DEFAULT_SLACK_CHANNEL:-C09M9A33FFF}"

# Log file for local backup
LOG_FILE="/tmp/claude-code-slack-log.txt"

# Rate limiting
LAST_SEND_TIME=0
MIN_SEND_INTERVAL=1  # Minimum 1 second between messages

# ============================================================================
# CORE FUNCTIONS
# ============================================================================

# Send message to Slack
send_to_slack() {
    local message="$1"
    local channel="${2:-$DEFAULT_LOG_CHANNEL}"

    # Skip if no token configured
    if [ "$SLACK_TOKEN" = "YOUR_SLACK_BOT_TOKEN_HERE" ]; then
        echo "[SLACK] Token not configured - message skipped" >&2
        return 0
    fi

    # Skip if channel not configured
    if [ -z "$channel" ] || [ "$channel" = "C09M9A33FFF" ]; then
        echo "[SLACK] Channel not configured - message skipped" >&2
        return 0
    fi

    # Rate limiting
    local current_time=$(date +%s)
    local time_diff=$((current_time - LAST_SEND_TIME))
    if [ $time_diff -lt $MIN_SEND_INTERVAL ]; then
        sleep $((MIN_SEND_INTERVAL - time_diff))
    fi
    LAST_SEND_TIME=$(date +%s)

    # Escape message for JSON
    local escaped_message=$(echo "$message" | jq -Rs .)

    # Send to Slack
    local response=$(curl -s -X POST "https://slack.com/api/chat.postMessage" \
        -H "Authorization: Bearer ${SLACK_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{
            \"channel\": \"${channel}\",
            \"text\": ${escaped_message},
            \"mrkdwn\": true
        }")

    # Check if successful
    local ok=$(echo "$response" | jq -r '.ok // false')
    if [ "$ok" != "true" ]; then
        local error=$(echo "$response" | jq -r '.error // "unknown"')
        echo "[SLACK] Failed to send: $error" >&2
        return 1
    fi

    return 0
}

# Log to both file and Slack
log_and_send() {
    local message="$1"
    local channel="${2:-$DEFAULT_LOG_CHANNEL}"

    # Log to file
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"

    # Send to Slack
    send_to_slack "$message" "$channel"
}

# Send code block to Slack
send_code_block() {
    local code="$1"
    local language="${2:-}"
    local channel="${3:-$DEFAULT_LOG_CHANNEL}"

    if [ -n "$language" ]; then
        send_to_slack "\`\`\`${language}\n${code}\n\`\`\`" "$channel"
    else
        send_to_slack "\`\`\`${code}\`\`\`" "$channel"
    fi
}

# Send formatted event notification
send_event() {
    local event_type="$1"
    local message="$2"
    local channel="${3:-$DEFAULT_LOG_CHANNEL}"

    local emoji
    local prefix

    case "$event_type" in
        "start")
            emoji="🏁"
            prefix="Started"
            ;;
        "progress")
            emoji="⚙️"
            prefix="Progress"
            ;;
        "complete")
            emoji="✅"
            prefix="Complete"
            ;;
        "error")
            emoji="❌"
            prefix="Error"
            ;;
        "warning")
            emoji="⚠️"
            prefix="Warning"
            ;;
        "info")
            emoji="ℹ️"
            prefix="Info"
            ;;
        "file_created")
            emoji="📝"
            prefix="File Created"
            ;;
        "file_updated")
            emoji="✏️"
            prefix="File Updated"
            ;;
        "test")
            emoji="🧪"
            prefix="Test"
            ;;
        "build")
            emoji="🔨"
            prefix="Build"
            ;;
        "deploy")
            emoji="🚀"
            prefix="Deploy"
            ;;
        *)
            emoji="•"
            prefix="$event_type"
            ;;
    esac

    send_to_slack "${emoji} *${prefix}:* ${message}" "$channel"
}

# Send session start notification
notify_session_start() {
    local session_name="${1:-Claude Code Session}"
    local channel="${2:-$DEFAULT_LOG_CHANNEL}"

    send_to_slack "🚀 *${session_name} Started*
Started at: $(date '+%I:%M %p %Z')
Hostname: $(hostname -s)
User: $(whoami)
Directory: $(pwd)" "$channel"
}

# Send session end notification
notify_session_end() {
    local session_name="${1:-Claude Code Session}"
    local start_time="${2:-}"
    local channel="${3:-$DEFAULT_LOG_CHANNEL}"

    local message="🛑 *${session_name} Ended*
Ended at: $(date '+%I:%M %p %Z')"

    if [ -n "$start_time" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local minutes=$((duration / 60))
        local seconds=$((duration % 60))
        message="${message}
Duration: ${minutes}m ${seconds}s"
    fi

    send_to_slack "$message" "$channel"
}

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

export -f send_to_slack
export -f log_and_send
export -f send_code_block
export -f send_event
export -f notify_session_start
export -f notify_session_end

# ============================================================================
# INITIALIZATION
# ============================================================================

# Create log file if it doesn't exist
touch "$LOG_FILE" 2>/dev/null || true

# Show status
if [ "$SLACK_TOKEN" = "YOUR_SLACK_BOT_TOKEN_HERE" ]; then
    echo "[SLACK LOGGER] ⚠️  Token not configured - Slack logging disabled" >&2
elif [ "$DEFAULT_LOG_CHANNEL" = "C09M9A33FFF" ]; then
    echo "[SLACK LOGGER] ⚠️  Channel not configured - Slack logging disabled" >&2
else
    echo "[SLACK LOGGER] ✅ Initialized - Logging to $DEFAULT_LOG_CHANNEL" >&2
fi
