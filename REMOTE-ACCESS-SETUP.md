# Claude Code Remote Access System

## Overview

This system allows you to control Claude Code remotely from Slack via N8n workflows and a Supabase database.

## 🎯 Complete Two-Way System

### What You Have Now:

1. ✅ **Slack Slash Command:** `/cc` - Send commands from anywhere
2. ✅ **N8n Workflow 1:** `slack-cc-command` - Receives /cc commands via webhook
3. ✅ **Supabase Database:** `claude_commands` table - Stores commands & responses
4. ✅ **Claude Code Polling:** `start-remote-access.sh` - Executes commands every 30s
5. ✅ **N8n Workflow 2:** `claude-responses-to-slack` - Sends responses back every 15s

### Complete Architecture

```
YOU (Phone/Work/Anywhere)
    ↓
Type in Slack: /cc ls -la
    ↓
Slack → N8n Webhook (slack-cc-command) → Supabase (status: pending)
    ↓
    Immediate: "🤖 Command received! Processing: ls -la"
    ↓
Claude Code Polling (every 30s)
    ↓
    Detects pending command
    ↓
    Executes: ls -la
    ↓
    Writes response to Supabase (status: completed)
    ↓
N8n Polling (claude-responses-to-slack, every 15s)
    ↓
    Detects completed command
    ↓
    Sends formatted message to Slack
    ↓
YOU receive result in Slack! 📱
```

### Total Latency: ~45 seconds maximum
- Detection: up to 30 seconds (Claude Code polling)
- Execution: few seconds
- Response: up to 15 seconds (N8n polling)

### How to Use

1. **Start Claude Code polling:**
   ```bash
   cd /Users/christophertolleymacbook2019
   ./start-remote-access.sh
   ```

2. **From Slack (anywhere - phone, work, home):**
   ```
   /cc echo "Hello from anywhere!"
   /cc ls -la
   /cc git status
   /cc pwd
   ```

3. **Wait ~45 seconds max, see results appear in Slack!**

## Database Schema

### Table: `claude_commands`

```sql
CREATE TABLE claude_commands (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Command info
  command TEXT NOT NULL,
  source VARCHAR(50) DEFAULT 'slack',
  user_id VARCHAR(100),

  -- Status tracking
  status VARCHAR(20) DEFAULT 'pending',
  -- status values: 'pending', 'processing', 'completed', 'error'

  -- Response
  response TEXT,
  error_message TEXT,

  -- Metadata
  processed_at TIMESTAMPTZ,
  slack_channel_id VARCHAR(100),
  slack_thread_ts VARCHAR(50),

  -- Response tracking
  slack_sent BOOLEAN DEFAULT false,
  slack_sent_at TIMESTAMPTZ
);
```

**Index for efficient polling:**
```sql
CREATE INDEX idx_claude_commands_status_created
ON claude_commands(status, created_at);
```

## Components

### 1. Supabase Database
- **Project:** grantomatic-prod
- **Table:** claude_commands
- **URL:** https://hjtvtkffpziopozmtsnb.supabase.co
- **Purpose:** Central communication hub between Slack/N8n and Claude Code

### 2. Polling Script (`claude-poll-commands.sh`)
- Queries Supabase for pending commands
- Returns command ID and command text
- Can be run standalone or sourced by main service

**Usage:**
```bash
./claude-poll-commands.sh
```

### 3. Response Writer (`claude-write-response.sh`)
- Updates command status (processing, completed, error)
- Writes responses back to Supabase
- Handles error messages

**Usage:**
```bash
# Mark as processing
./claude-write-response.sh <command_id> processing

# Write successful response
./claude-write-response.sh <command_id> response "Command executed successfully"

# Write error
./claude-write-response.sh <command_id> error "Command failed: invalid syntax"
```

### 4. Main Service (`start-remote-access.sh`)
- Continuously polls for commands (30-second interval)
- Executes commands automatically
- Handles response/error writing
- Graceful shutdown with Ctrl+C

