# Slack Integration Setup for Claude Code Remote Access

## Overview

This guide will help you connect Slack to your Claude Code remote access system via N8n.

## ✅ Workflow Created

**Workflow Name:** `slack-to-claude-code`
**Workflow ID:** `m7PZehrXfvqRtxVe`
**Status:** Created (needs activation)
**N8n URL:** https://n8n.grantpilot.app

## 📋 Workflow Structure

### Node 1: Receive Slack Message (Webhook Trigger)
- **Type:** Webhook
- **Path:** `/claude-command`
- **Method:** POST
- **Response Mode:** Immediately

**Webhook URL:** `https://n8n.grantpilot.app/webhook/claude-command`

### Node 2: Parse Slack Event (Code)
- Handles Slack URL verification challenge
- Extracts command from message text
- Removes bot mentions
- Parses channel, user, and timestamp

### Node 3: Check Event Type (IF condition)
- Filters for `event_callback` type
- Ignores verification and other events

### Node 4: Prepare Supabase Data (Set)
- Formats data for Supabase insert
- Fields: command, source, status, user_id, slack_channel_id, slack_thread_ts

### Node 5: Insert Command (Supabase)
- Inserts into `claude_commands` table
- Status automatically set to 'pending'

### Node 6: Send Acknowledgment (Slack)
- Replies to user in thread
- Message: "🤖 Command received! Claude Code is processing your request..."

---

## 🚀 STEP 1: Activate the N8n Workflow

### Manual Activation (Recommended):

1. Go to N8n: https://n8n.grantpilot.app
2. Find workflow: `slack-to-claude-code`
3. Click the **Active** toggle switch
4. Verify webhook is active

### Test Webhook is Active:

```bash
curl -X POST "https://n8n.grantpilot.app/webhook/claude-command" \
  -H "Content-Type: application/json" \
  -d '{"type":"url_verification","challenge":"test123"}'
```

**Expected Response:** `{"challenge":"test123"}`

---

## 🔧 STEP 2: Configure Slack App

### A. Create or Access Your Slack App

1. Go to: https://api.slack.com/apps
2. Click **"Create New App"** or select existing app
3. Choose **"From scratch"**
4. Name: `Claude Code Bot`
5. Select your workspace

### B. Enable Event Subscriptions

1. In your app settings, go to **"Event Subscriptions"**
2. Toggle **Enable Events** to ON
3. **Request URL:** `https://n8n.grantpilot.app/webhook/claude-command`
4. Wait for verification ✓ (should show "Verified")

### C. Subscribe to Bot Events

Under **"Subscribe to bot events"**, add these events:

- ✅ `message.channels` - Messages posted in channels
- ✅ `app_mention` - Bot is mentioned

Click **Save Changes**

### D. Configure OAuth & Permissions

1. Go to **"OAuth & Permissions"**
2. Under **"Scopes"** → **"Bot Token Scopes"**, add:
   - ✅ `chat:write` - Post messages
   - ✅ `chat:write.public` - Post to public channels
   - ✅ `channels:history` - View channel messages
   - ✅ `app_mentions:read` - View mentions
   - ✅ `im:history` - View DM messages (optional)
   - ✅ `im:write` - Write DMs (optional)

3. Click **"Install to Workspace"**
4. Authorize the app

### E. Get Your Bot Token

After installing:
1. Copy the **Bot User OAuth Token** (starts with `xoxb-`)
2. Store it securely - you'll need it for N8n Slack node

### F. Add Bot to Channels

1. Go to your Slack workspace
2. Open the channel where you want to use Claude Code
3. Type: `/invite @Claude Code Bot`
4. Or go to channel details → Integrations → Add apps

---

## 🔐 STEP 3: Configure N8n Slack Credentials

### Add Slack API Credential in N8n:

1. Go to N8n: https://n8n.grantpilot.app/credentials
2. Click **"+ Create New Credential"**
3. Search for **"Slack API"**
4. Enter:
   - **Name:** `Slack API`
   - **Access Token:** `xoxb-YOUR-BOT-TOKEN-HERE`
5. Click **"Create"**

### Link Credential to Workflow:

1. Open `slack-to-claude-code` workflow
2. Click on **"Send Acknowledgment"** node
3. Under **Credential**, select `Slack API`
4. Save workflow

---

## 🧪 STEP 4: Test the Integration

