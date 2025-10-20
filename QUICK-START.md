# Slack /cc Automation - Quick Start

## ✅ What's Running Now

Your automated Slack response system is fully operational with 3 services running:

1. **Conversation Service** (PID: 4097) - Receives messages from Slack
2. **Response Posting Service** (PID: 19735) - Posts responses back to Slack
3. **Message Monitor** (PID: 23504) - Alerts when new messages arrive ⭐ NEW!

## 🚀 How to Use

### Option 1: Slash Command (Easiest!)
In Claude Code, just type:
```
/check-slack
```

I'll automatically check for pending Slack messages and respond to them!

### Option 2: Manual Check
```bash
./check-slack-messages.sh
```

### Option 3: Watch the Monitor
The monitor service is running in the background and will ring a bell + display messages prominently when they arrive. Check its log:
```bash
tail -f /tmp/slack-monitor.log
```

## 📱 Sending Messages from Slack

In your Slack channel (`claude-code-updates`), just type:
```
/cc <your message here>
```

Within 30 seconds:
- Monitor will detect it
- Display it prominently
- Ring terminal bell to alert you
- You respond via `/check-slack`
- Response auto-posts to Slack within 15 seconds

## 🔍 Check Service Status

```bash
# See all running services:
ps aux | grep -E "claude-conversation|claude-respond|slack-message-monitor" | grep -v grep

# Or check individual services:
pgrep -f claude-conversation-service  # Should show: 4097
pgrep -f claude-respond-service       # Should show: 19735
pgrep -f slack-message-monitor        # Should show: 23504
```

## 📊 View Logs

```bash
# Incoming messages:
tail -f /tmp/claude-conversation.log

# Outgoing responses:
tail -f /tmp/claude-respond.log

# Message alerts:
tail -f /tmp/slack-monitor.log
```

## 🧪 Test It Now!

1. Send from Slack: `/cc test - reply to this!`
2. Wait 30 seconds for monitor to detect
3. Run: `/check-slack` in Claude Code
4. I'll respond!
5. Within 15 seconds, see my response in Slack

## ⚡ What Got Fixed

**The Problem**: Messages were being saved to files, but no automatic integration brought them into my conversation. They sat in "processing" status forever.

**The Solution**:
- Created `/check-slack` slash command for easy checking
- Added background monitor that alerts when new messages arrive
- Made it dead simple for you to trigger responses
- Response posting was already automatic - now the whole flow works!

## 📚 Full Documentation

See `SLACK-AUTOMATION-GUIDE.md` for complete details and troubleshooting.

---

**Next Steps**:
1. Try sending a test message from Slack
2. Run `/check-slack` here
3. Watch your response appear in Slack automatically!
