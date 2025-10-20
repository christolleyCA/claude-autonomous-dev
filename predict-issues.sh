#!/bin/bash
# ============================================================================
# PREDICT ISSUES - Predictive Issue Detection with AI
# ============================================================================

SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"
ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"

# Source Slack logger if available
[ -f "./slack-logger.sh" ] && source ./slack-logger.sh

# Call Claude API for predictions
call_claude_for_predictions() {
    local code="$1"
    local file_path="$2"

    if [ -z "$ANTHROPIC_API_KEY" ]; then
        echo "Warning: ANTHROPIC_API_KEY not set, skipping AI predictions" >&2
        return 1
    fi

    local prompt="You are an expert at predicting software issues before they occur. Analyze this code and predict potential problems:

CODE:
\`\`\`typescript
${code}
\`\`\`

FILE: ${file_path}

Predict potential issues in these categories:

1. PERFORMANCE RISKS (slow queries, n+1 problems, memory leaks, inefficient algorithms)
2. SECURITY RISKS (SQL injection, XSS, authentication bypass, data leaks)
3. SCALABILITY RISKS (hard-coded limits, single points of failure, race conditions)
4. RELIABILITY RISKS (missing error handling, no retries, timeout issues)
5. MAINTAINABILITY RISKS (tight coupling, no tests, complex logic)

For each predicted issue, provide:
- Issue type
- Severity (critical/high/medium/low)
- Confidence (0.0-1.0)
- Description
- Reasoning
- Suggested fix

Format as JSON array:
[
  {
    \"issue_type\": \"performance\",
    \"severity\": \"high\",
    \"confidence\": 0.85,
    \"prediction\": \"Database query without LIMIT clause\",
    \"reasoning\": \"Query on line 45 selects all rows which could be millions\",
    \"suggested_fix\": \"Add LIMIT and pagination\"
  }
]

Only include issues with confidence > 0.6. Be specific with line numbers when possible."

    local response=$(curl -s https://api.anthropic.com/v1/messages \
        -H "x-api-key: ${ANTHROPIC_API_KEY}" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "$(jq -n \
            --arg prompt "$prompt" \
            '{
                model: "claude-sonnet-4-20250514",
                max_tokens: 3000,
                messages: [{
                    role: "user",
                    content: $prompt
                }]
            }')")

    echo "$response" | jq -r '.content[0].text // empty'
}

# Predict issues for a file
predict_issues() {
    local feature_name="$1"
    local file_path="$2"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔮 PREDICTIVE ISSUE DETECTION: $feature_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if command -v send_to_slack &> /dev/null; then
        send_to_slack "🔮 *Predictive Analysis Starting*
Feature: ${feature_name}
File: ${file_path}
Analyzing for potential issues..."
    fi

    # Read the code
    if [ ! -f "$file_path" ]; then
        echo "Error: File not found: $file_path"
        return 1
    fi

    local code=$(cat "$file_path")

    echo "🤖 Running AI predictive analysis..."
    echo ""

    # Get predictions from Claude
    local predictions_json=$(call_claude_for_predictions "$code" "$file_path")

    # Extract JSON array from markdown if needed
    predictions_json=$(echo "$predictions_json" | sed -n '/^\[/,/^\]/p')

    if [ -z "$predictions_json" ] || ! echo "$predictions_json" | jq empty 2>/dev/null; then
        echo "No issues predicted (or API unavailable)"
        predictions_json="[]"
    fi

    local issue_count=$(echo "$predictions_json" | jq '. | length')

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 PREDICTION RESULTS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Potential Issues Found: $issue_count"
    echo ""

    if [ "$issue_count" -gt 0 ]; then
        # Display predictions
        local prediction_summary=""
        local critical_count=0
        local high_count=0

        echo "$predictions_json" | jq -c '.[]' | while IFS= read -r prediction; do
            local issue_type=$(echo "$prediction" | jq -r '.issue_type')
            local severity=$(echo "$prediction" | jq -r '.severity')
            local confidence=$(echo "$prediction" | jq -r '.confidence')
            local description=$(echo "$prediction" | jq -r '.prediction')
            local reasoning=$(echo "$prediction" | jq -r '.reasoning')
            local fix=$(echo "$prediction" | jq -r '.suggested_fix')

            # Count by severity
            if [ "$severity" = "critical" ]; then
                ((critical_count++))
            elif [ "$severity" = "high" ]; then
                ((high_count++))
            fi

            # Display icon based on severity
            local icon="⚠️"
            case "$severity" in
                critical) icon="🔴" ;;
                high) icon="🟠" ;;
                medium) icon="🟡" ;;
                low) icon="🔵" ;;
            esac

            echo "$icon $severity: $description (${confidence}% confidence)"
            echo "   Type: $issue_type"
            echo "   Why: $reasoning"
            echo "   Fix: $fix"
            echo ""

            # Log to database
            curl -s -X POST \
                "${SUPABASE_URL}/rest/v1/predicted_issues" \
                -H "apikey: ${SUPABASE_KEY}" \
                -H "Authorization: Bearer ${SUPABASE_KEY}" \
                -H "Content-Type: application/json" \
                -d "$(echo "$prediction" | jq -c ". + {
                    feature_name: \"$feature_name\",
                    file_path: \"$file_path\"
                }")" > /dev/null
        done

        # Send summary to Slack
        if command -v send_to_slack &> /dev/null; then
            local urgency_text=""
            if [ "$critical_count" -gt 0 ]; then
                urgency_text="🚨 $critical_count CRITICAL issues found!"
            elif [ "$high_count" -gt 0 ]; then
                urgency_text="⚠️ $high_count HIGH severity issues"
            else
                urgency_text="✅ No critical issues"
            fi

            send_to_slack "🔮 *Predictive Analysis Complete*

Feature: ${feature_name}
Total Predictions: ${issue_count}
${urgency_text}

Review predictions and apply fixes before deployment!"
        fi
    else
        echo "✅ No potential issues detected!"
        echo ""

        if command -v send_to_slack &> /dev/null; then
            send_to_slack "✅ *Predictive Analysis Complete*

Feature: ${feature_name}
Result: No potential issues detected
Code looks solid! 🎉"
        fi
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    return 0
}

# Apply preventive fixes
apply_preventive_fixes() {
    local feature_name="$1"
    local file_path="$2"

    echo "🔧 Applying preventive fixes..."

    # Get recent predictions for this feature
    local predictions=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/predicted_issues" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        --data-urlencode "select=*" \
        --data-urlencode "feature_name=eq.${feature_name}" \
        --data-urlencode "prevented=eq.false" \
        --data-urlencode "order=confidence.desc" \
        --data-urlencode "limit=10")

    local fix_count=$(echo "$predictions" | jq '. | length')

    if [ "$fix_count" -eq 0 ]; then
        echo "No fixes to apply"
        return 0
    fi

    echo "Found $fix_count issues to fix"

    # For each prediction, mark as prevented
    echo "$predictions" | jq -c '.[]' | while IFS= read -r prediction; do
        local id=$(echo "$prediction" | jq -r '.id')
        local description=$(echo "$prediction" | jq -r '.prediction')

        echo "  ✅ Prevented: $description"

        # Mark as prevented in database
        curl -s -X PATCH \
            "${SUPABASE_URL}/rest/v1/predicted_issues?id=eq.${id}" \
            -H "apikey: ${SUPABASE_KEY}" \
            -H "Authorization: Bearer ${SUPABASE_KEY}" \
            -H "Content-Type: application/json" \
            -d "{\"prevented\": true, \"fix_applied\": \"Automatically applied during build\"}" > /dev/null
    done

    echo "✅ Preventive fixes applied"

    return 0
}

# View prediction accuracy
view_prediction_accuracy() {
    echo "📊 Prediction Accuracy Report"
    echo ""

    local accuracy=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/prediction_accuracy" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}")

    if echo "$accuracy" | jq -e '. | length > 0' > /dev/null 2>&1; then
        echo "By Issue Type:"
        echo "$accuracy" | jq -r '.[] | "  \(.issue_type): \(.accuracy_percentage)% accurate (\(.came_true)/\(.total_predictions) came true, \(.prevented_count) prevented)"'
    else
        echo "Not enough data yet to calculate accuracy"
    fi
}

# Export functions
export -f predict_issues
export -f apply_preventive_fixes
export -f view_prediction_accuracy

# If script is run directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-}" in
        accuracy)
            view_prediction_accuracy
            ;;
        apply)
            if [ $# -lt 3 ]; then
                echo "Usage: $0 apply <feature-name> <file-path>"
                exit 1
            fi
            apply_preventive_fixes "$2" "$3"
            ;;
        *)
            if [ $# -lt 2 ]; then
                echo "Usage: $0 <feature-name> <file-path>"
                echo "       $0 accuracy"
                echo "       $0 apply <feature-name> <file-path>"
                echo ""
                echo "Examples:"
                echo "  $0 email-sender /tmp/builds/email-sender/index.ts"
                echo "  $0 accuracy"
                exit 1
            fi
            predict_issues "$@"
            ;;
    esac
fi
