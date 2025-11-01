#!/bin/bash
# Smart git commit - analyzes changes and creates descriptive message

# Get the Slack function
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Try to source send-to-slack from automation directory
if [ -f "$PROJECT_DIR/bin/automation/send-to-slack.sh" ]; then
    source "$PROJECT_DIR/bin/automation/send-to-slack.sh"
elif [ -f "$SCRIPT_DIR/send-to-slack.sh" ]; then
    source "$SCRIPT_DIR/send-to-slack.sh"
fi

smart_commit() {
    local push_flag="${1:-no}"

    echo "📊 Analyzing changes..."

    # Check if there are changes
    if [ -z "$(git status --porcelain)" ]; then
        echo "ℹ️  No changes to commit"
        return 0
    fi

    # Get change statistics
    local files_changed=$(git status --short | wc -l | tr -d ' ')
    local new_files=$(git status --short | grep "^??" | wc -l | tr -d ' ')
    local modified_files=$(git status --short | grep "^ M" | wc -l | tr -d ' ')

    # Get list of changed files
    local changed_list=$(git status --short | head -20)

    # Build smart commit message
    local commit_msg="Session update: "
    local details=""

    # Analyze what changed
    if echo "$changed_list" | grep -q "build-feature\|autonomous-builder\|feature-builder"; then
        details+="Enhanced build-feature system, "
    fi

    if echo "$changed_list" | grep -q "nonprofit\|intelligence"; then
        details+="Worked on nonprofit intelligence, "
    fi

    if echo "$changed_list" | grep -q "knowledge\|solution"; then
        details+="Updated knowledge base, "
    fi

    if echo "$changed_list" | grep -q "\.sql\|schema\|table\|supabase"; then
        details+="Database schema updates, "
    fi

    if echo "$changed_list" | grep -q "\.sh"; then
        details+="Added/updated scripts, "
    fi

    if echo "$changed_list" | grep -q "\.md\|README\|GETTING-STARTED"; then
        details+="Documentation updates, "
    fi

    if echo "$changed_list" | grep -q "\.ts\|\.js\|\.py"; then
        details+="Code changes, "
    fi

    if echo "$changed_list" | grep -q "git\|commit\|restore"; then
        details+="Git automation improvements, "
    fi

    if echo "$changed_list" | grep -q "remote-access\|slack\|command"; then
        details+="Remote access enhancements, "
    fi

    # Remove trailing comma and space
    details=${details%, }

    # If we found specific changes, use them
    if [ -n "$details" ]; then
        commit_msg+="$details - "
    fi

    # Add file count
    commit_msg+="${files_changed} files"

    # Show what we're committing
    echo ""
    echo "📝 Changes to commit:"
    echo "$changed_list"
    echo ""
    echo "💬 Commit message:"
    echo "   $commit_msg"
    echo ""

    # Add only tracked modified files (safe for home directories)
    # -u flag stages modifications and deletions of tracked files only
    git add -u

    # Commit with attribution
    git commit -m "$commit_msg" -m "🤖 Generated with Claude Code" -m "Co-Authored-By: Claude <noreply@anthropic.com>"

    local commit_hash=$(git log -1 --format="%h")
    echo "✅ Committed as $commit_hash"

    # Push if requested
    if [ "$push_flag" = "push" ]; then
        echo ""
        echo "🌐 Pushing to GitHub..."
        local current_branch=$(git branch --show-current)

        # Capture push output and exit code
        local push_output
        local push_exit_code
        push_output=$(git push origin "$current_branch" 2>&1)
        push_exit_code=$?

        # Wait for any background processes to complete
        wait

        if [ $push_exit_code -eq 0 ]; then
            echo "✅ Pushed successfully!"

            # Send to Slack if function exists
            if type send_to_slack &>/dev/null; then
                send_to_slack "✅ *Git Backup Complete*
Commit: \`$commit_hash\`
Message: $commit_msg
Pushed to GitHub ✓" &
                # Wait for Slack notification to complete
                wait
            fi
        else
            echo "❌ Push failed"
            echo "$push_output"

            # Send to Slack if function exists
            if type send_to_slack &>/dev/null; then
                send_to_slack "⚠️ Git committed locally but push failed
Commit: \`$commit_hash\`
Check internet connection" &
                # Wait for Slack notification to complete
                wait
            fi
        fi
    else
        echo ""
        echo "💡 To push: git push"
        echo "💡 Or run: ./smart-git-commit.sh push"
    fi

    # Ensure all child processes have completed before exiting
    wait
}

# If called directly (not sourced), execute
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    smart_commit "$@"
else
    export -f smart_commit
fi
