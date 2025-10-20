# 💻 Terminal Commands with Slack Notifications

## Overview

You can now run commands through Claude Code **directly from your terminal** and still receive real-time Slack notifications! This is perfect for:

- Working on your laptop while monitoring progress on your phone
- Running commands locally but tracking them in your team Slack
- Testing commands without using the `/cc` slash command
- Automating tasks with scripts that send notifications

## 🎯 What You Get

### Before (Terminal Only)
```bash
YOU (terminal): npm test
... wait ...
... see output in terminal ...
```
**Problem:** No Slack notifications, can't track on phone

### After (Terminal + Slack Notifications)
```bash
YOU (terminal): ./claude-run.sh npm test

YOUR PHONE (Slack):
💻 Terminal Command
⚙️ Processing your command
Command: `npm test`
Initiated from: Terminal at MacBook-Pro
Started at: 3:45 PM

[progress updates...]

✅ Complete! Duration: 23s
All tests passed ✓
```
**Benefit:** Full Slack notifications even for terminal commands!

## 📋 Quick Start

### Step 1: Configure Default Channel

Get your Slack channel ID:
1. Open the channel in Slack
2. Click the channel name at the top
3. Scroll down to find "Channel ID"
4. Copy it (format: `C1234567890`)

**Or use a DM channel for private notifications:**
1. Open a DM with yourself
2. Look at the URL: `app_redirect?channel=D1234567890`
3. Copy the `D...` ID

### Step 2: Update Scripts

Edit both scripts and replace `C09M9A33FFF` with your channel ID:

```bash
# 1. Edit start-remote-access.sh
nano start-remote-access.sh
# Find line 16 and update:
DEFAULT_SLACK_CHANNEL="C1234567890"  # Your actual channel ID

# 2. Edit claude-run.sh
nano claude-run.sh
# Find line 14 and update:
DEFAULT_SLACK_CHANNEL="C1234567890"  # Your actual channel ID

# 3. Edit insert-test-command.sh
nano insert-test-command.sh
# Find line 9 and update:
DEFAULT_SLACK_CHANNEL="C1234567890"  # Your actual channel ID
```

### Step 3: Test It!

```bash
# Simple test
./claude-run.sh echo "Testing terminal notifications!"

# Check your Slack channel for updates
```

## 🚀 Usage Methods

### Method 1: claude-run.sh (Recommended)

The easiest way - interactive script with progress monitoring:

```bash
# Basic usage
./claude-run.sh pwd
./claude-run.sh ls -la
./claude-run.sh "echo 'Hello World'"

# With monitoring
./claude-run.sh npm test
# Asks: "Monitor execution in terminal? (y/n)"
# Select 'y' to watch real-time progress

# Without monitoring
./claude-run.sh git status
# Select 'n' and check Slack for updates
```

**Features:**
- ✅ Validates command before submission
- ✅ Checks if polling service is running
- ✅ Optional terminal monitoring
- ✅ Color-coded output
- ✅ Helpful error messages

### Method 2: insert-test-command.sh

Quick test command insertion:

```bash
# Edit the script to change the command
nano insert-test-command.sh
# Update line 22: "command": "your command here"

# Run it
./insert-test-command.sh
```

### Method 3: Direct Supabase API

For automation and scripts:

```bash
COMMAND="npm test"
CHANNEL="C1234567890"

curl -X POST "https://hjtvtkffpziopozmtsnb.supabase.co/rest/v1/claude_commands" \
  -H "apikey: YOUR_SUPABASE_KEY" \
  -H "Authorization: Bearer YOUR_SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"command\": \"${COMMAND}\",
    \"source\": \"terminal\",
    \"status\": \"pending\",
    \"user_id\": \"$(whoami)@$(hostname -s)\",
    \"slack_channel_id\": \"${CHANNEL}\"
  }"
```

### Method 4: Bash Alias (Quick Access)

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Claude Run alias
alias ccrun='/Users/christophertolleymacbook2019/claude-run.sh'

# Then use it anywhere:
ccrun pwd
ccrun npm test
ccrun "echo 'Easy!'"
```

**Advanced aliases:**

```bash
# Quick command without monitoring
alias ccq='/Users/christophertolleymacbook2019/claude-run.sh'

