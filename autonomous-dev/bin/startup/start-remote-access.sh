#!/bin/bash
# Claude Code Remote Access Service - Enhanced with Real-Time Slack Updates
# Continuously polls for commands and executes them with progress notifications

# ============================================================================
# SLACK CONFIGURATION
# ============================================================================
# Get your Slack Bot Token from: https://api.slack.com/apps → Your App → OAuth & Permissions
# Copy the "Bot User OAuth Token" (starts with xoxb-)
SLACK_BOT_TOKEN="YOUR_SLACK_BOT_TOKEN_HERE"  # ⚠️ REPLACE WITH YOUR ACTUAL TOKEN

# Default Slack Channel for Terminal Commands
# When you run commands from terminal (not via /cc), notifications go here
# Get channel ID: Open channel in Slack, click name, scroll down to see "Channel ID"
# Or use a DM channel ID for private notifications (open DM with yourself, check URL)
DEFAULT_SLACK_CHANNEL="C09M9A33FFF"  # ⚠️ REPLACE WITH YOUR CHANNEL ID
NOTIFY_TERMINAL_COMMANDS=true        # Set to false to disable terminal command notifications

# Notification Settings
SLACK_UPDATES_ENABLED=true      # Set to false to disable progress updates
NOTIFY_ON_DETECT=true           # Notify when command detected
NOTIFY_ON_START=true            # Notify when execution starts
NOTIFY_ON_COMPLETE=true         # Notify on completion
NOTIFY_WITH_METRICS=true        # Include execution metrics

# ============================================================================
# POLLING CONFIGURATION
# ============================================================================
POLL_INTERVAL=30  # seconds
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Supabase Configuration (needed for source detection)
SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

# Source the helper scripts
source "${SCRIPT_DIR}/lib/claude-poll-commands.sh"
source "${SCRIPT_DIR}/lib/claude-write-response.sh"