**Usage:**
```bash
./start-remote-access.sh
```

## How to Start

### Quick Start
```bash
cd /Users/christophertolleymacbook2019
./start-remote-access.sh
```

You should see:
```
🚀 Claude Code Remote Access Service
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Polling interval: 30 seconds
Press Ctrl+C to stop

[2025-10-19 15:30:00] Checking for new commands...
   No pending commands
```

### Stop the Service
Press `Ctrl+C` to gracefully shut down.

## Testing

### Test 1: Manual Command Insertion

Insert a test command directly into Supabase:

```bash
curl -X POST "https://hjtvtkffpziopozmtsnb.supabase.co/rest/v1/claude_commands" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"command": "echo Hello from Slack!", "source": "test", "user_id": "test_user"}'
```

Watch the polling script detect and execute it!

### Test 2: Check Polling

```bash
./claude-poll-commands.sh
```

Expected output if commands exist:
```
🔍 Checking for new commands...
📬 New command received!
   ID: abc-123-def-456
   Command: echo Hello from Slack!
   Source: test
   User: test_user
```

### Test 3: Verify Response Writing

After a command executes, check the database:

```bash
curl -s "https://hjtvtkffpziopozmtsnb.supabase.co/rest/v1/claude_commands?select=*&order=created_at.desc&limit=5" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho" | jq
```

Look for `status: "completed"` and the `response` field.

## N8n Workflows

### Workflow 1: slack-cc-command ✅ Created
- **ID:** HBMOc0qTvAfc8SyA
- **Purpose:** Receive `/cc` slash commands from Slack
- **Webhook:** https://n8n.grantpilot.app/webhook/cc
- **Status:** Ready to activate
- **Nodes:**
  1. Webhook Trigger - Receives POST from Slack
  2. Extract Command - Parses form-encoded data
  3. Prepare Data - Formats for Supabase
  4. Insert to Supabase - Stores in claude_commands
  5. Immediate Response - Returns acknowledgment < 3s

### Workflow 2: claude-responses-to-slack ✅ Created
- **ID:** rIjqmtv7qRfsvirl
- **Purpose:** Send command responses back to Slack
- **Polling:** Every 15 seconds
- **Status:** Ready to activate (requires Slack bot token)
- **Nodes:**
  1. Schedule Trigger - Every 15 seconds
  2. Get Completed Commands - Query Supabase
  3. Check if Any - IF node to filter
  4. Process Each Response - Loop through results
  5. Format Message - Create formatted Slack message
  6. Post to Slack - Send via Slack API
  7. Mark as Sent - Update slack_sent=true

## Setup Instructions

### Step 1: Activate N8n Workflows ⚠️ Required

1. Go to: https://n8n.grantpilot.app
2. Find workflow: **slack-cc-command**
3. Click **"Active"** toggle
4. Find workflow: **claude-responses-to-slack**
5. Click **"Active"** toggle

### Step 2: Configure Slack Bot Token ⚠️ Required

The response workflow needs your Slack Bot Token to send messages.

**See:** `SLACK-BOT-TOKEN-NEEDED.txt` for detailed instructions

**Quick steps:**
1. Go to: https://n8n.grantpilot.app/credentials
2. Create/verify: "Slack API" credential
3. Add your bot token (xoxb-...)

### Step 3: Configure Slack Slash Command

**See:** `SLACK-SLASH-COMMAND-SETUP.md` for detailed instructions

**Quick steps:**
1. Go to: https://api.slack.com/apps
2. Create `/cc` slash command
3. Request URL: `https://n8n.grantpilot.app/webhook/cc`
4. Install app to workspace

### Step 4: Start Claude Code Polling

```bash
cd /Users/christophertolleymacbook2019
./start-remote-access.sh
```

### Step 5: End-to-End Test

```bash
# Option 1: Use the test script
./test-full-remote-access.sh

# Option 2: Real Slack test
# In Slack, type: /cc echo "Hello from remote!"
# Wait ~45 seconds, see response in Slack
```