# Run and monitor
alias ccm='ccrun_monitor() { /Users/christophertolleymacbook2019/claude-run.sh "$@"; }; ccrun_monitor'

# Run git commands
alias ccgit='/Users/christophertolleymacbook2019/claude-run.sh git'

# Example usage:
ccgit status
ccgit log --oneline -10
```

## 📱 Slack Notifications

### Terminal Command Format

When you run a command from terminal, Slack shows:

```
💻 Terminal Command
⚙️ Claude Code is processing your command
Command: `npm test`
Initiated from: Terminal at MacBook-Pro
Started at: 3:45 PM

🔨 Executing command...
This may take a moment depending on complexity.

✅ Execution complete!
Duration: 23s
Exit code: 0
Preview: `15 tests passed, 0 failed`

📊 Metrics
• Output: 47 lines (2.3 KB)
• Timestamp: 2025-10-19 03:46:08 PM

Full result will arrive in the main response shortly.

[Final full output posted by N8n]
```

### Slack Command Format (for comparison)

When using `/cc` in Slack:

```
⚙️ Claude Code is processing your command
Started at: 3:45 PM
Command: `npm test`

[rest is the same...]
```

**Difference:** Terminal commands have the 💻 prefix and show hostname

## 🎛️ Configuration

### Disable Terminal Notifications

In `start-remote-access.sh`:

```bash
# Line 17
NOTIFY_TERMINAL_COMMANDS=false  # Disable terminal notifications
```

Now terminal commands will execute but won't send Slack notifications.

### Different Channels for Different Sources

Modify `start-remote-access.sh` to use different channels:

```bash
# Add after line 16
SLACK_CHANNEL_TERMINAL="C1111111111"  # Private DM
SLACK_CHANNEL="C2222222222"          # Public #commands channel

# Then in execute_command function:
if [ "$source" = "terminal" ]; then
    channel_id="$SLACK_CHANNEL_TERMINAL"
else
    channel_id="$SLACK_CHANNEL"
fi
```

### Custom Source Tags

Modify `claude-run.sh` to tag commands:

```bash
# Line 76 - change source from "terminal" to something else
"source": "automation",  # or "cron", "script", "manual"
```

Then filter in Slack or database by source.

## 📊 Use Cases

### 1. Remote Monitoring

**Scenario:** You're running a long build on your laptop but need to leave

```bash
# Terminal on laptop
./claude-run.sh npm run build

# Phone (Slack)
💻 Terminal Command: npm run build
⚙️ Processing...
[25 seconds later]
✅ Complete! Build successful
```

You can leave your laptop and track progress on phone!

### 2. Automated Scripts

**Scenario:** Cron job that sends Slack updates

```bash
#!/bin/bash
# backup-script.sh

# Run backup with notifications
/path/to/claude-run.sh "tar -czf backup-$(date +%Y%m%d).tar.gz /data"
```

Add to crontab:
```bash
0 2 * * * /home/user/backup-script.sh
```

Now your 2 AM backups send Slack notifications!

### 3. Team Visibility

**Scenario:** Share terminal commands with team

```bash
# Use team channel instead of DM
DEFAULT_SLACK_CHANNEL="C_TEAM_DEVOPS"

# Run deployment
./claude-run.sh ./deploy-production.sh

# Team sees in #devops:
💻 Terminal Command (alice@macbook)
⚙️ Running: ./deploy-production.sh
...
✅ Deployment complete!
```

### 4. Testing Before Slack Integration

**Scenario:** Test commands before exposing via `/cc`

```bash
# Test risky command safely
./claude-run.sh "rm -rf /tmp/old-cache"

# Check result in Slack
# If looks good, approve for /cc usage
```

## 🔧 Troubleshooting

### "Claude Code polling service is not running"

**Solution:**
```bash
cd /Users/christophertolleymacbook2019
./start-remote-access.sh
```

Keep this running in a terminal or screen session.

### Notifications not appearing

**Check:**
1. ✅ `DEFAULT_SLACK_CHANNEL` is configured correctly
2. ✅ Bot has access to that channel (invite bot if needed)
3. ✅ `NOTIFY_TERMINAL_COMMANDS=true` in start-remote-access.sh
4. ✅ `SLACK_BOT_TOKEN` is configured
5. ✅ Polling service is running

**Debug:**
```bash
# Check last command in database
curl -s "https://hjtvtkffpziopozmtsnb.supabase.co/rest/v1/claude_commands?order=created_at.desc&limit=1" \
  -H "apikey: YOUR_KEY" | jq .

