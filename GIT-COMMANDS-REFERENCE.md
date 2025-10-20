# Git Commands Reference

Complete guide to using Git with your autonomous development system.

## Loading Git Helpers

The git-helpers.sh functions are automatically loaded when you source the file:

```bash
source ~/git-helpers.sh
```

Or add to your `~/.bashrc` or `~/.zshrc` to load automatically:

```bash
# Add this line:
source ~/git-helpers.sh
```

## Quick Commands

### From Terminal

```bash
# View status
git_status_detailed

# Commit changes
git_commit "Fixed email bug"

# Commit and push
git_commit_push "Add new feature"

# View recent commits
git_recent 10

# Create savepoint before risky change
git_savepoint "before-database-migration"
```

### From Slack (via /cc commands)

You can use Git commands from anywhere via Slack:

```
/cc git_status_detailed
/cc git_commit "Fixed grants processing bug"
/cc git_recent 20
/cc git_savepoint "before-major-refactor"
```

## All Available Commands

### 1. Basic Operations

#### git_commit
Commit all changes with a descriptive message.

```bash
git_commit "Add email validation feature"
```

**What it does:**
- Stages all changes (`git add .`)
- Creates commit with timestamp
- Formats: `[2025-01-20 15:30] Add email validation feature`

#### git_commit_push
Commit and immediately push to GitHub.

```bash
git_commit_push "Fix payment processing bug"
```

**What it does:**
- Stages all changes
- Commits with message
- Pushes to current branch on GitHub

### 2. Branch Operations

#### git_create_branch
Create and switch to a new branch.

```bash
git_create_branch "feature/email-notifications"
```

**Use cases:**
- Starting a new feature
- Experimental changes
- Isolating work

#### git_switch
Switch to an existing branch.

```bash
git_switch "main"
git_switch "feature/payment-processor"
```

#### git_branches
List all branches (local and remote).

```bash
git_branches
```

**Output:**
```
📋 All branches:
* main
  feature/email-notifications
  feature/payment-processor
  remotes/origin/main
```

### 3. Safety & Rollback

#### git_rollback
Undo recent commits (with confirmation).

```bash
# Undo last commit
git_rollback 1

# Undo last 3 commits
git_rollback 3
```

**⚠️ Warning:** This is destructive! You'll be asked to confirm.

**What it shows:**
```
⚠️  About to roll back 1 commit(s)
Current HEAD:
abc123 Add feature: payment-processor

Will reset to:
def456 Fix email validation

Continue? (y/n)
```

#### git_savepoint
Create a tagged savepoint before risky changes.

```bash
git_savepoint "before-database-migration"
git_savepoint "working-version"
git_savepoint "v1.0-stable"
```

**What it does:**
- Commits current state
- Creates tag: `savepoint-YOURNAME`
- Easy to restore later

**Use before:**
- Database migrations
- Major refactors
- Risky deployments
- Version milestones

#### git_savepoints
List all your savepoints.

```bash
git_savepoints
```

**Output:**
```
💾 All savepoints:
savepoint-before-database-migration
savepoint-working-version
savepoint-v1.0-stable
```

#### git_restore_savepoint
Restore code to a previous savepoint.

```bash
git_restore_savepoint "before-database-migration"
```

**Use when:**
- Something broke after changes
- Need to go back to known-good state
- Want to compare with previous version

### 4. Viewing History

#### git_status_detailed
Comprehensive status overview.

```bash
git_status_detailed
```

**Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 GIT STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌿 Current Branch: main

✅ Up to date with origin

M  build-feature.sh
A  new-feature.ts

📝 Last Commit:
abc123 - Add feature: payment-processor (2 hours ago by Claude)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Shows:**
- Current branch
- Sync status with GitHub
- Modified files
- Last commit info

#### git_recent
Show recent commit history.

```bash
# Last 10 commits (default)
git_recent

# Last 20 commits
git_recent 20

# Last 5 commits
git_recent 5
```

**Output:**
```
📜 Last 10 commits:
* abc123 (HEAD -> main) Add feature: payment-processor
* def456 Fix email validation
* ghi789 Update documentation
* jkl012 Add Sentry integration
```

#### git_search
Search commit messages.

```bash
git_search "email"
git_search "fix"
git_search "payment"
```

**Output:**
```
🔍 Searching for: email
abc123 Add email validation feature
def456 Fix email sending bug
ghi789 Update email templates
```

**Use to:**
- Find when you implemented something
- Locate bug fixes
- Track feature development

#### git_show_last
Show detailed changes in last commit.

```bash
git_show_last
```

**Output:**
```
📄 Changes in last commit:
commit abc123
Author: Claude <noreply@anthropic.com>
Date:   Mon Jan 20 15:30:00 2025

    Add feature: payment-processor

 payment-processor.ts | 127 +++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 127 insertions(+)
```

