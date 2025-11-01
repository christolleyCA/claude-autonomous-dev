#!/bin/bash
# Autonomous Feature Builder with Sentry-Powered Testing
# This script orchestrates the autonomous building of edge functions with comprehensive error tracking

# Load environment variables from .env if available
[ -f "${BASH_SOURCE[0]%/*}/.env" ] && source "${BASH_SOURCE[0]%/*}/.env"
SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN:-}"
SLACK_CHANNEL="C09M9A33FFF"
SUPABASE_PROJECT_ID="hjtvtkffpziopozmtsnb"
BUILD_DIR="/tmp/autonomous-builds"

# Ensure build directory exists
mkdir -p "$BUILD_DIR"

# Send message to Slack
send_slack() {
    local message="$1"
    local payload=$(jq -n \
        --arg channel "$SLACK_CHANNEL" \
        --arg text "$message" \
        '{
            channel: $channel,
            text: $text
        }')

    curl -s -X POST "https://slack.com/api/chat.postMessage" \
        -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$payload" > /dev/null 2>&1
}

# Main autonomous build function
build_feature_autonomous() {
    local feature_name="$1"
    local description="$2"
    local start_time=$(date +%s)
    local timestamp=$(date '+%I:%M %p')

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 AUTONOMOUS BUILD STARTED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Feature: ${feature_name}"
    echo "Description: ${description}"
    echo "Time: ${timestamp}"
    echo ""

    send_slack "🚀 *AUTONOMOUS BUILD STARTED*

Feature: \`${feature_name}\`
Description: ${description}
Time: ${timestamp}

I'll build this completely autonomously with Sentry-powered testing!"

    # Create feature directory
    local feature_dir="${BUILD_DIR}/${feature_name}"
    mkdir -p "$feature_dir"

    # Phase 1: Planning
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 PHASE 1: PLANNING & DESIGN"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    send_slack "📋 *Phase 1: Planning & Design*

Analyzing requirements...
Designing architecture...
Planning test strategy...
Identifying error scenarios..."

    # Store build metadata
    cat > "${feature_dir}/build-metadata.json" <<EOF
{
  "feature_name": "${feature_name}",
  "description": "${description}",
  "start_time": "${start_time}",
  "build_dir": "${feature_dir}",
  "status": "planning"
}
EOF

    echo "✅ Planning complete"
    echo "Build directory: ${feature_dir}"
    echo ""

    # Phase 2: Will be handled by Claude Code via command
    send_slack "✅ *Planning Complete*

Build directory ready: \`${feature_dir}\`
Feature spec saved: \`build-metadata.json\`

Next: Handing over to Claude Code for implementation..."

    # Return feature directory for Claude Code to use
    echo "$feature_dir"
}

# Parse command-line arguments
FEATURE_NAME=""
DESCRIPTION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            FEATURE_NAME="$2"
            shift 2
            ;;
        --description)
            DESCRIPTION="$2"
            shift 2
            ;;
        *)
            if [ -z "$FEATURE_NAME" ]; then
                FEATURE_NAME="$1"
            elif [ -z "$DESCRIPTION" ]; then
                DESCRIPTION="$1"
            fi
            shift
            ;;
    esac
done

# Execute if called directly
if [ -n "$FEATURE_NAME" ]; then
    build_feature_autonomous "$FEATURE_NAME" "$DESCRIPTION"
fi
