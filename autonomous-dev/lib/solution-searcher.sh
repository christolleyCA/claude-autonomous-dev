#!/bin/bash
# ============================================================================
# SOLUTION SEARCHER - Search and retrieve solutions from knowledge base
# ============================================================================

SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

# Search solutions by full-text search
search_solutions() {
    local query="$1"
    local limit="${2:-5}"

    echo "🔍 Searching knowledge base for: $query"
    echo ""

    # Convert query to tsquery format (replace spaces with & for AND search)
    local tsquery=$(echo "$query" | sed 's/ / \& /g')

    # Search using full-text search
    local response=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/claude_solutions" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        --data-urlencode "select=id,issue_title,solution_summary,tags,times_used,success_rate" \
        --data-urlencode "search_vector=wfts.${tsquery}" \
        --data-urlencode "order=success_rate.desc,times_used.desc" \
        --data-urlencode "limit=${limit}")

    # Check if we got results
    if echo "$response" | jq -e '. | length > 0' > /dev/null 2>&1; then
        echo "💡 Found $(echo "$response" | jq '. | length') solution(s):"
        echo ""

        # Display results
        echo "$response" | jq -r '.[] | "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n📋 \(.issue_title)\n💡 Solution: \(.solution_summary)\n🏷️  Tags: \(.tags // [] | join(", "))\n📊 Used \(.times_used) times | Success rate: \(.success_rate * 100)%\n🆔 ID: \(.id)\n"'

        return 0
    else
        echo "❌ No solutions found for: $query"
        return 1
    fi
}

# Find solution by error message
find_by_error() {
    local error_message="$1"

    echo "🔍 Checking if I've seen this error before..."
    echo ""

    # Search by error message field
    local response=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/claude_solutions" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        --data-urlencode "select=id,issue_title,solution_summary,error_message,tags,times_used,success_rate" \
        --data-urlencode "error_message=ilike.*${error_message}*" \
        --data-urlencode "order=success_rate.desc,times_used.desc" \
        --data-urlencode "limit=5")

    if echo "$response" | jq -e '. | length > 0' > /dev/null 2>&1; then
        echo "💡 Found matching error(s):"
        echo ""

        echo "$response" | jq -r '.[] | "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n📋 \(.issue_title)\n❌ Error: \(.error_message // "N/A")\n💡 Solution: \(.solution_summary)\n🏷️  Tags: \(.tags // [] | join(", "))\n📊 Used \(.times_used) times | Success rate: \(.success_rate * 100)%\n🆔 ID: \(.id)\n"'

        return 0
    else
        echo "❌ No matching errors found"
        return 1
    fi
}

# Find solutions by tags
find_by_tags() {
    local tags="$1"

    echo "🔍 Finding solutions tagged with: $tags"
    echo ""

    # Convert comma-separated tags to array for PostgreSQL
    local tags_array=$(echo "$tags" | sed 's/,/","/g' | sed 's/^/["/' | sed 's/$/"]/')

    # Search by tags (contains any of the specified tags)
    local response=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/claude_solutions" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        --data-urlencode "select=id,issue_title,solution_summary,tags,times_used,success_rate" \
        --data-urlencode "tags=cs.{${tags}}" \
        --data-urlencode "order=success_rate.desc,times_used.desc" \
        --data-urlencode "limit=10")

    if echo "$response" | jq -e '. | length > 0' > /dev/null 2>&1; then
        echo "💡 Found $(echo "$response" | jq '. | length') solution(s):"
        echo ""

        echo "$response" | jq -r '.[] | "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n📋 \(.issue_title)\n💡 Solution: \(.solution_summary)\n🏷️  Tags: \(.tags // [] | join(", "))\n📊 Used \(.times_used) times | Success rate: \(.success_rate * 100)%\n🆔 ID: \(.id)\n"'

        return 0
    else
        echo "❌ No solutions found with tags: $tags"
        return 1
    fi
}

# Get a specific solution by ID
get_solution() {
    local solution_id="$1"

    echo "📄 Fetching solution: $solution_id"
    echo ""

    local response=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/claude_solutions" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        --data-urlencode "select=*" \
        --data-urlencode "id=eq.${solution_id}")

    if echo "$response" | jq -e '. | length > 0' > /dev/null 2>&1; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "$response" | jq -r '.[0] | "📋 ISSUE: \(.issue_title)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ PROBLEM:
\(.issue_description)

\(if .error_message then "🔴 ERROR MESSAGE:\n\(.error_message)\n" else "" end)
💡 SOLUTION:
\(.solution_summary)

\(if .solution_steps then "📝 STEPS:\n\(.solution_steps)\n" else "" end)
\(if .code_changes then "💻 CODE CHANGES:\n\(.code_changes)\n" else "" end)
📊 METADATA:
• Feature: \(.feature_name // "N/A")
• File: \(.file_affected // "N/A")
• Technology: \(.technology_stack // "N/A")
• Tags: \(.tags // [] | join(", "))
• Error Type: \(.error_type // "N/A")

📈 USAGE STATS:
• Times used: \(.times_used)
• Success rate: \(.success_rate * 100)%
• Last used: \(.last_used_at // "Never")
• Created: \(.created_at)

🆔 ID: \(.id)"'
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        return 0
    else
        echo "❌ Solution not found: $solution_id"
        return 1
    fi
}

# Search for similar features
find_similar_features() {
    local feature_name="$1"

    echo "🔍 Looking for solutions related to feature: $feature_name"
    echo ""

    # Search by feature name
    local response=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/claude_solutions" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        --data-urlencode "select=id,issue_title,solution_summary,feature_name,tags,times_used,success_rate" \
        --data-urlencode "feature_name=ilike.*${feature_name}*" \
        --data-urlencode "order=success_rate.desc,times_used.desc" \
        --data-urlencode "limit=5")

    if echo "$response" | jq -e '. | length > 0' > /dev/null 2>&1; then
        echo "💡 Found similar feature solutions:"
        echo ""

        echo "$response" | jq -r '.[] | "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n📋 \(.issue_title)\n🔧 Feature: \(.feature_name)\n💡 Solution: \(.solution_summary)\n🏷️  Tags: \(.tags // [] | join(", "))\n📊 Used \(.times_used) times | Success rate: \(.success_rate * 100)%\n🆔 ID: \(.id)\n"'

        return 0
    else
        echo "❌ No solutions found for similar features"
        return 1
    fi
}

# Export functions
export -f search_solutions
export -f find_by_error
export -f find_by_tags
export -f get_solution
export -f find_similar_features

# If script is run directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <search_query>"
        echo ""
        echo "Examples:"
        echo "  $0 'database timeout'"
        echo "  ./solution-searcher.sh 'email validation'"
        exit 1
    fi

    search_solutions "$@"
fi
