

# 💬 Conversation Mirroring to Slack - Complete Guide

## Overview

Monitor Claude Code's output on your phone! All scripts send Claude Code's conversational output, file operations, and progress updates to Slack in real-time.

## 🎯 What You Get

### Before (Terminal Only)
```
YOU (at laptop): Working with Claude Code
CLAUDE: Creating files, running tests...
YOU: Need to leave
PROBLEM: No idea what's happening!
```

### After (With Slack Mirroring)
```
YOU (at laptop): Start Claude with mirroring
CLAUDE: Creating files, running tests...
YOU: Leave for errands
YOUR PHONE (Slack):
  📝 File Created: email-handler.ts
  🧪 Test: Email validation ✅
  ✅ Complete: All tests passed!
YOU: Check Slack, see everything worked!
```

## 🚀 Quick Start (3 Options)

### Option A: Full Session Mirroring (Verbose)

**Best for:** Short sessions, want to see everything

```bash
# Start Claude with full mirroring
./claude-with-slack.sh
```

**What you get in Slack:**
- Every line of output
- File operations
- Errors and warnings
- Complete session log

### Option B: Smart Summarizer (Recommended)

**Best for:** Long sessions, want highlights only

```bash
# Pipe Claude through smart summarizer
claude 2>&1 | ./claude-summary.sh
```

**What you get in Slack:**
- Immediate alerts for errors/warnings
- File create/update notifications
- Test results
- 5-minute summaries of activity

### Option C: Manual Notifications (Precise)

**Best for:** Want complete control

```bash
# Source the notification functions
source ./claude-ping.sh

# Use in your prompts:
claude_start "Building email feature"
claude_progress "Created database migration"
claude_complete "Email feature ready"
```

**What you get in Slack:**
- Only what you explicitly notify
- Clean, focused updates
- No noise

## 📋 Setup Instructions

### Step 1: Configure Slack Token

Edit `slack-logger.sh`:

```bash
nano slack-logger.sh

# Line 11 - Add your Slack bot token:
SLACK_TOKEN="xoxb-your-actual-token-here"

# Line 16 - Add your channel ID:
DEFAULT_LOG_CHANNEL="C1234567890"  # or D1234567890 for DM
```

Get your token and channel ID:
- **Token:** https://api.slack.com/apps → OAuth & Permissions → Bot User OAuth Token
- **Channel ID:** Open channel → Click name → Scroll to "Channel ID"
- **DM ID:** Open DM with yourself → Check URL for `D...` ID

### Step 2: Choose Your Approach

```bash
# Option A: Full mirroring
./claude-with-slack.sh

# Option B: Smart summarizer
claude 2>&1 | ./claude-summary.sh

# Option C: Manual notifications
source ./claude-ping.sh
# Then use claude_notify in your work
```

### Step 3: Start Working

Claude Code output automatically goes to Slack!

## 📱 What You'll See

### Full Session Mirroring

```
SLACK:
🚀 Claude Code Session Started
Started at: 3:45 PM EST
Hostname: MacBook-Pro
User: alice
Directory: /Users/alice/project

```
Creating email notification system...

File created: email-handler.ts
File created: send-email.ts
Running tests...
✅ All tests passed
```

🛑 Claude Code Session Ended
Ended at: 4:15 PM EST
Duration: 30m 0s
```

### Smart Summarizer

```
SLACK:
🚀 Claude Code Smart Monitor Started
Started at: 3:45 PM

📝 File Created: email-handler.ts

🧪 Test: Email validation test

✅ Success: All 15 tests passed

📊 Summary #1 (5min interval)
Total lines logged: 342
Recent activity: [last 20 lines]

📝 File Updated: package.json

🚀 Deploy: Deployed to production

🛑 Claude Code Smart Monitor Ended
```

### Manual Notifications

```
SLACK:
🏁 Started: Building email notification system

⚙️ Progress: Created database schema

⚙️ Progress: Implemented email handler

🧪 Test: Running email validation tests

✅ Complete: Email feature ready for review
```

## 🎛️ Advanced Usage

### Task Tracking with Duration

```bash
source ./claude-ping.sh

# Start a task (records start time)
claude_task_start "Build authentication system"

# ... do work ...

# Complete task (shows duration)
claude_task_complete "Build authentication system"
```

**Slack shows:**
```
🏁 Started: Build authentication system
... [time passes] ...
✅ Complete: Build authentication system (Duration: 23m 45s)
```

### Custom Channels for Different Tasks

```bash
# Development updates to #dev channel
claude_notify start "Building feature" "C_DEV_CHANNEL"

# Deployment updates to #ops channel
claude_notify deploy "Deploying v2.0" "C_OPS_CHANNEL"

# Errors to #alerts channel
claude_notify error "Database timeout" "C_ALERTS_CHANNEL"
```

### Integration with Prompts

Add to your Claude Code prompts:

