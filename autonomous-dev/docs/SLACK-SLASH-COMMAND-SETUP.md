# /cc Slash Command Setup for Claude Code

## 🎯 Overview

Control Claude Code from Slack using the `/cc` slash command - simple, fast, no event subscriptions needed!

## ✅ What's Already Done

- ✅ N8n workflow created: `slack-cc-command`
- ✅ Workflow ID: `HBMOc0qTvAfc8SyA`
- ✅ Webhook path configured: `/cc`
- ✅ Immediate response configured (< 3 seconds)
- ✅ Supabase integration ready
- ✅ Old event-based workflow removed

## 🔗 Webhook URL

**Production Webhook:**
```
https://n8n.grantpilot.app/webhook/cc
```

---

## 📋 STEP 1: Activate N8n Workflow

### Option A: Manual Activation (Recommended)

1. Go to: **https://n8n.grantpilot.app**
2. Find workflow: **`slack-cc-command`**
3. Click the **"Active"** toggle switch to ON
4. Verify it shows "Active" ✓

### Option B: Verify Webhook is Live

Test the webhook:
```bash
curl -X POST "https://n8n.grantpilot.app/webhook/cc" \
  -d "text=test command" \
  -d "channel_id=C12345" \
  -d "user_id=U12345"
```

**Expected Response:**
```json
{
  "response_type": "in_channel",
  "text": "🤖 Command received! Processing: test command"
}
```

---

## 📋 STEP 2: Create Slack Slash Command

### A. Go to Slack Apps

1. Visit: **https://api.slack.com/apps**
2. Select **"Claude Code Bot"** (or click "Create New App")
3. If creating new:
   - Choose **"From scratch"**
   - App Name: `Claude Code Bot`
   - Select your workspace
   - Click **"Create App"**

### B. Create the /cc Slash Command

1. In left sidebar, click: **"Slash Commands"**
2. Click: **"Create New Command"**
3. Fill in the form:

   **Command:**
   ```
   /cc
   ```

   **Request URL:**
   ```
   https://n8n.grantpilot.app/webhook/cc
   ```

   **Short Description:**
   ```
   Send commands to Claude Code
   ```

   **Usage Hint:**
   ```
   ls -la
   ```

4. Click **"Save"**

### C. Install/Reinstall the App

1. In left sidebar, click: **"Install App"**
2. Click: **"Install to Workspace"** (or "Reinstall to Workspace")
3. Review permissions
4. Click **"Allow"**

---

## 🧪 STEP 3: Test the Slash Command

### Test 1: In Slack

1. Go to **any Slack channel** (public or private)
2. Type:
   ```
   /cc echo "Hello from Claude Code!"
   ```
3. Press **Enter**

**Expected Response:**
```
🤖 Command received! Processing: echo "Hello from Claude Code!"
```

### Test 2: Verify Supabase Entry

Check that the command was stored:

```bash
curl -s "https://hjtvtkffpziopozmtsnb.supabase.co/rest/v1/claude_commands?select=*&order=created_at.desc&limit=1" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho" | jq
```

**Look for:**
- ✅ `command`: "echo \"Hello from Claude Code!\""
- ✅ `status`: "pending"
- ✅ `source`: "slack"
- ✅ `slack_channel_id`: Your channel ID
- ✅ `user_id`: Your Slack user ID

### Test 3: Watch Claude Code Execute

If Claude Code polling service is running:

```bash
cd /Users/christophertolleymacbook2019
./start-remote-access.sh
```

You should see:
```
[2025-10-19 15:30:00] Checking for new commands...
📬 New command received!
   ID: abc-123-def-456
   Command: echo "Hello from Claude Code!"
   Source: slack
   User: U12345678
⚡ Executing command: echo "Hello from Claude Code!"
✅ Command completed successfully
```

---

## 🎉 COMPLETE END-TO-END FLOW

### Full Test Scenario:

1. **Start Claude Code service:**
   ```bash
   ./start-remote-access.sh
   ```

2. **In Slack, type:**
   ```
   /cc ls -la
   ```

3. **Watch the magic happen:**
   - ✅ Slack sends request to N8n webhook
   - ✅ N8n responds immediately: "🤖 Command received! Processing: ls -la"
   - ✅ N8n inserts command to Supabase (status: pending)
   - ✅ Claude Code detects command within 30 seconds
   - ✅ Claude Code executes `ls -la`
   - ✅ Claude Code writes response to Supabase (status: completed)
   - 🔄 (Next: Response workflow will send result back to Slack)

---

## 📊 Workflow Architecture

```
Slack: /cc ls -la
      ↓
N8n Webhook Receives (POST /webhook/cc)
      ↓
Extract Command (parse form data)
      ↓
   Split → Immediate Response (< 3 sec)
      ↓       "🤖 Command received!"
      ↓
   Continue → Prepare Supabase Data
      ↓
   Insert to claude_commands table
      ↓
   (status: pending)

Claude Code Polling Service (30s interval)
      ↓
   Detects pending command
      ↓
   Executes command
      ↓
   Writes response to Supabase
      ↓
   (status: completed)
```

