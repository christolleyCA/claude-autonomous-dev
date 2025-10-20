#!/bin/bash
# Git Helper Functions for Autonomous Development System

# ============================================================================
# BASIC GIT OPERATIONS
# ============================================================================

# Commit current changes with descriptive message
git_commit() {
    local message="$1"

    if [ -z "$message" ]; then
        echo "❌ Error: Commit message required"
        echo "Usage: git_commit \"your commit message\""
        return 1
    fi

    # Add all changes
    git add .

    # Commit with timestamp
    local timestamp=$(date '+%Y-%m-%d %H:%M')
    git commit -m "[$timestamp] $message"

    echo "✅ Committed: $message"
}

# Commit and push in one command
git_commit_push() {
    local message="$1"

    if [ -z "$message" ]; then
        echo "❌ Error: Commit message required"
        echo "Usage: git_commit_push \"your commit message\""
        return 1
    fi

    # Add and commit
    git add .
    git commit -m "$message"

    # Push to current branch
    local current_branch=$(git branch --show-current)
    git push origin "$current_branch"

    echo "✅ Committed and pushed to: $current_branch"
}

# ============================================================================
# BRANCH OPERATIONS
# ============================================================================

# Create and switch to feature branch
git_create_branch() {
    local branch_name="$1"

    if [ -z "$branch_name" ]; then
        echo "❌ Error: Branch name required"
        echo "Usage: git_create_branch \"branch-name\""
        return 1
    fi

    git checkout -b "$branch_name"
    echo "✅ Created and switched to branch: $branch_name"
}

# Switch to existing branch
git_switch() {
    local branch_name="$1"

    if [ -z "$branch_name" ]; then
        echo "❌ Error: Branch name required"
        echo "Usage: git_switch \"branch-name\""
        return 1
    fi

    git checkout "$branch_name"
    echo "✅ Switched to branch: $branch_name"
}

# List all branches
git_branches() {
    echo "📋 All branches:"
    git branch -a
}

# ============================================================================
# SAFETY & ROLLBACK
# ============================================================================

# Safe rollback to previous commit(s)
git_rollback() {
    local commits="${1:-1}"

    echo "⚠️  About to roll back $commits commit(s)"
    echo "Current HEAD:"
    git log --oneline -n 1
    echo ""
    echo "Will reset to:"
    git log --oneline -n 1 HEAD~$commits
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git reset --hard HEAD~$commits
        echo "✅ Rolled back $commits commit(s)"
    else
        echo "❌ Rollback cancelled"
    fi
}

# Create a savepoint (tagged commit)
git_savepoint() {
    local name="$1"

    if [ -z "$name" ]; then
        echo "❌ Error: Savepoint name required"
        echo "Usage: git_savepoint \"savepoint-name\""
        return 1
    fi

    git add .
    git commit -m "SAVEPOINT: $name" || echo "(No changes to commit)"
    git tag "savepoint-$name"

    echo "✅ Created savepoint: $name"
    echo "To restore: git reset --hard savepoint-$name"
}

# List all savepoints
git_savepoints() {
    echo "💾 All savepoints:"
    git tag -l "savepoint-*"
}

# Restore to savepoint
git_restore_savepoint() {
    local name="$1"

    if [ -z "$name" ]; then
        echo "❌ Error: Savepoint name required"
        echo "Usage: git_restore_savepoint \"savepoint-name\""
        return 1
    fi

    git reset --hard "savepoint-$name"
    echo "✅ Restored to savepoint: $name"
}

# ============================================================================
# VIEWING HISTORY
# ============================================================================

# Show recent commits
git_recent() {
    local count="${1:-10}"

    echo "📜 Last $count commits:"
    git log --oneline --decorate --graph -n "$count"
}