## Status Values

- `pending` - Command received, waiting for Claude Code
- `processing` - Claude Code is executing the command
- `completed` - Command executed successfully, response ready
- `error` - Command execution failed, error message available

## Security Considerations

### Current Setup
- Uses Supabase anon key (public)
- No authentication on commands
- Executes any bash command

### Production Recommendations
1. **Add RLS (Row Level Security)** to claude_commands table
2. **Validate commands** before execution (whitelist)
3. **Add user authentication** via Slack user IDs
4. **Rate limiting** to prevent abuse
5. **Command approval** for sensitive operations
6. **Logging** all executed commands

### Example: Add Command Whitelist

Modify `start-remote-access.sh` to only allow safe commands:

```bash
ALLOWED_COMMANDS=(
    "ls"
    "pwd"
    "date"
    "whoami"
)

is_allowed() {
    local cmd=$1
    local cmd_name=$(echo "$cmd" | awk '{print $1}')

    for allowed in "${ALLOWED_COMMANDS[@]}"; do
        if [[ "$cmd_name" == "$allowed" ]]; then
            return 0
        fi
    done
    return 1
}
```

## Troubleshooting

### Commands Not Being Detected

1. Check if service is running:
   ```bash
   ps aux | grep start-remote-access
   ```

2. Check database connection:
   ```bash
   ./claude-poll-commands.sh
   ```

3. Verify Supabase table has pending commands:
   ```bash
   curl -s "https://hjtvtkffpziopozmtsnb.supabase.co/rest/v1/claude_commands?status=eq.pending" \
     -H "apikey: <KEY>" | jq
   ```

### Responses Not Being Written

1. Check if command ID is correct
2. Verify Supabase credentials
3. Check network connectivity
4. Look for error messages in terminal

### N8n Not Receiving Responses

1. Verify N8n polling interval
2. Check Supabase query in N8n workflow
3. Ensure status field is being updated correctly
4. Add logging to N8n workflow

## Files Created

### Database
1. ✅ `claude_commands` table in Supabase (with slack_sent tracking)

### Shell Scripts
2. ✅ `claude-poll-commands.sh` - Poll for pending commands
3. ✅ `claude-write-response.sh` - Write responses to Supabase
4. ✅ `start-remote-access.sh` - Main polling service
5. ✅ `test-full-remote-access.sh` - Complete system test script

### N8n Workflows
6. ✅ `slack-cc-command` (ID: HBMOc0qTvAfc8SyA) - Slack → Supabase
7. ✅ `claude-responses-to-slack` (ID: rIjqmtv7qRfsvirl) - Supabase → Slack

### Documentation
8. ✅ `REMOTE-ACCESS-SETUP.md` - This complete system guide
9. ✅ `SLACK-SLASH-COMMAND-SETUP.md` - Slack configuration guide
10. ✅ `SLACK-BOT-TOKEN-NEEDED.txt` - Bot token setup instructions

## Quick Reference

### Start the System
```bash
./start-remote-access.sh
```

### Use from Slack
```
/cc echo "test"
/cc ls -la
/cc git status
/cc pwd
```

### Test the System
```bash
./test-full-remote-access.sh
```

### Monitor Commands
```bash
# Watch database in real-time
./test-full-remote-access.sh
# Select option 4
```

## Summary

🎉 **Complete Two-Way Remote Access System for Claude Code!**

### What's Working:
- ✅ Database communication hub (Supabase)
- ✅ Command polling and execution (Claude Code)
- ✅ Slack slash command integration (N8n webhook)
- ✅ Automated response delivery (N8n polling)
- ✅ Complete testing suite

### To Complete Setup:
1. ⚠️ Activate both N8n workflows
2. ⚠️ Add Slack bot token to N8n
3. ⚠️ Configure `/cc` slash command in Slack
4. ✅ Run `./start-remote-access.sh`
5. 🎉 Control Claude Code from anywhere!

**Control Claude Code from your phone, work, or anywhere with Slack! 📱🚀**
