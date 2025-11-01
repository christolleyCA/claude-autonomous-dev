#!/bin/bash
# Sentry Integration Helper Functions
# Provides utilities for checking errors, getting details, and managing Sentry integration

SENTRY_AUTH_TOKEN="${SENTRY_AUTH_TOKEN:-}"
SENTRY_ORG="${SENTRY_ORG:-grantomatic}"
SENTRY_PROJECT="${SENTRY_PROJECT:-supabase-edge-functions}"

# Check Sentry for recent errors
check_sentry_for_errors() {
    local time_window="${1:-1h}"
    local function_name="${2:-}"

    echo "🔍 Checking Sentry for errors in last ${time_window}..."

    if [ -z "$SENTRY_AUTH_TOKEN" ]; then
        echo "⚠️  Warning: SENTRY_AUTH_TOKEN not set, skipping Sentry check"
        echo "0"
        return 0
    fi

    # Convert time window to timestamp
    local since_timestamp
    case $time_window in
        *m)
            local minutes="${time_window%m}"
            since_timestamp=$(date -u -v-${minutes}M +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -d "${minutes} minutes ago" +%Y-%m-%dT%H:%M:%S)
            ;;
        *h)
            local hours="${time_window%h}"
            since_timestamp=$(date -u -v-${hours}H +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -d "${hours} hours ago" +%Y-%m-%dT%H:%M:%S)
            ;;
        *)
            since_timestamp=$(date -u -v-1H +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -d "1 hour ago" +%Y-%m-%dT%H:%M:%S)
            ;;
    esac

    # Query Sentry API for issues
    local query="is:unresolved"
    if [ -n "$function_name" ]; then
        query="${query} function:${function_name}"
    fi

    local response=$(curl -s \
        -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
        "https://sentry.io/api/0/projects/${SENTRY_ORG}/${SENTRY_PROJECT}/issues/?query=${query}&statsPeriod=${time_window}")

    # Count errors
    local error_count=$(echo "$response" | jq '. | length' 2>/dev/null || echo "0")

    if [ "$error_count" -gt 0 ]; then
        echo "❌ Found ${error_count} error(s) in Sentry"
        echo "$response" | jq -r '.[] | "  - \(.title) (Count: \(.count), Last seen: \(.lastSeen))"' 2>/dev/null
    else
        echo "✅ No errors found in Sentry"
    fi

    echo "$error_count"
}

# Get detailed error information
get_error_details() {
    local error_id="$1"

    if [ -z "$SENTRY_AUTH_TOKEN" ]; then
        echo "⚠️  Warning: SENTRY_AUTH_TOKEN not set"
        return 1
    fi

    echo "📋 Fetching error details for: ${error_id}"
    echo ""

    local response=$(curl -s \
        -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
        "https://sentry.io/api/0/issues/${error_id}/")

    echo "Error Details:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo "$response" | jq -r '
        "Title: \(.title)",
        "Type: \(.type)",
        "Count: \(.count)",
        "First Seen: \(.firstSeen)",
        "Last Seen: \(.lastSeen)",
        "Status: \(.status)",
        "",
        "Latest Event:",
        "  Message: \(.metadata.value)",
        "  Function: \(.metadata.function // "N/A")",
        "",
        "Stack Trace:",
        (.entries[0].data.values[0].stacktrace.frames[-3:] | .[] | "  \(.filename):\(.lineNo) in \(.function)"),
        "",
        "Tags:",
        (.tags | to_entries | .[] | "  \(.key): \(.value)")
    ' 2>/dev/null || echo "$response"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Return full JSON for programmatic use
    echo "$response"
}

# Get latest event for an issue
get_latest_event() {
    local issue_id="$1"

    if [ -z "$SENTRY_AUTH_TOKEN" ]; then
        echo "⚠️  Warning: SENTRY_AUTH_TOKEN not set"
        return 1
    fi

    echo "📋 Fetching latest event for issue: ${issue_id}"

    local response=$(curl -s \
        -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
        "https://sentry.io/api/0/issues/${issue_id}/events/latest/")

    echo "$response"
}

# Mark error as resolved
mark_error_resolved() {
    local error_id="$1"
    local resolution="${2:-fixed}"

    if [ -z "$SENTRY_AUTH_TOKEN" ]; then
        echo "⚠️  Warning: SENTRY_AUTH_TOKEN not set"
        return 1
    fi

    echo "✅ Marking error ${error_id} as resolved (${resolution})"

    curl -s -X PUT \
        -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"status\": \"resolved\", \"statusDetails\": {\"inRelease\": \"${resolution}\"}}" \
        "https://sentry.io/api/0/issues/${error_id}/" > /dev/null

    echo "✅ Error marked as resolved"
}

# Wait for Sentry to receive data
wait_for_sentry() {
    local function_name="$1"
    local wait_seconds="${2:-10}"

    echo "⏳ Waiting ${wait_seconds} seconds for Sentry to receive data..."

    for i in $(seq 1 $wait_seconds); do
        echo -n "."
        sleep 1
    done

    echo ""
    echo "✅ Wait complete, checking Sentry now..."
}

# Create breadcrumb message for Slack
format_sentry_summary() {
    local error_count="$1"
    local function_name="$2"

    if [ "$error_count" -eq 0 ]; then
        echo "✅ *Sentry Check: CLEAN*

No errors detected for \`${function_name}\`
All tests passing with zero errors! 🎉"
    else
        echo "❌ *Sentry Check: ${error_count} ERROR(S) FOUND*

Function: \`${function_name}\`
Errors need to be addressed before deployment."
    fi
}

# Export functions for use in other scripts
export -f check_sentry_for_errors
export -f get_error_details
export -f get_latest_event
export -f mark_error_resolved
export -f wait_for_sentry
export -f format_sentry_summary