# Look for:
# - slack_channel_id: should be your channel ID
# - source: should be "terminal"
# - status: should change from pending → processing → completed
```

### Wrong channel receiving notifications

**Check:**
1. `DEFAULT_SLACK_CHANNEL` value in all 3 scripts
2. Make sure they all match

**Update all at once:**
```bash
# Find and replace in all files
sed -i 's/C09M9A33FFF/YOUR_CHANNEL_ID/g' start-remote-access.sh
sed -i 's/C09M9A33FFF/YOUR_CHANNEL_ID/g' claude-run.sh
sed -i 's/C09M9A33FFF/YOUR_CHANNEL_ID/g' insert-test-command.sh
```

### Command executes but no Slack notifications

**Possible causes:**

1. **Token not configured**
   ```bash
   # Check in start-remote-access.sh
   grep SLACK_BOT_TOKEN start-remote-access.sh
   # Should NOT be "YOUR_SLACK_BOT_TOKEN_HERE"
   ```

2. **Terminal notifications disabled**
   ```bash
   # Check in start-remote-access.sh
   grep NOTIFY_TERMINAL_COMMANDS start-remote-access.sh
   # Should be "true"
   ```

3. **Bot not in channel**
   ```bash
   # In Slack channel, type:
   /invite @YourBotName
   ```

## 📈 Comparison

| Feature | `/cc` Slack Command | `claude-run.sh` Terminal |
|---------|-------------------|------------------------|
| Slack notifications | ✅ Yes | ✅ Yes |
| Progress updates | ✅ Yes | ✅ Yes |
| Metrics | ✅ Yes | ✅ Yes |
| Threading | ✅ Yes | ❌ No (top-level messages) |
| Requires Slack open | ✅ Yes | ❌ No |
| From anywhere | ✅ Yes (any device with Slack) | ❌ No (only from machine) |
| Terminal monitoring | ❌ No | ✅ Yes (optional) |
| Automation friendly | ❌ No | ✅ Yes |

## 🚦 Best Practices

### 1. Use DM for Personal Commands

```bash
# Private notifications
DEFAULT_SLACK_CHANNEL="D_YOUR_DM_ID"
```

### 2. Use Channel for Team Commands

```bash
# Team visibility
DEFAULT_SLACK_CHANNEL="C_TEAM_OPS"
```

### 3. Tag Commands with Context

Modify `claude-run.sh` to include context:

```bash
# Add project name to user_id
"user_id": "$(whoami)@$(hostname -s) [Project: MyApp]"
```

Now Slack shows: `alice@macbook [Project: MyApp]`

### 4. Create Per-Project Wrappers

```bash
# ~/myapp/run-command.sh
#!/bin/bash
cd ~/myapp
/path/to/claude-run.sh "$@"

# Usage:
cd ~/myapp
./run-command.sh npm test
```

## 🎉 Summary

You now have **3 ways** to run commands with Slack notifications:

1. **`/cc` in Slack** - From anywhere, anytime
2. **`claude-run.sh`** - Terminal with Slack tracking
3. **Direct API** - For automation

All methods give you:
- ✅ Real-time progress updates
- ✅ Execution metrics
- ✅ Error notifications
- ✅ Complete visibility

**Next Steps:**

1. Configure `DEFAULT_SLACK_CHANNEL` in all 3 scripts
2. Test with: `./claude-run.sh echo "It works!"`
3. Check your Slack channel for notifications
4. Create aliases for quick access
5. Enjoy terminal commands with Slack tracking! 🚀

## 📚 Related Documentation

- **Setup Guide:** `SLACK-BOT-TOKEN-SETUP.md`
- **Progress Updates:** `PROGRESS-UPDATES-README.md`
- **Main Guide:** `REMOTE-ACCESS-SETUP.md`
- **System Status:** `SYSTEM-READY.md`