```
Hey Claude, build an email notification feature.

Before you start:
source ./claude-ping.sh
claude_start "Building email notifications"

After each major step:
claude_progress "Step description"

When complete:
claude_complete "Email feature ready for review"
```

### Automated Workflow

```bash
#!/bin/bash
# daily-build.sh

source ./claude-ping.sh

claude_start "Daily build process"

# Run tests
if npm test; then
    claude_progress "Tests passed ✅"
else
    claude_error "Tests failed ❌"
    exit 1
fi

# Build
if npm run build; then
    claude_progress "Build successful ✅"
else
    claude_error "Build failed ❌"
    exit 1
fi

claude_complete "Daily build finished successfully"
```

## 📊 Comparison of Approaches

| Feature | Full Mirroring | Smart Summarizer | Manual Notifications |
|---------|----------------|------------------|---------------------|
| **Verbosity** | High | Medium | Low |
| **Setup** | Easy | Medium | Manual |
| **Noise** | Can be high | Filtered | Minimal |
| **Real-time** | Yes | Important only | Yes |
| **Best for** | Short sessions | Long sessions | Precise control |
| **CPU impact** | Low | Low | Minimal |
| **Customization** | Limited | Pattern-based | Complete |

## 🔧 Configuration

### slack-logger.sh Settings

```bash
# Token and channel
SLACK_TOKEN="xoxb-..."
DEFAULT_LOG_CHANNEL="C1234567890"

# Rate limiting (prevent spam)
MIN_SEND_INTERVAL=1  # Minimum 1 second between messages

# Log file location
LOG_FILE="/tmp/claude-code-slack-log.txt"
```

### claude-with-slack.sh Settings

```bash
# Buffer settings
BUFFER_SIZE=2000          # Max chars per message
PARAGRAPH_BREAK_LINES=2   # Blank lines = send
BUFFER_TIMEOUT=5          # Send after 5s idle
```

### claude-summary.sh Settings

```bash
# Summary interval
SUMMARY_INTERVAL=300  # 5 minutes

# Event detection patterns (customize!)
PATTERNS_ERROR="error|Error|ERROR|failed"
PATTERNS_SUCCESS="success|Success|completed"
PATTERNS_FILE_CREATED="created|Created|new file"
# ... and more
```

## 🎯 Recommended Workflows

### Workflow 1: Development Session

```bash
# Use smart summarizer for coding sessions
claude 2>&1 | ./claude-summary.sh
```

**Why:** Gets immediate alerts for errors but doesn't spam with every line

### Workflow 2: Important Feature

```bash
# Use manual notifications for critical work
source ./claude-ping.sh

# Add notifications at key points
claude_start "Building payment integration"
# ... work with Claude ...
claude_progress "Stripe API integrated"
# ... more work ...
claude_complete "Payment system ready"
```

**Why:** Precise control, clean notifications

### Workflow 3: Debugging Session

```bash
# Use full mirroring to see everything
./claude-with-slack.sh
```

**Why:** Need to see every detail to diagnose issues

### Workflow 4: Automated Task

```bash
# In cron job or CI/CD:
source ./claude-ping.sh
claude_start "Nightly database backup"
# ... run backup ...
claude_complete "Backup completed: 2.3GB"
```

**Why:** Track automated processes from anywhere

## 🐛 Troubleshooting

### "Token not configured"

**Solution:**
```bash
nano slack-logger.sh
# Line 11: Add your actual token
SLACK_TOKEN="xoxb-1234567890-..."
```

### Messages not appearing in Slack

**Check:**
1. Token is correct
2. Channel ID is correct
3. Bot is invited to channel: `/invite @YourBot`
4. Bot has `chat:write` scope

### Too many messages (spam)

**Solution 1:** Switch to smart summarizer
```bash
claude 2>&1 | ./claude-summary.sh
```

**Solution 2:** Increase buffer size
```bash
nano claude-with-slack.sh
# Line 9: Increase buffer
BUFFER_SIZE=5000
```

**Solution 3:** Use manual notifications only
```bash
source ./claude-ping.sh
# Only notify important events
```

### No notifications for errors

**For smart summarizer, check patterns:**
```bash
nano claude-summary.sh
# Lines 17-23: Customize error patterns
PATTERNS_ERROR="error|Error|ERROR|fail|exception"
```

## 💡 Tips & Tricks

### 1. Create Aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# Quick access
alias claude-mirror='cd /path/to && ./claude-with-slack.sh'
alias claude-smart='claude 2>&1 | /path/to/claude-summary.sh'
alias cn='source /path/to/claude-ping.sh && claude_notify'

# Usage:
claude-mirror  # Start full mirroring
cn start "Building feature"  # Quick notification
```

### 2. Different Channels per Project

```bash
# In your project directory
cat > .claude-config <<EOF
export DEFAULT_LOG_CHANNEL="C_PROJECT_A"
EOF

