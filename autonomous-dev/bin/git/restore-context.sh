#!/bin/bash
# Restores context about what we were working on

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

restore_context() {
    echo "🔍 RESTORING CONTEXT FROM LAST SESSION"
    echo "════════════════════════════════════════"
    echo ""

    # Last commit
    echo "📅 LAST COMMIT:"
    if git log -1 --format="%h" &> /dev/null; then
        git log -1 --pretty=format:"   Commit: %h%n   Date:   %ad%n   Message: %s" --date=format:'%Y-%m-%d %H:%M'
        echo ""
        echo ""
    else
        echo "   No commits yet"
        echo ""
    fi

    # Recent commits
    echo "📊 RECENT ACTIVITY (Last 10 commits):"
    if git log -10 --format="%h" &> /dev/null 2>&1; then
        git log -10 --pretty=format:"   %ad %h %s" --date=format:'%m/%d %H:%M'
        echo ""
        echo ""
    else
        echo "   No commit history"
        echo ""
    fi

    # Changed files in last commit
    echo "📁 FILES CHANGED IN LAST COMMIT:"
    if git log -1 --format="%h" &> /dev/null; then
        git diff-tree --no-commit-id --name-only -r HEAD | head -15 | sed 's/^/      /'
        echo ""
    fi

    # Current state
    echo "📂 CURRENT STATE:"
    local uncommitted=$(git status --porcelain | wc -l | tr -d ' ')
    echo "   Uncommitted changes: $uncommitted files"

    if [ $uncommitted -gt 0 ]; then
        echo "   Files:"
        git status --short | head -10 | sed 's/^/      /'
        echo ""
        echo "   💡 Tip: Run './smart-git-commit.sh push' to commit and backup"
    fi
    echo ""

    # Check if services are running
    echo "🚀 SERVICES STATUS:"
    if pgrep -f "start-remote-access.sh" > /dev/null; then
        echo "   ✅ Remote access: Running"
    else
        echo "   ⚠️  Remote access: Not running"
        echo "      Start with: ./start-everything.sh"
    fi

    if pgrep -f "watchdog.sh" > /dev/null; then
        echo "   ✅ Watchdog: Running"
    else
        echo "   ℹ️  Watchdog: Not running (optional)"
    fi
    echo ""

    # Check for heartbeat file (shows if remote access was recently active)
    if [ -f "/tmp/claude-remote-access-heartbeat" ]; then
        local heartbeat_time=$(cat /tmp/claude-remote-access-heartbeat 2>/dev/null)
        if [ -n "$heartbeat_time" ]; then
            echo "💓 LAST REMOTE ACCESS:"
            echo "   $(date -r "$heartbeat_time" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'Recently active')"
            echo ""
        fi
    fi

    # Query Supabase for recent builds (if credentials exist)
    if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_ANON_KEY" ]; then
        echo "🏗️ RECENT FEATURES BUILT:"
        query_recent_builds
        echo ""

        echo "💡 RECENT SOLUTIONS ADDED:"
        query_recent_solutions
        echo ""

        echo "⚡ RECENT COMMANDS:"
        query_recent_commands
        echo ""
    else
        echo "💡 TIP: Set SUPABASE_URL and SUPABASE_ANON_KEY to see build history"
        echo ""
    fi

    # Summary
    echo "════════════════════════════════════════"
    echo "✅ CONTEXT RESTORED - Ready to continue!"
    echo ""
    echo "📖 QUICK START:"
    echo "   • Check docs: cat GETTING-STARTED.md"
    echo "   • Git status: git status"
    echo "   • Commit work: ./smart-git-commit.sh push"
    echo "   • Remote access: ./start-everything.sh"
    echo ""
}

query_recent_builds() {
    # This would use Supabase MCP to query build_history
    # For now, show placeholder
    echo "   (Connect Supabase MCP to see build history)"
    echo "   Recent builds will appear here once Supabase is configured"
}

query_recent_solutions() {
    # This would use Supabase MCP to query claude_solutions
    echo "   (Connect Supabase MCP to see solutions)"
    echo "   Recent solutions will appear here once Supabase is configured"
}

query_recent_commands() {
    # This would use Supabase MCP to query claude_commands
    echo "   (Connect Supabase MCP to see command history)"
    echo "   Recent commands will appear here once Supabase is configured"
}

# If called directly (not sourced), execute
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    restore_context
else
    export -f restore_context
    export -f query_recent_builds
    export -f query_recent_solutions
    export -f query_recent_commands
fi