# Show detailed status
git_status_detailed() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 GIT STATUS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Current branch
    local current_branch=$(git branch --show-current)
    echo "🌿 Current Branch: $current_branch"
    echo ""

    # Remote status
    git fetch origin > /dev/null 2>&1
    local ahead=$(git rev-list --count origin/$current_branch..$current_branch 2>/dev/null || echo "0")
    local behind=$(git rev-list --count $current_branch..origin/$current_branch 2>/dev/null || echo "0")

    if [ "$ahead" -gt 0 ]; then
        echo "⬆️  Ahead of origin by $ahead commit(s)"
    fi
    if [ "$behind" -gt 0 ]; then
        echo "⬇️  Behind origin by $behind commit(s)"
    fi
    if [ "$ahead" -eq 0 ] && [ "$behind" -eq 0 ]; then
        echo "✅ Up to date with origin"
    fi
    echo ""

    # File status
    git status -s
    echo ""

    # Last commit
    echo "📝 Last Commit:"
    git log -1 --pretty=format:"%h - %s (%cr by %an)"
    echo ""
    echo ""

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Search commits by message
git_search() {
    local search_term="$1"

    if [ -z "$search_term" ]; then
        echo "❌ Error: Search term required"
        echo "Usage: git_search \"search term\""
        return 1
    fi

    echo "🔍 Searching for: $search_term"
    git log --oneline --grep="$search_term" --all
}

# Show changes in last commit
git_show_last() {
    echo "📄 Changes in last commit:"
    git show --stat
}

# ============================================================================
# FEATURE BUILD INTEGRATION
# ============================================================================

# Autonomous feature build workflow
git_build_feature() {
    local feature_name="$1"
    local description="$2"

    if [ -z "$feature_name" ]; then
        echo "❌ Error: Feature name required"
        return 1
    fi

    # Create feature branch
    local branch_name="feature/${feature_name}"
    git checkout -b "$branch_name" 2>/dev/null || git checkout "$branch_name"

    echo "✅ On branch: $branch_name"
    echo "Ready to build feature: $feature_name"
    echo "Description: $description"
}

# Complete feature build (commit and optionally merge)
git_complete_feature() {
    local feature_name="$1"
    local description="$2"
    local auto_merge="${3:-no}"

    # Commit changes
    git add .
    git commit -m "Add feature: $feature_name - $description

🤖 Generated with Claude Code Autonomous System

Co-Authored-By: Claude <noreply@anthropic.com>"

    echo "✅ Committed feature: $feature_name"

    # Push to origin
    git push origin "feature/${feature_name}"
    echo "✅ Pushed to origin"

    # Auto-merge if requested
    if [ "$auto_merge" = "yes" ]; then
        git checkout main
        git merge "feature/${feature_name}" --no-ff -m "Merge feature: $feature_name"
        echo "✅ Merged to main"

        git push origin main
        echo "✅ Pushed main to origin"
    fi
}

# ============================================================================
# CLEANUP OPERATIONS
# ============================================================================

# Delete merged feature branches
git_cleanup_branches() {
    echo "🧹 Cleaning up merged branches..."

    git checkout main 2>/dev/null || git checkout master
    git branch --merged | grep "feature/" | xargs -I {} git branch -d {}

    echo "✅ Cleanup complete"
}

# ============================================================================
# QUICK COMMANDS
# ============================================================================

# Quick status (alias)
alias gs='git_status_detailed'

# Quick commit
alias gc='git_commit'

# Quick push
alias gp='git push'

# Quick pull
alias gl='git pull'

# Quick log
alias glog='git_recent'

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

export -f git_commit
export -f git_commit_push
export -f git_create_branch
export -f git_switch
export -f git_branches
export -f git_rollback
export -f git_savepoint
export -f git_savepoints
export -f git_restore_savepoint
export -f git_recent
export -f git_status_detailed
export -f git_search
export -f git_show_last
export -f git_build_feature
export -f git_complete_feature
export -f git_cleanup_branches

echo "✅ Git helpers loaded"
echo "Available commands: git_commit, git_commit_push, git_create_branch, git_rollback, git_savepoint, git_recent, git_status_detailed"
