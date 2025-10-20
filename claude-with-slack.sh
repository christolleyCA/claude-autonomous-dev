#!/bin/bash
# Claude Code with Slack Mirroring
# Wrapper to run Claude Code with all output sent to Slack

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/slack-logger.sh"

# Buffer settings
BUFFER_SIZE=2000          # Slack message size limit (characters)
PARAGRAPH_BREAK_LINES=2   # Number of blank lines = paragraph break
BUFFER_TIMEOUT=5          # Send buffer after 5 seconds of inactivity

# ============================================================================
# USAGE CHECK
# ============================================================================

show_usage() {
    echo "Claude Code with Slack Mirroring"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -c, --channel ID    Slack channel ID for mirroring"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Configuration:"
    echo "  Edit slack-logger.sh to set:"
    echo "    SLACK_TOKEN          Your Slack bot token"
    echo "    DEFAULT_LOG_CHANNEL  Default channel ID"
    echo ""
    echo "Example:"
    echo "  $0"
    echo "  $0 --channel C1234567890"
    echo ""
    exit 0
}

# Parse arguments
MIRROR_CHANNEL="$DEFAULT_LOG_CHANNEL"
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--channel)
            MIRROR_CHANNEL="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            ;;
    esac
done

# ============================================================================
# MIRRORING FUNCTION
# ============================================================================

mirror_to_slack() {
    local buffer=""
    local blank_line_count=0
    local last_activity=$(date +%s)

    echo "[MIRROR] Starting Slack mirroring to $MIRROR_CHANNEL..." >&2

    while IFS= read -r line || [ -n "$line" ]; do
        # Show in terminal
        echo "$line"

        # Track blank lines for paragraph detection
        if [ -z "$line" ]; then
            blank_line_count=$((blank_line_count + 1))
        else
            blank_line_count=0
        fi

        # Add to buffer
        buffer="${buffer}${line}\n"
        last_activity=$(date +%s)

        # Send buffer if:
        # 1. It's too large
        # 2. We hit a paragraph break
        local should_send=false

        if [ ${#buffer} -gt $BUFFER_SIZE ]; then
            should_send=true
        elif [ $blank_line_count -ge $PARAGRAPH_BREAK_LINES ]; then
            should_send=true
        fi

        if [ "$should_send" = "true" ] && [ -n "$buffer" ]; then
            # Trim trailing newlines
            buffer=$(echo -e "$buffer" | sed -e :a -e '/^\n*$/{ $d; N; ba' -e '}')

            # Send as code block
            send_code_block "$buffer" "" "$MIRROR_CHANNEL"

            buffer=""
            blank_line_count=0

            # Rate limiting
            sleep 0.5
        fi

        # Check for timeout
        local current_time=$(date +%s)
        local idle_time=$((current_time - last_activity))
        if [ $idle_time -ge $BUFFER_TIMEOUT ] && [ -n "$buffer" ]; then
            buffer=$(echo -e "$buffer" | sed -e :a -e '/^\n*$/{ $d; N; ba' -e '}')
            send_code_block "$buffer" "" "$MIRROR_CHANNEL"
            buffer=""
        fi
    done

    # Send any remaining buffer
    if [ -n "$buffer" ]; then
        buffer=$(echo -e "$buffer" | sed -e :a -e '/^\n*$/{ $d; N; ba' -e '}')
        send_code_block "$buffer" "" "$MIRROR_CHANNEL"
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    # Check configuration
    if [ "$SLACK_TOKEN" = "YOUR_SLACK_BOT_TOKEN_HERE" ]; then
        echo "❌ Slack bot token not configured!"
        echo ""
        echo "Please edit slack-logger.sh and set SLACK_TOKEN"
        echo "Get token from: https://api.slack.com/apps → OAuth & Permissions"
        exit 1
    fi

    if [ "$MIRROR_CHANNEL" = "C09M9A33FFF" ]; then
        echo "⚠️  Using default channel ID (C09M9A33FFF)"
        echo "Please edit slack-logger.sh and set DEFAULT_LOG_CHANNEL to your actual channel ID"
        echo ""
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Record start time
    SESSION_START=$(date +%s)

    # Notify session start
    notify_session_start "Claude Code Session" "$MIRROR_CHANNEL"

    echo ""
    echo "🚀 Starting Claude Code with Slack Mirroring"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Slack Channel: $MIRROR_CHANNEL"
    echo "All output will be mirrored to Slack"
    echo ""
    echo "Press Ctrl+C to stop"
    echo ""

    # Trap exit to send session end notification
    trap "notify_session_end 'Claude Code Session' '$SESSION_START' '$MIRROR_CHANNEL'; exit 0" INT TERM

    # Check if claude-code command exists
    if ! command -v claude &> /dev/null; then
        echo "❌ 'claude' command not found"
        echo ""
        echo "Please make sure Claude Code is installed and in your PATH"
        echo "Visit: https://docs.claude.com/claude-code"
        exit 1
    fi

    # Start Claude Code and pipe output through mirror function
    claude 2>&1 | mirror_to_slack

    # Session ended normally
    notify_session_end "Claude Code Session" "$SESSION_START" "$MIRROR_CHANNEL"
}

# Run main function
main "$@"