# ============================================================================
# SLACK NOTIFICATION FUNCTION
# ============================================================================
send_slack_update() {
    local channel_id="$1"
    local message="$2"
    local thread_ts="$3"

    # Skip if Slack updates are disabled
    if [ "$SLACK_UPDATES_ENABLED" != "true" ]; then
        return 0
    fi

    # Skip if no channel (shouldn't happen, but safety check)
    if [ -z "$channel_id" ] || [ "$channel_id" = "null" ]; then
        return 0
    fi

    # Check if token is configured
    if [ "$SLACK_BOT_TOKEN" = "YOUR_SLACK_BOT_TOKEN_HERE" ]; then
        echo "⚠️  Slack token not configured - skipping notification"
        return 0
    fi

    # Build the request body
    local body="{\"channel\": \"${channel_id}\", \"text\": $(echo "$message" | jq -Rs .)}"

    # Add thread_ts if provided
    if [ -n "$thread_ts" ] && [ "$thread_ts" != "null" ]; then
        body=$(echo "$body" | jq ". + {\"thread_ts\": \"${thread_ts}\"}")
    fi

    # Send the message
    local response=$(curl -s -X POST "https://slack.com/api/chat.postMessage" \
        -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$body")

    # Check if successful
    local ok=$(echo "$response" | jq -r '.ok')
    if [ "$ok" = "true" ]; then
        echo "   📤 Slack notification sent"
    else
        local error=$(echo "$response" | jq -r '.error')
        echo "   ⚠️  Slack notification failed: $error"
    fi
}

# ============================================================================
# ENHANCED COMMAND EXECUTION WITH PROGRESS UPDATES
# ============================================================================
execute_command() {
    local command_id=$1
    local command=$2
    local channel_id=$3
    local thread_ts=$4
    local source=$5

    echo ""
    echo "⚡ Executing command: $command"
    echo "   Source: $source"

    # Detect if this is a terminal command
    local is_terminal_cmd=false
    if [ -z "$channel_id" ] || [ "$channel_id" = "null" ] || [ "$channel_id" = "" ]; then
        is_terminal_cmd=true

        # Use default channel for terminal commands if enabled
        if [ "$NOTIFY_TERMINAL_COMMANDS" = "true" ]; then
            channel_id="$DEFAULT_SLACK_CHANNEL"
            echo "📍 Using default Slack channel for terminal command notifications"
        else
            echo "📍 Terminal command notifications disabled"
            channel_id=""  # Disable notifications
        fi
    fi

    # Track execution time
    local start_time=$(date +%s)
    local start_display=$(date '+%I:%M %p')
    local hostname=$(hostname -s)

    # STAGE 1: Command Detected
    if [ "$NOTIFY_ON_DETECT" = "true" ]; then
        local detect_message=""

        if [ "$is_terminal_cmd" = "true" ]; then
            # Terminal command - add special prefix
            detect_message="💻 *Terminal Command*
⚙️ Claude Code is processing your command
Command: \`${command}\`
Initiated from: Terminal at ${hostname}
Started at: ${start_display}"
        else
            # Slack command - standard message
            detect_message="⚙️ *Claude Code is processing your command*
Started at: ${start_display}
Command: \`${command}\`"
        fi

        send_slack_update "$channel_id" "$detect_message" "$thread_ts"
    fi

    # Mark as processing in database
    mark_processing "$command_id"

    # STAGE 2: Execution Starting
    if [ "$NOTIFY_ON_START" = "true" ]; then
        local start_message="🔨 *Executing command...*
This may take a moment depending on complexity."
        send_slack_update "$channel_id" "$start_message" "$thread_ts"
    fi

    # Execute the command and capture output
    local response
    local exit_code

    # CRITICAL: Wrap in error handling to prevent crashes
    {
        # Check if this is a build-feature command
        if [[ "$command" == build-feature* ]]; then
            echo "🏗️  Build-feature command detected"

            # Parse: build-feature feature-name "description"
            # Extract feature name (word after build-feature)
            local feature_name=$(echo "$command" | sed 's/build-feature[[:space:]]*//' | awk '{print $1}')

            # Extract description (everything in quotes)
            local description=$(echo "$command" | grep -o '"[^"]*"' | sed 's/"//g')

            # If no description in quotes, try to get rest of line
            if [ -z "$description" ]; then
                description=$(echo "$command" | sed 's/build-feature[[:space:]]*[^[:space:]]*[[:space:]]*//')
                # If still empty, use default
                if [ -z "$description" ]; then
                    description="Auto-generated feature"
                fi
            fi

            echo "   Feature: $feature_name"
            echo "   Description: $description"

            # Export API key for build-feature script
            export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-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}"

            # Execute build-feature script with robust error handling
            echo "   Calling build-feature.sh..."
            if [ -f "${SCRIPT_DIR}/bin/features/build-feature.sh" ]; then
                # Run in subshell to isolate any exit commands
                (
                    "${SCRIPT_DIR}/bin/features/build-feature.sh" "$feature_name" "$description" 2>&1
                    exit $?
                )
                exit_code=$?
                response=$(cat /tmp/build-feature-output.txt 2>/dev/null || echo "Build completed with exit code: $exit_code")

                if [ $exit_code -eq 0 ]; then
                    echo "   ✅ Build-feature completed successfully"
                else
                    echo "   ⚠️ Build-feature completed with code: $exit_code"
                fi
            else
                echo "   ❌ Error: build-feature.sh not found"
                response="Error: build-feature.sh not found at ${SCRIPT_DIR}/build-feature.sh"
                exit_code=1
            fi
        elif [[ "$command" == "git-commit" ]] || [[ "$command" == "git-commit-and-push" ]]; then
            echo "🔧 Git commit command detected"

            # Determine if we should push
            local push_arg="no"
            if [[ "$command" == "git-commit-and-push" ]]; then
                push_arg="push"
                echo "   Mode: Commit AND push to GitHub"
            else
                echo "   Mode: Commit only (no push)"
            fi

            # Execute smart commit
            if [ -f "${SCRIPT_DIR}/bin/git/smart-git-commit.sh" ]; then
                response=$("${SCRIPT_DIR}/bin/git/smart-git-commit.sh" "$push_arg" 2>&1)
                exit_code=$?
            else
                response="Error: smart-git-commit.sh not found at ${SCRIPT_DIR}/smart-git-commit.sh"
                exit_code=1
            fi

        elif [[ "$command" == "git-status" ]]; then
            echo "📊 Git status command detected"
            response=$(git status 2>&1)
            exit_code=$?

        elif [[ "$command" == "git-summary" ]]; then
            echo "📈 Git summary command detected"
            response=$(echo "=== Last 5 Commits ===" && git log -5 --pretty=format:"%h - %an, %ar : %s" && echo "" && echo "" && echo "=== Current Branch ===" && git branch && echo "" && echo "=== Uncommitted Changes ===" && git status --short 2>&1)
            exit_code=$?

        elif [[ "$command" == "restore-context" ]]; then
            echo "🔍 Restore context command detected"

            # Execute restore context
            if [ -f "${SCRIPT_DIR}/bin/git/restore-context.sh" ]; then
                response=$("${SCRIPT_DIR}/bin/git/restore-context.sh" 2>&1)
                exit_code=$?
            else
                response="Error: restore-context.sh not found at ${SCRIPT_DIR}/restore-context.sh"
                exit_code=1
            fi

        else
            # Normal command - execute as shell
            echo "⚡ Executing shell command"
            response=$(bash -c "$command" 2>&1)
            exit_code=$?
        fi
    } || {
        # CRITICAL ERROR HANDLER: Never crash, always recover
        echo "❌ CRITICAL ERROR in command execution"
        response="CRITICAL ERROR: Command execution failed unexpectedly. Error: $?"
        exit_code=99
    }

    # Calculate execution time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Count output lines and size
    local output_lines=$(echo "$response" | wc -l | tr -d ' ')
    local output_chars=$(echo "$response" | wc -c | tr -d ' ')

    if [ $exit_code -eq 0 ]; then
        # ===== SUCCESS =====

        # STAGE 3: Command Completed Successfully
        if [ "$NOTIFY_ON_COMPLETE" = "true" ]; then
            # Create preview (first 200 chars)
            local preview=$(echo "$response" | head -c 200)
            if [ ${#response} -gt 200 ]; then
                preview="${preview}..."
            fi

            local success_message="✅ *Execution complete!*
Duration: ${duration}s
Exit code: 0"

            # Add preview if there's output
            if [ -n "$response" ]; then
                success_message="${success_message}
Preview: \`${preview}\`"
            fi

            # Add metrics if enabled
            if [ "$NOTIFY_WITH_METRICS" = "true" ]; then
                success_message="${success_message}

📊 *Metrics*
• Output: ${output_lines} lines (${output_chars} chars)
• Timestamp: $(date '+%Y-%m-%d %I:%M:%S %p')"
            fi

            success_message="${success_message}

_Full result will arrive in the main response shortly._"

            send_slack_update "$channel_id" "$success_message" "$thread_ts"
        fi

        # Write response to database
        write_response "$command_id" "$response"
        echo "✅ Command completed successfully (${duration}s)"

    else
        # ===== FAILURE =====

        # STAGE 4: Command Failed
        if [ "$NOTIFY_ON_COMPLETE" = "true" ]; then
            # Create error preview
            local error_preview=$(echo "$response" | head -c 300)
            if [ ${#response} -gt 300 ]; then
                error_preview="${error_preview}..."
            fi

            local error_message="❌ *Command failed*
Exit code: ${exit_code}
Duration: ${duration}s

Error preview:
\`\`\`
${error_preview}
\`\`\`"

            if [ "$NOTIFY_WITH_METRICS" = "true" ]; then
                error_message="${error_message}

📊 *Metrics*
• Output: ${output_lines} lines
• Timestamp: $(date '+%Y-%m-%d %I:%M:%S %p')"
            fi

            send_slack_update "$channel_id" "$error_message" "$thread_ts"
        fi

        # Write error to database
        write_error "$command_id" "Command failed with exit code $exit_code: $response"
        echo "❌ Command failed (${duration}s)"
    fi
}

# ============================================================================
# MAIN POLLING LOOP
# ============================================================================
main() {
    echo "🚀 Claude Code Remote Access Service - Enhanced Edition"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Polling interval: ${POLL_INTERVAL} seconds"
    echo "Slack updates: $([ "$SLACK_UPDATES_ENABLED" = "true" ] && echo "✅ Enabled" || echo "❌ Disabled")"

    # Check Slack token configuration
    if [ "$SLACK_UPDATES_ENABLED" = "true" ] && [ "$SLACK_BOT_TOKEN" = "YOUR_SLACK_BOT_TOKEN_HERE" ]; then
        echo ""
        echo "⚠️  WARNING: Slack Bot Token not configured!"
        echo "   Edit this script and replace SLACK_BOT_TOKEN with your actual token"
        echo "   Get it from: https://api.slack.com/apps → Your App → OAuth & Permissions"
        echo "   Progress updates will be skipped until configured."
        echo ""
    fi

    echo "Press Ctrl+C to stop"
    echo ""

    while true; do
        # CRITICAL: Wrap entire loop in error handler to prevent crashes
        {
            # Write heartbeat for health monitoring
            echo "$(date +%s)" > /tmp/claude-remote-access-heartbeat

            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Checking for new commands..."

            # Check for commands
            local result=$(check_for_commands 2>&1)

            # Check if we found a command (contains multiple pipes)
            if echo "$result" | grep -q "|"; then
                # Extract all fields: command_id|command|slack_channel_id|slack_thread_ts
                local data_line=$(echo "$result" | grep "|" | tail -1)

                local command_id=$(echo "$data_line" | cut -d'|' -f1)
                local command=$(echo "$data_line" | cut -d'|' -f2)
                local slack_channel=$(echo "$data_line" | cut -d'|' -f3)
                local slack_thread=$(echo "$data_line" | cut -d'|' -f4)

                # Get source from database (slack, terminal, manual_test, etc)
                local cmd_source=$(curl -s "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.${command_id}&select=source" \
                    -H "apikey: ${SUPABASE_KEY}" \
                    -H "Authorization: Bearer ${SUPABASE_KEY}" | jq -r '.[0].source // "unknown"')

                # Execute the command with progress updates
                execute_command "$command_id" "$command" "$slack_channel" "$slack_thread" "$cmd_source"
            fi
        } || {
            # CRITICAL ERROR: Main loop error handler
            echo "❌ ERROR in main processing loop at $(date)"
            echo "Error: $?"
            echo "Recovering and continuing..."

            # Log error to file
            echo "[$(date)] LOOP ERROR: $?" >> /tmp/remote-access-errors.log

            # Send alert to Slack if possible
            send_slack_update "$DEFAULT_SLACK_CHANNEL" "⚠️ *Remote Access Service*
Error in processing loop, but service is self-healing and continuing.
Time: $(date '+%I:%M %p')
Check /tmp/remote-access-errors.log for details" ""
        }

        # Wait before next poll (always execute, even after error)
        sleep $POLL_INTERVAL
    done
}

# ============================================================================
# SIGNAL HANDLING
# ============================================================================
trap 'echo ""; echo "👋 Shutting down Claude Code Remote Access Service"; exit 0' INT

# ============================================================================
# START THE SERVICE
# ============================================================================
main
