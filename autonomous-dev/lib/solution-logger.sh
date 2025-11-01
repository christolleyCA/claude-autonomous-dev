#!/bin/bash
# ============================================================================
# SOLUTION LOGGER - Log solutions to knowledge base
# ============================================================================

SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

# Source Slack logger if available
[ -f "./slack-logger.sh" ] && source ./slack-logger.sh

log_solution() {
    local issue_title="$1"
    local issue_description="$2"
    local solution_summary="$3"
    local error_message="${4:-}"
    local feature_name="${5:-}"
    local tags="${6:-}"
    local error_type="${7:-}"
    local file_affected="${8:-}"
    local technology_stack="${9:-}"
    local solution_steps="${10:-}"
    local code_changes="${11:-}"

    echo "💾 Logging solution to knowledge base..."

    # Prepare tags array for PostgreSQL
    local tags_array="null"
    if [ -n "$tags" ]; then
        # Convert comma-separated tags to PostgreSQL array format
        tags_array=$(echo "$tags" | sed 's/,/","/g' | sed 's/^/["/' | sed 's/$/"]/')
    fi

    # Prepare JSON payload
    local payload=$(cat <<EOF
{
  "issue_title": "$issue_title",
  "issue_description": "$issue_description",
  "solution_summary": "$solution_summary",
  "error_message": $([ -n "$error_message" ] && echo "\"$error_message\"" || echo "null"),
  "feature_name": $([ -n "$feature_name" ] && echo "\"$feature_name\"" || echo "null"),
  "tags": $tags_array,
  "error_type": $([ -n "$error_type" ] && echo "\"$error_type\"" || echo "null"),
  "file_affected": $([ -n "$file_affected" ] && echo "\"$file_affected\"" || echo "null"),
  "technology_stack": $([ -n "$technology_stack" ] && echo "\"$technology_stack\"" || echo "null"),
  "solution_steps": $([ -n "$solution_steps" ] && echo "\"$solution_steps\"" || echo "null"),
  "code_changes": $([ -n "$code_changes" ] && echo "\"$code_changes\"" || echo "null")
}
EOF
)

    # Insert into Supabase
    local response=$(curl -s -X POST \
        "${SUPABASE_URL}/rest/v1/claude_solutions" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "$payload")

    if echo "$response" | grep -q '"id"'; then
        echo "✅ Solution logged successfully"

        # Send to Slack if available
        if command -v send_to_slack &> /dev/null; then
            send_to_slack "💡 *Solution Logged to Knowledge Base*
📝 Issue: ${issue_title}
💡 Solution: ${solution_summary}
🏷️ Tags: ${tags:-none}
This will be referenced automatically in future builds!"
        fi

        return 0
    else
        echo "❌ Failed to log solution"
        echo "Response: $response"
        return 1
    fi
}

# Quick interactive logging
quick_log() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💾 QUICK SOLUTION LOGGER"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    read -p "Issue title: " issue_title
    if [ -z "$issue_title" ]; then
        echo "❌ Title required"
        return 1
    fi

    echo ""
    read -p "What was the problem? " issue_desc
    if [ -z "$issue_desc" ]; then
        echo "❌ Description required"
        return 1
    fi

    echo ""
    read -p "How did you fix it? " solution
    if [ -z "$solution" ]; then
        echo "❌ Solution required"
        return 1
    fi

    echo ""
    read -p "Error message (optional): " error_msg

    echo ""
    read -p "Tags (comma-separated, optional): " tags

    echo ""
    read -p "Feature name (optional): " feature

    echo ""
    log_solution "$issue_title" "$issue_desc" "$solution" "$error_msg" "$feature" "$tags"
}

# Log from command line arguments
log_from_args() {
    if [ $# -lt 3 ]; then
        echo "Usage: $0 <title> <description> <solution> [error_message] [feature_name] [tags]"
        return 1
    fi

    log_solution "$@"
}

# Update solution usage (when it gets used successfully)
mark_solution_used() {
    local solution_id="$1"
    local success="${2:-true}"

    echo "📊 Updating solution usage..."

    # Increment times_used and update last_used_at
    local payload=$(cat <<EOF
{
  "times_used": "increment",
  "last_used_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
)

    curl -s -X PATCH \
        "${SUPABASE_URL}/rest/v1/claude_solutions?id=eq.${solution_id}" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        -H "Content-Type: application/json" \
        -d "$payload" > /dev/null

    echo "✅ Solution usage updated"
}

# Export functions
export -f log_solution
export -f quick_log
export -f log_from_args
export -f mark_solution_used

# If script is run directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -eq 0 ]; then
        quick_log
    else
        log_from_args "$@"
    fi
fi
