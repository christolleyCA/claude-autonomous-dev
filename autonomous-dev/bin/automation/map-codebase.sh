#!/bin/bash
# ============================================================================
# MAP CODEBASE - Context-Aware Codebase Analysis and Mapping
# ============================================================================

SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

# Source Slack logger
[ -f "./slack-logger.sh" ] && source ./slack-logger.sh

# Map entire codebase
map_codebase() {
    local base_dir="${1:-.}"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗺️  CODEBASE MAPPING"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if command -v send_to_slack &> /dev/null; then
        send_to_slack "🗺️ *Mapping Codebase*
Directory: ${base_dir}
Analyzing project structure..."
    fi

    # Find all relevant files
    local script_files=$(find "$base_dir" -name "*.sh" -type f ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
    local ts_files=$(find "$base_dir" -name "*.ts" -type f ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
    local total_files=$((script_files + ts_files))

    echo "📊 Project Overview:"
    echo "   Shell Scripts: $script_files"
    echo "   TypeScript Files: $ts_files"
    echo "   Total Files: $total_files"
    echo ""

    # Analyze patterns
    echo "🔍 Analyzing patterns..."

    local function_count=0
    local reusable_components=0

    # Map shell scripts
    find "$base_dir" -name "*.sh" -type f ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | while read -r file; do
        local relative_path=$(echo "$file" | sed "s|^$base_dir/||")
        local functions=$(grep -c "^[a-zA-Z_][a-zA-Z0-9_]*() {" "$file" || echo "0")
        local lines=$(wc -l < "$file" | tr -d ' ')

        ((function_count += functions))

        # Determine if reusable
        local reusable=false
        if grep -q "export -f" "$file"; then
            reusable=true
            ((reusable_components++))
        fi

        # Log to database
        curl -s -X POST \
            "${SUPABASE_URL}/rest/v1/codebase_map" \
            -H "apikey: ${SUPABASE_KEY}" \
            -H "Authorization: Bearer ${SUPABASE_KEY}" \
            -H "Content-Type: application/json" \
            -H "Prefer: resolution=merge-duplicates" \
            -d "{
                \"file_path\": \"$relative_path\",
                \"file_type\": \"shell\",
                \"lines_of_code\": $lines,
                \"reusable\": $reusable
            }" 2>/dev/null > /dev/null
    done

    echo "✅ Codebase mapped!"
    echo ""
    echo "📋 Summary:"
    echo "   Total Functions: $function_count"
    echo "   Reusable Components: $reusable_components"
    echo ""

    if command -v send_to_slack &> /dev/null; then
        send_to_slack "✅ *Codebase Mapped*

Files Analyzed: ${total_files}
Functions Found: ${function_count}
Reusable Components: ${reusable_components}

Claude Code now understands your codebase! 🧠"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    return 0
}

# Find similar files
find_similar() {
    local file_path="$1"

    echo "🔍 Finding files similar to: $file_path"

    # Query database for similar files
    local similar=$(curl -s -G \
        "${SUPABASE_URL}/rest/v1/codebase_map" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        --data-urlencode "select=file_path,file_type,reusable" \
        --data-urlencode "file_type=eq.shell" \
        --data-urlencode "reusable=eq.true" \
        --data-urlencode "limit=10")

    if echo "$similar" | jq -e '. | length > 0' > /dev/null 2>&1; then
        echo ""
        echo "Similar Reusable Files:"
        echo "$similar" | jq -r '.[] | "  • \(.file_path)"'
    else
        echo "No similar files found"
    fi
}

export -f map_codebase
export -f find_similar

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-}" in
        similar)
            if [ $# -lt 2 ]; then
                echo "Usage: $0 similar <file-path>"
                exit 1
            fi
            find_similar "$2"
            ;;
        *)
            map_codebase "${1:-.}"
            ;;
    esac
fi
