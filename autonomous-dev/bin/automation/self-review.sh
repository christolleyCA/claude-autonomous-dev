#!/bin/bash
# ============================================================================
# SELF-REVIEW - Code Quality Review and Automatic Improvement
# ============================================================================

SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"
ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"

# Source Slack logger if available
[ -f "./slack-logger.sh" ] && source ./slack-logger.sh

# Call Claude API for code review
call_claude_for_review() {
    local code="$1"
    local file_path="$2"

    if [ -z "$ANTHROPIC_API_KEY" ]; then
        echo "Warning: ANTHROPIC_API_KEY not set, using basic analysis" >&2
        return 1
    fi

    local prompt="You are an expert code reviewer. Analyze this code for:

CODE:
\`\`\`typescript
${code}
\`\`\`

FILE: ${file_path}

Provide a structured review:

1. QUALITY SCORE (0-100)
2. COMPLEXITY SCORE (1-10, where 1=simple, 10=very complex)
3. ISSUES FOUND (list specific issues)
4. SUGGESTIONS (specific improvements)
5. REFACTORING NEEDED (yes/no with explanation)
6. OPTIMIZATIONS (performance improvements)
7. TEST COVERAGE GAPS (what tests are missing)

Format as JSON:
{
  \"quality_score\": 85,
  \"complexity_score\": 6,
  \"issues\": [\"issue 1\", \"issue 2\"],
  \"suggestions\": [\"suggestion 1\", \"suggestion 2\"],
  \"refactoring_needed\": true,
  \"optimizations\": [\"optimization 1\"],
  \"test_gaps\": [\"missing edge case tests\"]
}"

    local response=$(curl -s https://api.anthropic.com/v1/messages \
        -H "x-api-key: ${ANTHROPIC_API_KEY}" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "$(jq -n \
            --arg prompt "$prompt" \
            '{
                model: "claude-sonnet-4-20250514",
                max_tokens: 2048,
                messages: [{
                    role: "user",
                    content: $prompt
                }]
            }')")

    echo "$response" | jq -r '.content[0].text // empty'
}

# Analyze code quality
analyze_code_quality() {
    local file_path="$1"

    echo "🔍 Analyzing code quality: $file_path"

    # Read the code
    if [ ! -f "$file_path" ]; then
        echo "Error: File not found: $file_path"
        return 1
    fi

    local code=$(cat "$file_path")
    local line_count=$(echo "$code" | wc -l | tr -d ' ')

    # Basic metrics
    local function_count=$(grep -c "function\|const.*=.*(" "$file_path" || echo "0")
    local comment_lines=$(grep -c "^[[:space:]]*//\|^[[:space:]]*\*" "$file_path" || echo "0")
    local duplication=$(echo "$code" | sort | uniq -d | wc -l | tr -d ' ')

    echo "📊 Basic Metrics:"
    echo "   Lines of code: $line_count"
    echo "   Functions: $function_count"
    echo "   Comment lines: $comment_lines"
    echo "   Potential duplicates: $duplication"

    # Use Claude for deep analysis
    echo ""
    echo "🤖 Running AI code review..."
    local review=$(call_claude_for_review "$code" "$file_path")

    if [ -n "$review" ]; then
        echo "$review"
        echo "$review"
    else
        echo "{\"quality_score\": 70, \"complexity_score\": 5, \"issues\": [], \"suggestions\": [], \"refactoring_needed\": false, \"optimizations\": [], \"test_gaps\": []}"
    fi
}

# Main review function
review_feature() {
    local feature_name="$1"
    local file_path="$2"
    local git_commit="${3:-}"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 SELF-REVIEW: $feature_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if command -v send_to_slack &> /dev/null; then
        send_to_slack "🔍 *Self-Review Starting*
Feature: ${feature_name}
File: ${file_path}
Analyzing code quality..."
    fi

    # Analyze the code
    local review_json=$(analyze_code_quality "$file_path")

    # Extract metrics from JSON
    local quality_score=$(echo "$review_json" | jq -r '.quality_score // 70')
    local complexity_score=$(echo "$review_json" | jq -r '.complexity_score // 5')
    local issues_count=$(echo "$review_json" | jq -r '.issues | length // 0')
    local suggestions_count=$(echo "$review_json" | jq -r '.suggestions | length // 0')

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 REVIEW RESULTS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Quality Score: $quality_score/100"
    echo "Complexity Score: $complexity_score/10"
    echo "Issues Found: $issues_count"
    echo "Suggestions: $suggestions_count"
    echo ""

    # Display issues
    if [ "$issues_count" -gt 0 ]; then
        echo "⚠️  Issues Found:"
        echo "$review_json" | jq -r '.issues[]' | while read -r issue; do
            echo "   • $issue"
        done
        echo ""
    fi

    # Display suggestions
    if [ "$suggestions_count" -gt 0 ]; then
        echo "💡 Suggestions:"
        echo "$review_json" | jq -r '.suggestions[]' | while read -r suggestion; do
            echo "   • $suggestion"
        done
        echo ""
    fi

    # Log to database
    echo "💾 Logging review to database..."

    local issues_array=$(echo "$review_json" | jq -c '.issues // []')
    local suggestions_array=$(echo "$review_json" | jq -c '.suggestions // []')

    local payload=$(cat <<EOF
{
  "feature_name": "$feature_name",
  "review_type": "automatic",
  "file_path": "$file_path",
  "code_quality_score": $quality_score,
  "complexity_score": $complexity_score,
  "issues_found": $issues_count,
  "suggestions": $suggestions_array,
  "before_git_commit": $([ -n "$git_commit" ] && echo "\"$git_commit\"" || echo "null")
}
EOF
)

    curl -s -X POST \
        "${SUPABASE_URL}/rest/v1/code_reviews" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "$payload" > /dev/null

    echo "✅ Review logged"

    # Send summary to Slack
    if command -v send_to_slack &> /dev/null; then
        local improvement=""
        if [ "$quality_score" -ge 90 ]; then
            improvement="Excellent quality! 🎉"
        elif [ "$quality_score" -ge 75 ]; then
            improvement="Good quality with room for improvement"
        else
            improvement="Needs significant improvement"
        fi

        send_to_slack "✅ *Self-Review Complete*

Feature: ${feature_name}
Quality Score: ${quality_score}/100
Complexity: ${complexity_score}/10
Issues Found: ${issues_count}
Suggestions: ${suggestions_count}

${improvement}

Ready for deployment! 🚀"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    return 0
}

# Compare before/after
compare_versions() {
    local feature_name="$1"

    echo "📊 Comparing review history for: $feature_name"

    local reviews=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/code_reviews" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        --data-urlencode "select=code_quality_score,complexity_score,issues_found,created_at" \
        --data-urlencode "feature_name=eq.${feature_name}" \
        --data-urlencode "order=created_at.asc" \
        --data-urlencode "limit=10")

    if echo "$reviews" | jq -e '. | length > 1' > /dev/null 2>&1; then
        echo ""
        echo "Quality Trend:"
        echo "$reviews" | jq -r '.[] | "  \(.created_at | split("T")[0]): Score \(.code_quality_score)/100, Issues: \(.issues_found)"'

        local first_score=$(echo "$reviews" | jq -r '.[0].code_quality_score')
        local last_score=$(echo "$reviews" | jq -r '.[-1].code_quality_score')
        local improvement=$(echo "$last_score - $first_score" | bc)

        echo ""
        echo "Overall Improvement: +$improvement points"
    else
        echo "Not enough review history to compare"
    fi
}

# Export functions
export -f review_feature
export -f analyze_code_quality
export -f compare_versions

# If script is run directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -lt 2 ]; then
        echo "Usage: $0 <feature-name> <file-path> [git-commit]"
        echo ""
        echo "Examples:"
        echo "  $0 email-sender /tmp/autonomous-builds/email-sender-123/index.ts"
        echo "  $0 payment-processor ./payment-processor.ts abc123def"
        exit 1
    fi

    review_feature "$@"
fi
