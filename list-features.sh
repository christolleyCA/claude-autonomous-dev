#!/bin/bash
# List Features - Show all features built by build-feature.sh and discover existing ones

# ============================================================================
# CONFIGURATION
# ============================================================================

REGISTRY_FILE="/Users/christophertolleymacbook2019/.feature-registry.json"
SUPABASE_PROJECT_ID="hjtvtkffpziopozmtsnb"
N8N_URL="https://n8n.grantpilot.app"

# ============================================================================
# HELPERS
# ============================================================================

# Ensure registry exists
mkdir -p "$(dirname "$REGISTRY_FILE")"
touch "$REGISTRY_FILE"

# Initialize registry if empty
if [ ! -s "$REGISTRY_FILE" ]; then
    echo "[]" > "$REGISTRY_FILE"
fi

# ============================================================================
# DISCOVERY FUNCTIONS
# ============================================================================

discover_edge_functions() {
    echo "📦 Discovering Supabase Edge Functions..."
    echo ""

    # Use Claude Code MCP to list functions
    local functions=$(claude code execute mcp__supabase__list_edge_functions \
        --project_id "$SUPABASE_PROJECT_ID" 2>&1)

    echo "$functions" | jq -r '.[] | "  - \(.name)"' 2>/dev/null || echo "  (Unable to fetch)"
    echo ""
}

discover_n8n_workflows() {
    echo "⚙️  Discovering N8n Workflows..."
    echo ""

    # Use Claude Code MCP to list workflows
    local workflows=$(claude code execute mcp__n8n-mcp__n8n_list_workflows 2>&1)

    echo "$workflows" | jq -r '.[] | "  - \(.name)"' 2>/dev/null || echo "  (Unable to fetch)"
    echo ""
}

list_build_directories() {
    echo "📁 Build Directories (last 10)..."
    echo ""

    if [ -d "/tmp/autonomous-builds" ]; then
        ls -lt /tmp/autonomous-builds | head -11 | tail -10 | awk '{print "  - " $9}'
    else
        echo "  (No build directories found)"
    fi
    echo ""
}

# ============================================================================
# REGISTRY FUNCTIONS
# ============================================================================

show_registry() {
    local registry_content=$(cat "$REGISTRY_FILE" 2>/dev/null || echo "[]")
    local count=$(echo "$registry_content" | jq 'length' 2>/dev/null || echo "0")

    echo "📋 Feature Registry (${count} features)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ "$count" -eq 0 ]; then
        echo "  No features in registry yet."
        echo ""
        echo "  💡 Tip: Features built with build-feature.sh will be automatically registered."
        echo ""
        return
    fi

    # Show features in a nice table format
    echo "$registry_content" | jq -r '
        .[] |
        "Feature: \(.name)
  Description: \(.description)
  Built: \(.timestamp)
  Status: \(.status)
  Build Dir: \(.build_dir)
  Edge Function: https://hjtvtkffpziopozmtsnb.supabase.co/functions/v1/\(.name)
  "
    ' 2>/dev/null

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

search_registry() {
    local search_term="$1"
    local registry_content=$(cat "$REGISTRY_FILE" 2>/dev/null || echo "[]")

    echo "🔍 Searching for: \"${search_term}\""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    local results=$(echo "$registry_content" | jq -r --arg term "$search_term" '
        .[] |
        select(.name | contains($term)) // select(.description | contains($term)) |
        "Feature: \(.name)
  Description: \(.description)
  Built: \(.timestamp)
  "
    ' 2>/dev/null)

    if [ -z "$results" ]; then
        echo "  No features found matching \"${search_term}\""
    else
        echo "$results"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

show_feature_details() {
    local feature_name="$1"
    local registry_content=$(cat "$REGISTRY_FILE" 2>/dev/null || echo "[]")

    local feature=$(echo "$registry_content" | jq --arg name "$feature_name" '.[] | select(.name == $name)' 2>/dev/null)

    if [ -z "$feature" ]; then
        echo "❌ Feature '${feature_name}' not found in registry"
        echo ""
        echo "Run: ./list-features.sh --all"
        echo "Or:  ./list-features.sh --search <term>"
        return 1
    fi

    echo "📋 Feature Details: ${feature_name}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "$feature" | jq -r '
        "Name:        \(.name)
Description: \(.description)
Status:      \(.status)
Built:       \(.timestamp)
Build Dir:   \(.build_dir)

Edge Function URL:
  https://hjtvtkffpziopozmtsnb.supabase.co/functions/v1/\(.name)

N8n Workflow:
  Search for: [ACTIVE] [\(.name)]

Files:
  - Plan:      \(.build_dir)/plan.md
  - Code:      \(.build_dir)/index.ts
  - Workflow:  \(.build_dir)/workflow.json
  - Tests:     \(.build_dir)/test-cases.sh
"
    ' 2>/dev/null

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

show_all_systems() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 COMPLETE FEATURE INVENTORY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Show registry
    show_registry
    echo ""

    # Show edge functions
    discover_edge_functions

    # Show N8n workflows
    discover_n8n_workflows

    # Show build directories
    list_build_directories
}

export_registry() {
    local output_file="${1:-features-export.json}"

    cp "$REGISTRY_FILE" "$output_file"
    echo "✅ Registry exported to: ${output_file}"
}

# ============================================================================
# CLI
# ============================================================================

show_usage() {
    cat <<EOF
List Features - View all features built by your autonomous system

Usage: $0 [OPTIONS]

Options:
  --all              Show complete inventory (registry + Supabase + N8n)
  --registry         Show only the feature registry
  --search <term>    Search registry by name or description
  --details <name>   Show detailed info for a specific feature
  --edge-functions   List all Supabase Edge Functions
  --workflows        List all N8n Workflows
  --builds           List recent build directories
  --export [file]    Export registry to JSON file
  --help             Show this help message

Examples:
  # Show everything
  $0 --all

  # Show just the registry
  $0 --registry

  # Search for features
  $0 --search email
  $0 --search "grant"

  # Get details on a specific feature
  $0 --details hello-world-test

  # Quick discovery
  $0 --edge-functions
  $0 --workflows

Default (no options): Shows registry
EOF
}

# Parse arguments
case "${1:-}" in
    --all)
        show_all_systems
        ;;
    --registry)
        show_registry
        ;;
    --search)
        if [ -z "$2" ]; then
            echo "Error: --search requires a search term"
            exit 1
        fi
        search_registry "$2"
        ;;
    --details)
        if [ -z "$2" ]; then
            echo "Error: --details requires a feature name"
            exit 1
        fi
        show_feature_details "$2"
        ;;
    --edge-functions)
        discover_edge_functions
        ;;
    --workflows)
        discover_n8n_workflows
        ;;
    --builds)
        list_build_directories
        ;;
    --export)
        export_registry "$2"
        ;;
    --help|-h)
        show_usage
        ;;
    "")
        # Default: show registry
        show_registry
        ;;
    *)
        echo "Unknown option: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac
