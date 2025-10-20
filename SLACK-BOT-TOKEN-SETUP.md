# 🔑 Slack Bot Token Setup Guide

## Step 1: Get Your Slack Bot Token

1. Go to: **https://api.slack.com/apps**
2. Select your Slack App (or create a new one if needed)
3. Go to: **OAuth & Permissions** (in the left sidebar)
4. Scroll to: **OAuth Tokens for Your Workspace**
5. Copy the **Bot User OAuth Token** (starts with `xoxb-`)

Example token format:
```
xoxb-XXXX-XXXX-XXXX
```

## Step 2: Verify Bot Token Scopes

Your bot needs these permissions (OAuth Scopes):

### Required Scopes:
- ✅ `chat:write` - Post messages to channels
- ✅ `chat:write.public` - Post to public channels without joining

### How to Add Scopes:
1. In **OAuth & Permissions**
2. Scroll to **Scopes** → **Bot Token Scopes**
3. Click **Add an OAuth Scope**
4. Add both `chat:write` and `chat:write.public`
5. **Important:** After adding scopes, you must **Reinstall the app** to your workspace!

## Step 3: Install/Reinstall App to Workspace

1. Go to: **Install App** (in the left sidebar)
2. Click: **Reinstall to Workspace** (or **Install to Workspace** if first time)
3. Review permissions
4. Click: **Allow**

## Step 4: Configure start-remote-access.sh

1. Open the file:
   ```bash
   nano /Users/christophertolleymacbook2019/start-remote-access.sh
   ```

2. Find line 10:
   ```bash
   SLACK_BOT_TOKEN="YOUR_SLACK_BOT_TOKEN_HERE"
   ```

3. Replace with your actual token:
   ```bash
   SLACK_BOT_TOKEN="xoxb-XXXX-XXXX-XXXX"
   ```

4. Save and exit (Ctrl+X, then Y, then Enter)

## Step 5: Verify Configuration

Test that your token works:

```bash
curl -X POST "https://slack.com/api/auth.test" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" | jq .
```

Expected response:
```json
{
  "ok": true,
  "url": "https://your-workspace.slack.com/",
  "team": "Your Workspace Name",
  "user": "your-bot-name",
  "team_id": "T1234567890",
  "user_id": "U1234567890",
  "bot_id": "B1234567890"
}
```

If `"ok": false`, check:
- Token is copied correctly (no extra spaces)
- Token starts with `xoxb-`
- App is installed to workspace
- Scopes are configured correctly

## Step 6: Start the Enhanced Service

```bash
cd /Users/christophertolleymacbook2019
./start-remote-access.sh
```

You should see:
```
🚀 Claude Code Remote Access Service - Enhanced Edition
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Polling interval: 30 seconds
Slack updates: ✅ Enabled
Press Ctrl+C to stop
```

## Configuration Options

You can customize the notifications in `start-remote-access.sh`:

```bash
# Slack Configuration
SLACK_BOT_TOKEN="xoxb-..."          # Your bot token
SLACK_UPDATES_ENABLED=true          # Enable/disable all notifications

# Notification Settings
NOTIFY_ON_DETECT=true               # "⚙️ Processing your command"
NOTIFY_ON_START=true                # "🔨 Executing command..."
NOTIFY_ON_COMPLETE=true             # "✅ Execution complete!"
NOTIFY_WITH_METRICS=true            # Include timing and output stats
```

## Security Best Practices

### ⚠️ NEVER commit your bot token to git!

Add to `.gitignore`:
```bash
echo "start-remote-access.sh" >> .gitignore
```

### Alternative: Use Environment Variable

Modify `start-remote-access.sh` to read from environment:

```bash
# Read token from environment, fallback to hardcoded
SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN_ENV:-YOUR_SLACK_BOT_TOKEN_HERE}"
```

Then set in your shell:
```bash
export SLACK_BOT_TOKEN_ENV="xoxb-your-token-here"
```

## Troubleshooting

### "Slack token not configured"
- You forgot to replace `YOUR_SLACK_BOT_TOKEN_HERE` with your actual token

### "Slack notification failed: not_authed"
- Token is invalid or expired
- App needs to be reinstalled to workspace

### "Slack notification failed: missing_scope"
- Add `chat:write` and `chat:write.public` scopes
- Reinstall app to workspace

### "Slack notification failed: channel_not_found"
- Bot doesn't have access to the channel
- Invite bot to the channel: `/invite @YourBotName`

### No notifications appearing
- Check `SLACK_UPDATES_ENABLED=true`
- Check notification flags are `true`
- Verify bot token is configured
- Check terminal output for errors

## What You'll See

### Example Notification Flow:

```
YOU (in Slack): /cc pwd

IMMEDIATE (from N8n webhook):
🤖 Command received! Processing: pwd

THREAD REPLY 1 (~10-30s later):
⚙️ Claude Code is processing your command
Started at: 8:42 PM
Command: `pwd`

THREAD REPLY 2 (~1s later):
🔨 Executing command...
This may take a moment depending on complexity.

THREAD REPLY 3 (~1s later):
✅ Execution complete!
Duration: 0s
Exit code: 0
Preview: `/Users/christophertolleymacbook2019`

📊 Metrics
• Output: 1 lines (34 chars)
• Timestamp: 2025-10-19 08:42:35 PM

Full result will arrive in the main response shortly.

FINAL MESSAGE (~15s later, from N8n):
✅ Command completed:
```pwd```

Result:
```/Users/christophertolleymacbook2019```
```

All progress messages appear in a **thread** under the original command acknowledgment!

## Next Steps

Once configured:
1. ✅ Start the enhanced service
2. ✅ Send a test command: `/cc echo "Testing progress updates!"`
3. ✅ Watch Slack for real-time progress notifications
4. 🎉 Enjoy complete visibility into Claude Code execution!