# Source before running
source .claude-config
./claude-with-slack.sh
```

### 3. Filter Sensitive Data

Edit `claude-with-slack.sh` to filter secrets:

```bash
# Before sending to Slack:
buffer=$(echo "$buffer" | sed 's/password=.*/password=***REDACTED***/g')
buffer=$(echo "$buffer" | sed 's/token=.*/token=***REDACTED***/g')
```

### 4. Desktop Notifications + Slack

Combine with macOS notifications:

```bash
#!/bin/bash
source ./claude-ping.sh

claude_notify_both() {
    claude_notify "$1" "$2"  # Send to Slack
    osascript -e "display notification \"$2\" with title \"Claude: $1\""  # Desktop
}

claude_notify_both "complete" "Tests passed!"
```

### 5. Emoji Customization

Edit `slack-logger.sh` line 76-110 to change emojis:

```bash
case "$event_type" in
    "start")
        emoji="🎬"  # Changed from 🏁
        ;;
    "complete")
        emoji="🎉"  # Changed from ✅
        ;;
esac
```

## 🔐 Security

### Protect Your Slack Token

1. **Never commit tokens to git:**
   ```bash
   echo "slack-logger.sh" >> .gitignore
   ```

2. **Use environment variables:**
   ```bash
   # In slack-logger.sh:
   SLACK_TOKEN="${SLACK_BOT_TOKEN_ENV:-YOUR_SLACK_BOT_TOKEN_HERE}"

   # In shell:
   export SLACK_BOT_TOKEN_ENV="xoxb-..."
   ```

3. **Restrict file permissions:**
   ```bash
   chmod 700 slack-logger.sh
   ```

4. **Use separate tokens per environment:**
   - Development: Different token
   - Production: Different token
   - Personal: Different token

## 📚 Function Reference

### slack-logger.sh

| Function | Description |
|----------|-------------|
| `send_to_slack(message, channel)` | Send plain message |
| `log_and_send(message, channel)` | Log to file + send |
| `send_code_block(code, lang, channel)` | Send formatted code |
| `send_event(type, message, channel)` | Send with emoji/prefix |
| `notify_session_start(name, channel)` | Session started |
| `notify_session_end(name, start_time, channel)` | Session ended |

### claude-ping.sh

| Function | Description |
|----------|-------------|
| `claude_notify(type, message, channel)` | Generic notification |
| `claude_start(message)` | Started task |
| `claude_progress(message)` | Progress update |
| `claude_complete(message)` | Completed task |
| `claude_error(message)` | Error occurred |
| `claude_warning(message)` | Warning |
| `claude_info(message)` | Information |
| `claude_task_start(name)` | Start timed task |
| `claude_task_complete(name)` | End timed task |

## 🎊 Examples

### Example 1: Feature Development

```bash
source ./claude-ping.sh

claude_task_start "Build user authentication"

# Work with Claude...
claude_progress "Created user model"
claude_progress "Implemented JWT tokens"
claude_progress "Added password hashing"

# Test
if npm test; then
    claude_progress "All tests passed ✅"
else
    claude_error "Tests failed - fixing..."
fi

claude_task_complete "Build user authentication"
```

**Slack output:**
```
🏁 Started: Build user authentication
⚙️ Progress: Created user model
⚙️ Progress: Implemented JWT tokens
⚙️ Progress: Added password hashing
⚙️ Progress: All tests passed ✅
✅ Complete: Build user authentication (Duration: 34m 12s)
```

### Example 2: Debugging

```bash
# Use full mirroring to see everything
./claude-with-slack.sh

# In Claude session:
# "Help me debug why the email sending is failing"
# All output goes to Slack
# You can leave and check on phone
```

### Example 3: Automated Deployment

```bash
#!/bin/bash
# deploy.sh

source ./claude-ping.sh

claude_start "Production deployment v2.1.0"

# Build
claude_progress "Building application..."
if npm run build:prod; then
    claude_progress "Build successful ✅"
else
    claude_error "Build failed ❌"
    exit 1
fi

# Tests
claude_progress "Running production tests..."
if npm run test:prod; then
    claude_progress "Tests passed ✅"
else
    claude_error "Tests failed ❌"
    exit 1
fi

# Deploy
claude_progress "Deploying to production..."
if ./deploy-to-prod.sh; then
    claude_complete "Deployment successful! 🚀"
else
    claude_error "Deployment failed ❌"
    exit 1
fi
```

Add to crontab:
```
0 2 * * * /path/to/deploy.sh
```

Get deployment notifications at 2 AM without being awake!

## 🎯 Summary

You now have **3 powerful ways** to monitor Claude Code from Slack:

1. **Full Mirroring** - See everything
2. **Smart Summarizer** - Highlights + summaries
3. **Manual Notifications** - Precise control

**Choose based on your needs:**
- Short session? → Full mirroring
- Long session? → Smart summarizer
- Critical work? → Manual notifications
- Automation? → Manual notifications

**Next Steps:**
1. Configure Slack token in `slack-logger.sh`
2. Choose your approach
3. Start working with Claude Code
4. Monitor from your phone! 📱

**Enjoy complete visibility into Claude Code from anywhere! 🎉**