### 5. Feature Build Integration

These are used internally by `build-feature.sh`, but you can also use them manually.

#### git_build_feature
Prepare for building a feature (creates branch).

```bash
git_build_feature "email-sender" "Send emails via SendGrid"
```

**What it does:**
- Creates branch: `feature/email-sender`
- Switches to that branch
- Ready for development

#### git_complete_feature
Complete feature build (commit and optionally merge).

```bash
# Just commit and push
git_complete_feature "email-sender" "Send emails via SendGrid" "no"

# Commit, push, AND merge to main
git_complete_feature "email-sender" "Send emails via SendGrid" "yes"
```

**With auto-merge:**
- Commits feature
- Pushes to GitHub
- Merges to main
- Pushes main to GitHub

### 6. Cleanup

#### git_cleanup_branches
Delete merged feature branches.

```bash
git_cleanup_branches
```

**What it does:**
- Switches to main
- Finds branches merged into main
- Deletes feature branches
- Keeps main clean

**Safe:** Only deletes already-merged branches!

## Real-World Workflows

### Workflow 1: Quick Fix

```bash
# See what's changed
git_status_detailed

# Commit the fix
git_commit "Fix grants processing timeout"

# Push to GitHub
git_commit_push "Fix grants processing timeout"
```

### Workflow 2: Risky Change

```bash
# Create savepoint first
git_savepoint "before-refactor"

# Make your risky changes
# ...edit files...

# Test it
# If it breaks:
git_restore_savepoint "before-refactor"

# If it works:
git_commit "Refactor grants processing logic"
```

### Workflow 3: Feature Development

```bash
# Create feature branch
git_create_branch "feature/pdf-export"

# Work on feature
# ...edit files...

# Commit progress
git_commit "Add PDF generation logic"
git_commit "Add PDF styling"
git_commit "Add PDF tests"

# Merge when done
git_switch "main"
git merge "feature/pdf-export"
git_push
```

### Workflow 4: View History

```bash
# See recent work
git_recent 20

# Find specific change
git_search "email"

# View last change details
git_show_last

# Check current status
git_status_detailed
```

## Using from Slack

Your remote access system allows Git commands from Slack!

### Examples:

```
YOU: /cc git_status_detailed

CLAUDE:
📊 GIT STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌿 Current Branch: main
✅ Up to date with origin
...
```

```
YOU: /cc git_commit "Fix email bug"

CLAUDE: ✅ Committed: Fix email bug
```

```
YOU: /cc git_recent 10

CLAUDE:
📜 Last 10 commits:
* abc123 Fix email bug
* def456 Add payment processor
...
```

```
YOU: /cc git_savepoint "before-major-change"

CLAUDE: ✅ Created savepoint: before-major-change
```

## Automatic Git Integration

When you build features with `build-feature.sh`:

```bash
./build-feature.sh my-feature "Description"
```

**Automatically happens:**
1. ✅ Feature is built
2. ✅ Tests are run
3. ✅ Changes are committed
4. ✅ Commit is pushed to GitHub
5. ✅ Feature registry is updated

**Commit message format:**
```
Add feature: my-feature

Description: [your description]
Build Time: 3m 45s

Components:
- Edge Function: /tmp/autonomous-builds/my-feature-123/index.ts
- N8n Workflow: /tmp/autonomous-builds/my-feature-123/workflow.json
- Tests: /tmp/autonomous-builds/my-feature-123/test-cases.sh

🤖 Generated with Claude Code Autonomous System

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────────┐
│                      QUICK GIT COMMANDS                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Status:                                                           │
│    git_status_detailed                                             │
│    git_recent 10                                                   │
│    git_search "keyword"                                            │
│                                                                     │
│  Commit:                                                           │
│    git_commit "message"                                            │
│    git_commit_push "message"                                       │
│                                                                     │
│  Safety:                                                           │
│    git_savepoint "name"                                            │
│    git_rollback 1                                                  │
│    git_restore_savepoint "name"                                    │
│                                                                     │
│  Branches:                                                         │
│    git_create_branch "name"                                        │
│    git_switch "name"                                               │
│    git_branches                                                    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Tips

### Before Major Changes
```bash
git_savepoint "working-version"
```

### After Completing Work
```bash
git_commit_push "Completed email notifications feature"
```

### When Something Breaks
```bash
git_rollback 1  # Undo last commit
# or
git_restore_savepoint "working-version"
```

### To See What You Did Today
```bash
git_recent 20
```

### To Find Old Changes
```bash
git_search "payment"
```

## Summary

You now have Git integrated into your autonomous development system!

- ✅ Every feature is automatically committed
- ✅ Changes are pushed to GitHub
- ✅ Full history is preserved
- ✅ Easy rollback if needed
- ✅ Professional version control

Use `git_status_detailed` anytime to see what's happening!
