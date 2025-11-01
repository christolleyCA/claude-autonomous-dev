# Fully Autonomous Slack Response System

## What This Does

**100% AUTONOMOUS** - No manual intervention needed! This service:

1. Monitors for new Slack messages every 20 seconds
2. Uses Claude API to generate intelligent responses automatically
3. Posts responses back to Slack within seconds
4. Runs 24/7 in the background

## Setup Instructions

### Step 1: Get Your Anthropic API Key

1. Go to: https://console.anthropic.com/
2. Sign in or create an account
3. Navigate to API Keys
4. Create a new key (or use an existing one)
5. Copy the key (starts with `sk-ant-...`)

### Step 2: Set the API Key

**Option A: Set for current session**
```bash
export ANTHROPIC_API_KEY='sk-ant-your-key-here'
```

**Option B: Add to your shell profile (recommended)**
```bash
# Add to ~/.bashrc or ~/.zshrc
echo 'export ANTHROPIC_API_KEY="sk-ant-your-key-here"' >> ~/.zshrc
source ~/.zshrc
```

**Option C: Run directly with the key**
```bash
ANTHROPIC_API_KEY='sk-ant-your-key-here' ./autonomous-responder.sh > /tmp/autonomous-responder.log 2>&1 &
```

### Step 3: Start the Autonomous Responder

```bash
./autonomous-responder.sh > /tmp/autonomous-responder.log 2>&1 &
```

The service will now:
- Run in the background
- Check for messages every 20 seconds
- Automatically respond using Claude API
- Never require manual intervention!

### Step 4: Verify It's Running

```bash
# Check process:
pgrep -f autonomous-responder

# Watch the log:
tail -f /tmp/autonomous-responder.log
```

## Complete Service Stack

With autonomous mode, you have **4 services**:

1. **Conversation Service** - Receives messages from Slack
2. **Response Posting Service** - Posts responses to Slack
3. **Message Monitor** - Visual alerts for new messages (optional)
4. **Autonomous Responder** - **NEW!** Auto-generates responses ⭐

## Testing

1. Send from Slack: `/cc tell me a joke`
2. Wait ~30 seconds
3. Claude API generates response automatically
4. Response appears in Slack - NO MANUAL ACTION NEEDED!

## Monitoring

```bash
# See all services:
ps aux | grep -E "claude-conversation|claude-respond|slack-message-monitor|autonomous-responder" | grep -v grep

# View logs:
tail -f /tmp/autonomous-responder.log        # Auto-responder
tail -f /tmp/claude-respond.log              # Slack posting
tail -f /tmp/claude-conversation.log         # Message receiving
```

## Cost Considerations

The autonomous responder uses the Claude API which has costs:
- Claude Sonnet 4: ~$3 per million input tokens
- Each message typically uses ~200-500 tokens
- Estimated cost: $0.0005 - $0.001 per message

For typical usage (10-50 messages/day), this is very affordable!

## Stopping the Service

```bash
# Stop autonomous responder:
pkill -f autonomous-responder

# Or stop all services:
pkill -f claude-conversation-service
pkill -f claude-respond-service
pkill -f slack-message-monitor
pkill -f autonomous-responder
```

## Troubleshooting

### "ANTHROPIC_API_KEY not set" error

The API key isn't configured. Follow Step 2 above.

### Responses not being generated

```bash
# Check the log for errors:
tail -20 /tmp/autonomous-responder.log

# Common issues:
# - Invalid API key
# - API rate limits
# - Network connectivity
```

### Messages still stuck in "processing"

```bash
# Restart the autonomous responder:
pkill -f autonomous-responder
export ANTHROPIC_API_KEY='your-key'
./autonomous-responder.sh > /tmp/autonomous-responder.log 2>&1 &
```

---

## Alternative: Manual Mode

If you prefer to control responses manually (no API costs):

1. Don't run the autonomous responder
2. Use `/check-slack` command when you want to respond
3. Or run `./check-slack-messages.sh` periodically

The system works both ways!
