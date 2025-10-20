#!/bin/bash
# Claude Ping - Simple manual notification system
# Use this to send notifications at specific points in your workflow

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/slack-logger.sh"

# ============================================================================
# NOTIFICATION FUNCTION
# ============================================================================

claude_notify() {
    local event_type="$1"
    local message="$2"
    local channel="${3:-$DEFAULT_LOG_CHANNEL}"

    if [ -z "$message" ]; then
        echo "Usage: claude_notify <event_type> <message> [channel]"
        echo ""
        echo "Event types:"
        echo "  start      - 🏁 Task started"
        echo "  progress   - ⚙️  Progress update"
        echo "  complete   - ✅ Task completed"
        echo "  error      - ❌ Error occurred"
        echo "  warning    - ⚠️  Warning"
        echo "  info       - ℹ️  Information"
        echo "  file       - 📝 File operation"
        echo "  test       - 🧪 Test"
        echo "  build      - 🔨 Build"
        echo "  deploy     - 🚀 Deploy"
        echo ""
        echo "Examples:"
        echo "  claude_notify start 'Building email feature'"
        echo "  claude_notify progress 'Created database migration'"
        echo "  claude_notify complete 'Email feature ready for review'"
        echo "  claude_notify error 'Database connection failed'"
        return 1
    fi

    send_event "$event_type" "$message" "$channel"
}

# Convenience aliases
claude_start() {
    claude_notify "start" "$1" "${2:-$DEFAULT_LOG_CHANNEL}"
}

claude_progress() {
    claude_notify "progress" "$1" "${2:-$DEFAULT_LOG_CHANNEL}"
}

claude_complete() {
    claude_notify "complete" "$1" "${2:-$DEFAULT_LOG_CHANNEL}"
}

claude_error() {
    claude_notify "error" "$1" "${2:-$DEFAULT_LOG_CHANNEL}"
}

claude_warning() {
    claude_notify "warning" "$1" "${2:-$DEFAULT_LOG_CHANNEL}"
}

claude_info() {
    claude_notify "info" "$1" "${2:-$DEFAULT_LOG_CHANNEL}"
}

# Task tracking
claude_task_start() {
    local task_name="$1"
    local task_file="/tmp/claude-task-$(echo "$task_name" | tr ' ' '-').start"
    echo "$(date +%s)" > "$task_file"
    claude_notify "start" "$task_name"
}

claude_task_complete() {
    local task_name="$1"
    local task_file="/tmp/claude-task-$(echo "$task_name" | tr ' ' '-').start"

    if [ -f "$task_file" ]; then
        local start_time=$(cat "$task_file")
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local minutes=$((duration / 60))
        local seconds=$((duration % 60))

        claude_notify "complete" "$task_name (Duration: ${minutes}m ${seconds}s)"
        rm "$task_file"
    else
        claude_notify "complete" "$task_name"
    fi
}

# Export functions
export -f claude_notify
export -f claude_start
export -f claude_progress
export -f claude_complete
export -f claude_error
export -f claude_warning
export -f claude_info
export -f claude_task_start
export -f claude_task_complete

# ============================================================================
# CLI MODE
# ============================================================================

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Called as script
    if [ $# -lt 2 ]; then
        echo "Claude Ping - Manual Notification System"
        echo ""
        echo "Usage: $0 <event_type> <message> [channel]"
        echo ""
        echo "Event types:"
        echo "  start, progress, complete, error, warning, info"
        echo "  file, test, build, deploy"
        echo ""
        echo "Examples:"
        echo "  $0 start 'Building email feature'"
        echo "  $0 progress 'Completed step 1 of 3'"
        echo "  $0 complete 'All tests passing'"
        echo ""
        echo "Or source this file and use functions:"
        echo "  source $0"
        echo "  claude_notify start 'Building feature'"
        echo "  claude_progress 'Step 1 done'"
        echo "  claude_complete 'Feature ready'"
        echo ""
        echo "Task tracking:"
        echo "  claude_task_start 'Build email system'"
        echo "  # ... do work ..."
        echo "  claude_task_complete 'Build email system'"
        echo "  # Shows duration automatically"
        exit 1
    fi

    claude_notify "$@"
fi