---

## 🔍 Troubleshooting

### Issue: "Slash command failed to send"

**Solution:**
1. Check N8n workflow is activated
2. Verify webhook URL is exact: `https://n8n.grantpilot.app/webhook/cc`
3. Test webhook directly with curl
4. Check N8n execution logs

### Issue: Response takes > 3 seconds (timeout)

**Solution:**
- This workflow uses "Respond to Webhook" node for immediate response
- Supabase insert happens in background after response
- If still timing out, check N8n server performance

### Issue: Command not appearing in Supabase

**Solution:**
1. Check N8n execution history for errors
2. Verify Supabase credentials in N8n
3. Check claude_commands table exists
4. Review N8n node connections

### Issue: Claude Code not detecting command

**Solution:**
1. Verify polling service is running: `ps aux | grep start-remote-access`
2. Check Supabase connection in polling script
3. Verify command status is "pending"
4. Check polling interval (default: 30 seconds)

### Issue: Permission denied error

**Solution:**
- Slash commands don't require special permissions
- Only need the app installed to workspace
- No OAuth scopes needed for basic slash commands

---

## 🚀 Next Steps

### Create Response Workflow

Still needed: Send Claude Code responses back to Slack

**Next command:**
```
Create N8n workflow: Supabase → Slack Response
```

This workflow will:
- Poll Supabase for completed commands
- Send responses back to Slack channel
- Use `response_url` for delayed responses
- Mark commands as notified

---

## 📝 Example Commands

### Simple Commands:
```
/cc pwd
/cc date
/cc whoami
/cc echo "Hello World"
```

### File Operations:
```
/cc ls -la
/cc cat README.md
/cc find . -name "*.js"
```

### System Info:
```
/cc df -h
/cc top -l 1
/cc ps aux | grep node
```

### Git Operations:
```
/cc git status
/cc git log --oneline -5
/cc git diff
```

---

## ⚠️ Security Notes

### Current Setup:
- ✅ Commands from Slack only
- ✅ User tracking (Slack user ID)
- ✅ Channel tracking
- ❌ No command validation (executes anything)
- ❌ No user authorization check

### Recommended Improvements:

1. **Add Command Whitelist:**
   ```javascript
   const ALLOWED_COMMANDS = ['ls', 'pwd', 'date', 'echo'];
   const cmd = command.split(' ')[0];
   if (!ALLOWED_COMMANDS.includes(cmd)) {
     return { error: "Command not allowed" };
   }
   ```

2. **Add User Authorization:**
   ```javascript
   const AUTHORIZED_USERS = ['U12345678', 'U87654321'];
   if (!AUTHORIZED_USERS.includes(user_id)) {
     return { error: "Unauthorized" };
   }
   ```

3. **Add Rate Limiting:**
   - Track commands per user
   - Limit to X commands per hour
   - Prevent abuse

4. **Add Dangerous Command Detection:**
   ```javascript
   const DANGEROUS = ['rm', 'sudo', 'chmod', 'mv', 'dd'];
   if (DANGEROUS.some(d => command.includes(d))) {
     return { error: "Dangerous command blocked" };
   }
   ```

---

## 📁 Files & Resources

### Local Files:
- ✅ `/Users/christophertolleymacbook2019/claude-poll-commands.sh`
- ✅ `/Users/christophertolleymacbook2019/claude-write-response.sh`
- ✅ `/Users/christophertolleymacbook2019/start-remote-access.sh`
- ✅ `/Users/christophertolleymacbook2019/REMOTE-ACCESS-SETUP.md`
- ✅ `/Users/christophertolleymacbook2019/SLACK-SLASH-COMMAND-SETUP.md` (this file)

### Online Resources:
- **N8n:** https://n8n.grantpilot.app
- **Supabase:** https://hjtvtkffpziopozmtsnb.supabase.co
- **Slack Apps:** https://api.slack.com/apps
- **Webhook:** https://n8n.grantpilot.app/webhook/cc

### Workflow Details:
- **Name:** slack-cc-command
- **ID:** HBMOc0qTvAfc8SyA
- **Nodes:** 5 (Webhook, Parse, Set, Supabase, Respond)
- **Type:** Slash Command Handler

---

## ✅ Checklist

- [ ] N8n workflow activated
- [ ] Webhook URL tested with curl
- [ ] Slack app created/accessed
- [ ] /cc slash command created
- [ ] Request URL configured
- [ ] App installed to workspace
- [ ] Tested in Slack channel
- [ ] Command appeared in Supabase
- [ ] Claude Code polling service running
- [ ] Command executed successfully

---

## 🎯 Summary

You now have a **simple, fast slash command** to control Claude Code from Slack!

### What Works:
✅ `/cc` command in any Slack channel
✅ Immediate acknowledgment
✅ Command stored in Supabase
✅ Claude Code auto-executes
✅ No complex permissions needed
✅ No event subscriptions
✅ No bot setup hassle

### What's Next:
🔄 Response workflow (Supabase → Slack)
🔄 Send execution results back to Slack
🔄 Complete two-way communication

**Ready to control Claude Code from your phone! 📱**