### Test 1: URL Verification

```bash
curl -X POST "https://n8n.grantpilot.app/webhook/claude-command" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "url_verification",
    "challenge": "test_challenge_abc123"
  }'
```

**Expected:** `{"challenge":"test_challenge_abc123"}`

### Test 2: Simulate Slack Event

```bash
curl -X POST "https://n8n.grantpilot.app/webhook/claude-command" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "event_callback",
    "event": {
      "type": "message",
      "text": "echo Hello from Slack!",
      "channel": "C12345678",
      "user": "U12345678",
      "ts": "1234567890.123456"
    }
  }'
```

**Check:**
1. ✅ N8n workflow executes
2. ✅ Command inserted in Supabase
3. ✅ Acknowledgment sent to Slack (if credentials configured)

### Test 3: Verify Supabase Entry

```bash
curl -s "https://hjtvtkffpziopozmtsnb.supabase.co/rest/v1/claude_commands?select=*&order=created_at.desc&limit=1" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho" | jq
```

**Expected:** Should see your test command with status "pending"

### Test 4: Real Slack Message

1. Go to your Slack channel
2. Mention the bot: `@Claude Code Bot echo "test from real slack"`
3. Watch for acknowledgment message
4. Check Supabase for the command
5. Watch Claude Code polling service detect it

---

## 📊 Complete Flow Test

### End-to-End Test:

1. **Start Claude Code Service:**
   ```bash
   cd /Users/christophertolleymacbook2019
   ./start-remote-access.sh
   ```

2. **Send Slack Message:**
   ```
   @Claude Code Bot ls -la
   ```

3. **Expected Flow:**
   - ✅ Slack sends event to N8n webhook
   - ✅ N8n parses and inserts to Supabase
   - ✅ N8n sends acknowledgment to Slack
   - ✅ Claude Code detects pending command (within 30s)
   - ✅ Claude Code executes `ls -la`
   - ✅ Response written to Supabase
   - 🔄 (Next: N8n workflow to send response back to Slack)

---

## 🔍 Troubleshooting

### Webhook Not Verifying

**Issue:** Slack shows "Webhook URL failed to verify"

**Solution:**
1. Check N8n workflow is activated
2. Test webhook URL directly with curl
3. Check N8n execution logs
4. Ensure "Parse Slack Event" node handles `url_verification`

### Commands Not Appearing in Supabase

**Issue:** Slack message sent but nothing in database

**Solution:**
1. Check N8n execution history
2. Verify Supabase credentials in N8n
3. Check "Check Event Type" node filters correctly
4. Review N8n error logs

### Bot Not Responding in Slack

**Issue:** Command inserted but no acknowledgment

**Solution:**
1. Verify Slack API credentials in N8n
2. Check bot has `chat:write` permission
3. Verify bot is invited to channel
4. Check N8n "Send Acknowledgment" node configuration

### Slack Events Not Reaching N8n

**Issue:** Messages sent but webhook not triggered

**Solution:**
1. Check Event Subscriptions are enabled
2. Verify correct events subscribed (message.channels, app_mention)
3. Ensure bot is in the channel
4. Check Request URL matches exactly

---

## 🎯 Next Steps

### STEP 5: Create Response Workflow (Supabase → Slack)

Still needed:
- N8n workflow to poll Supabase for completed commands
- Send responses back to Slack
- Mark commands as notified

**Next command to run:**
```
Create the Supabase-to-Slack N8n workflow
```

---

## 📋 Summary

### ✅ Completed:
- [x] N8n workflow created: `slack-to-claude-code`
- [x] Webhook configured: `/webhook/claude-command`
- [x] Slack event parsing
- [x] Supabase integration
- [x] Acknowledgment message

### 🔄 To Do:
- [ ] Activate N8n workflow
- [ ] Configure Slack App
- [ ] Add Slack API credentials to N8n
- [ ] Test end-to-end
- [ ] Create response workflow (Supabase → Slack)

### 🔗 Important URLs:
- **N8n:** https://n8n.grantpilot.app
- **Webhook:** https://n8n.grantpilot.app/webhook/claude-command
- **Slack Apps:** https://api.slack.com/apps
- **Supabase:** https://hjtvtkffpziopozmtsnb.supabase.co

---

**Ready for Slack integration! Follow the steps above to complete the setup.** 🚀
