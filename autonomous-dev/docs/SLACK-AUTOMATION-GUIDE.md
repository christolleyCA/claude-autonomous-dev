# Slack Automation System - User Guide

## Overview

Your Slack `/cc` command system is now fully operational! Here's how it works:

### The Complete Flow

```
1. You send: /cc <message> from Slack
   ↓
2. Message received → Saved to Supabase (status: "pending")
   ↓
3. Conversation service detects it → Marks as "processing"
   ↓
4. You check for messages (see methods below)
   ↓
5. Claude responds → Response saved (status: "completed")
   ↓
6. Response posting service → Automatically posts to Slack (within 15 seconds)
   ↓
7. You see the response in Slack! ✨
```

## Running Services

You should have these services running in the background:

### 1. Conversation Service (Receives messages from Slack)
```bash
# Check if running:
pgrep -f claude-conversation-service

# Start if not running:
./claude-conversation-service.sh > /tmp/claude-conversation.log 2>&1 &
```

### 2. Response Posting Service (Posts responses to Slack)
```bash
# Check if running:
pgrep -f claude-respond-service

# Start if not running:
./claude-respond-service.sh > /tmp/claude-respond.log 2>&1 &
```

### 3. Message Monitor Service (NEW! - Alerts you to new messages)
```bash
# Optional but recommended - displays new messages prominently:
./slack-message-monitor.sh > /tmp/slack-monitor.log 2>&1 &
```

## How to Check for and Respond to Messages

### Method 1: Slash Command (Easiest!)

In this Claude Code session, just type:
```
/check-slack
```

Claude will automatically:
- Check for pending messages
- Display them clearly
- Respond to each one
- Responses auto-post to Slack

### Method 2: Manual Script

```bash
./check-slack-messages.sh
```

This displays all pending messages. Then ask Claude to respond to them.

### Method 3: Background Monitor

The monitor service (`slack-message-monitor.sh`) runs continuously and will:
- Check every 30 seconds for new messages
- Ring a terminal bell when found
- Display messages prominently in colored output
- Track which messages you've already seen

## Responding to Messages

### Automatic (Recommended)
When Claude sees pending messages (via `/check-slack` or the scripts), Claude will:
1. Read each message
2. Generate an appropriate response
3. Save it to the database (status: "completed", slack_sent: false)
4. The response posting service automatically posts it to Slack

### Manual (If needed)
```bash
./respond-to-slack.sh <message_id> "Your response here"
```

## Checking Logs

- **Conversation service**: `tail -f /tmp/claude-conversation.log`
- **Response posting service**: `tail -f /tmp/claude-respond.log`
- **Message monitor**: `tail -f /tmp/slack-monitor.log`

## Troubleshooting

### Messages not arriving from Slack?
```bash
# Check conversation service:
pgrep -f claude-conversation-service

# Check logs:
tail -20 /tmp/claude-conversation.log

# Restart if needed:
pkill -f claude-conversation-service
./claude-conversation-service.sh > /tmp/claude-conversation.log 2>&1 &
```

### Responses not posting to Slack?
```bash
# Check response service:
pgrep -f claude-respond-service

# Check logs:
tail -20 /tmp/claude-respond.log

# Restart if needed:
pkill -f claude-respond-service
./claude-respond-service.sh > /tmp/claude-respond.log 2>&1 &
```

### Check for stuck messages
```bash
# See messages in "processing" status:
./check-slack-messages.sh
```

## Testing the System

1. Send a test message from Slack:
   ```
   /cc test message - please respond!
   ```

2. Within 15 seconds, you should see it saved to the database

3. Run `/check-slack` in Claude Code

4. Claude will respond

5. Within 15 seconds, you'll see Claude's response in Slack

## Database Queries

### See all pending messages:
```bash
curl -s 'https://hjtvtkffpziopozmtsnb.supabase.co/rest/v1/claude_commands?status=eq.processing&order=created_at.desc' \
  -H 'apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho' | jq .
```

### See recent completed messages:
```bash
curl -s 'https://hjtvtkffpziopozmtsnb.supabase.co/rest/v1/claude_commands?status=eq.completed&order=created_at.desc&limit=5' \
  -H 'apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho' | jq .
```

## Files Reference

- `~/check-slack-messages.sh` - Check for pending messages
- `~/respond-to-slack.sh` - Respond to a specific message
- `~/slack-message-monitor.sh` - Background monitor for new messages
- `~/claude-conversation-service.sh` - Receives messages from Slack
- `~/claude-respond-service.sh` - Posts responses to Slack
- `~/.claude/commands/check-slack.md` - Slash command for checking messages

## Tips

- Use `/check-slack` every 5-10 minutes when actively working
- Or run the monitor service in a visible terminal window
- The system works best when you check regularly
- All responses are automatic once you provide them
- No need to manually post to Slack - that's automated!

---

**Need help?** Just ask Claude to check for Slack messages or run `/check-slack`!
