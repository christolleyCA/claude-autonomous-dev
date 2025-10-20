#!/bin/bash
# ============================================================================
# VIEW SOLUTIONS - Browse and view the solution knowledge base
# ============================================================================

SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

# Source searcher functions if available
[ -f "./solution-searcher.sh" ] && source ./solution-searcher.sh

# Show top solutions by usage
show_top_solutions() {
    local count="${1:-10}"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🏆 TOP $count SOLUTIONS (by usage)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    local response=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/claude_solutions" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        --data-urlencode "select=id,issue_title,solution_summary,tags,times_used,success_rate" \
        --data-urlencode "order=times_used.desc,success_rate.desc" \
        --data-urlencode "limit=${count}")

    if echo "$response" | jq -e '. | length > 0' > /dev/null 2>&1; then
        echo "$response" | jq -r 'to_entries[] | "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n#\(.key + 1). \(.value.issue_title)\n💡 Solution: \(.value.solution_summary)\n🏷️  Tags: \(.value.tags // [] | join(", "))\n📊 Used \(.value.times_used) times | Success rate: \(.value.success_rate * 100)%\n🆔 ID: \(.value.id)\n"'
    else
        echo "❌ No solutions found in knowledge base"
        echo "💡 Tip: Start logging solutions to build your knowledge base!"
    fi
}

# Show recent solutions
show_recent() {
    local count="${1:-10}"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📅 RECENT $count SOLUTIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    local response=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/claude_solutions" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        --data-urlencode "select=id,issue_title,solution_summary,tags,times_used,success_rate,created_at" \
        --data-urlencode "order=created_at.desc" \
        --data-urlencode "limit=${count}")

    if echo "$response" | jq -e '. | length > 0' > /dev/null 2>&1; then
        echo "$response" | jq -r '.[] | "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n📋 \(.issue_title)\n💡 Solution: \(.solution_summary)\n🏷️  Tags: \(.tags // [] | join(", "))\n📊 Used \(.times_used) times | Success rate: \(.success_rate * 100)%\n📅 Created: \(.created_at)\n🆔 ID: \(.id)\n"'
    else
        echo "❌ No solutions found in knowledge base"
    fi
}

# Show knowledge base statistics
show_stats() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 KNOWLEDGE BASE STATISTICS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Get total count
    local total=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/claude_solutions" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        --data-urlencode "select=count" \
        -H "Prefer: count=exact" | jq -r '.[0].count // 0' 2>/dev/null || echo "0")

    echo "📚 Total Solutions: $total"
    echo ""

    if [ "$total" -eq 0 ]; then
        echo "💡 No solutions yet! Start logging with: ./solution-logger.sh"
        return
    fi

    # Get most used solution
    local most_used=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/claude_solutions" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        --data-urlencode "select=issue_title,times_used,success_rate" \
        --data-urlencode "order=times_used.desc" \
        --data-urlencode "limit=1" | jq -r '.[0] // empty')

    if [ -n "$most_used" ]; then
        echo "🏆 Most Used Solution:"
        echo "$most_used" | jq -r '"   \(.issue_title)\n   Used \(.times_used) times | Success rate: \(.success_rate * 100)%"'
        echo ""
    fi

    # Get highest success rate (with at least 2 uses)
    local best_success=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/claude_solutions" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        --data-urlencode "select=issue_title,times_used,success_rate" \
        --data-urlencode "times_used=gte.2" \
        --data-urlencode "order=success_rate.desc,times_used.desc" \
        --data-urlencode "limit=1" | jq -r '.[0] // empty')

    if [ -n "$best_success" ]; then
        echo "🎯 Highest Success Rate:"
        echo "$best_success" | jq -r '"   \(.issue_title)\n   Success rate: \(.success_rate * 100)% (used \(.times_used) times)"'
        echo ""
    fi

    # Get most common tags
    echo "🏷️  Most Common Tags:"
    local all_solutions=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/claude_solutions" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        --data-urlencode "select=tags")

    echo "$all_solutions" | jq -r '.[].tags[]? // empty' | sort | uniq -c | sort -rn | head -5 | awk '{print "   " $2 " (" $1 " times)"}'
    echo ""

    # Recent activity
    local recent_count=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/claude_solutions" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        --data-urlencode "select=count" \
        --data-urlencode "created_at=gte.$(date -u -v-7d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d '7 days ago' +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo '2000-01-01T00:00:00Z')" \
        -H "Prefer: count=exact" | jq -r '.[0].count // 0' 2>/dev/null || echo "0")

    echo "📈 Activity:"
    echo "   New solutions this week: $recent_count"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Interactive search interface
interactive_search() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 SOLUTION KNOWLEDGE BASE - INTERACTIVE SEARCH"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Commands:"
    echo "  <search terms>  - Search for solutions"
    echo "  tags <tags>     - Search by tags"
    echo "  error <msg>     - Search by error message"
    echo "  id <id>         - View specific solution"
    echo "  stats           - Show statistics"
    echo "  recent [N]      - Show recent solutions"
    echo "  top [N]         - Show top solutions"
    echo "  quit            - Exit"
    echo ""

    while true; do
        echo -n "🔍 > "
        read -r input

        if [ -z "$input" ]; then
            continue
        fi

        # Parse command
        local cmd=$(echo "$input" | awk '{print $1}')
        local args=$(echo "$input" | cut -d' ' -f2-)

        case "$cmd" in
            quit|exit|q)
                echo "👋 Goodbye!"
                break
                ;;
            stats)
                show_stats
                ;;
            recent)
                show_recent "${args:-10}"
                ;;
            top)
                show_top_solutions "${args:-10}"
                ;;
            tags)
                if command -v find_by_tags &> /dev/null; then
                    find_by_tags "$args"
                else
                    echo "❌ tags command not available"
                fi
                ;;
            error)
                if command -v find_by_error &> /dev/null; then
                    find_by_error "$args"
                else
                    echo "❌ error command not available"
                fi
                ;;
            id)
                if command -v get_solution &> /dev/null; then
                    get_solution "$args"
                else
                    echo "❌ id command not available"
                fi
                ;;
            help|h|\?)
                echo "Commands: <search> | tags <tags> | error <msg> | id <id> | stats | recent | top | quit"
                ;;
            *)
                if command -v search_solutions &> /dev/null; then
                    search_solutions "$input"
                else
                    echo "❌ search command not available"
                fi
                ;;
        esac
        echo ""
    done
}

# Show all tags available
show_all_tags() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🏷️  ALL AVAILABLE TAGS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    local all_solutions=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/claude_solutions" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        --data-urlencode "select=tags")

    local tags=$(echo "$all_solutions" | jq -r '.[].tags[]? // empty' | sort -u)

    if [ -n "$tags" ]; then
        echo "$tags" | while read -r tag; do
            local count=$(echo "$all_solutions" | jq -r ".[].tags[]? // empty" | grep -c "^${tag}$")
            echo "  • $tag ($count solution(s))"
        done
    else
        echo "  No tags found"
    fi

    echo ""
}

# Export functions
export -f show_top_solutions
export -f show_recent
export -f show_stats
export -f interactive_search
export -f show_all_tags

# If script is run directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-}" in
        stats)
            show_stats
            ;;
        recent)
            show_recent "${2:-10}"
            ;;
        top)
            show_top_solutions "${2:-10}"
            ;;
        tags)
            show_all_tags
            ;;
        interactive|search)
            interactive_search
            ;;
        *)
            echo "Usage: $0 {stats|recent|top|tags|interactive}"
            echo ""
            echo "Commands:"
            echo "  stats       - Show knowledge base statistics"
            echo "  recent [N]  - Show N recent solutions (default: 10)"
            echo "  top [N]     - Show top N solutions by usage (default: 10)"
            echo "  tags        - Show all available tags"
            echo "  interactive - Interactive search mode"
            echo ""
            echo "Example: $0 stats"
            ;;
    esac
fi
