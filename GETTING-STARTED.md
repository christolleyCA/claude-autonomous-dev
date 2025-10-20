# 🚀 Getting Started Guide

**Everything you need to restart your autonomous development system after closing your laptop.**

---

## ⚡ Quick Start (When You Return)

### ONE COMMAND TO START EVERYTHING:

```bash
cd /Users/christophertolleymacbook2019
./start-everything.sh
```

**That's it!** Everything starts automatically.

---

## ✅ Verify It's Working

### Test from Slack (after ~30 seconds):
```
/cc echo "System test"
```

You should see:
1. Immediate: "🤖 Command received!"
2. After ~30s: Your message echoed back

### Check system status:
```
/cc system-status
```

Shows:
- Service health
- Last command processed
- System metrics

---

## 🔄 What's Running (Behind the Scenes)

When you run `./start-everything.sh`, it starts:

1. **start-with-watchdog.sh**
   - Main polling service
   - Checks Supabase every 15 seconds for new commands
   - Auto-restarts if it crashes

2. **Heartbeat monitoring**
   - Updates `/tmp/claude-remote-access-heartbeat` every iteration
   - Watchdog checks this to detect hangs

3. **Command processing**
   - Executes commands from Slack
   - Logs results
   - Posts responses back

### Services that are ALWAYS running (in cloud):
- **N8n workflows** (already configured)
- **Supabase database** (stores commands/responses)
- **Slack integration** (receives /cc commands)

---

## 📂 File Locations

Everything is in:
```
/Users/christophertolleymacbook2019/
```

### Key Files:
```
start-everything.sh          # Master startup (USE THIS)
stop-everything.sh           # Stop all services
start-with-watchdog.sh       # Main service + watchdog
start-remote-access.sh       # Core polling script

build-feature.sh             # Autonomous feature builder
self-review.sh               # Code quality review
predict-issues.sh            # Bug prediction
generate-tests.sh            # Test generation
monitor-deployment.sh        # Deployment monitoring
map-codebase.sh              # Codebase analysis

solution-logger.sh           # Knowledge base logging
solution-searcher.sh         # KB search
view-solutions.sh            # KB viewer

git-helpers.sh               # Git utility functions
slack-logger.sh              # Slack notification helper
```

### Documentation:
```
GETTING-STARTED.md           # This file
QUICK-REFERENCE.txt          # Command cheat sheet
ULTIMATE-AUTONOMOUS-SYSTEM.md    # Complete system guide
KNOWLEDGE-BASE-COMPLETE.md   # KB system details
GIT-SETUP-COMPLETE.md        # Git integration guide
```

---

## 🎮 Using the System

### From Slack:

#### Basic Commands:
```
/cc echo "test"                  # Test if working
/cc system-status                # Check system health
/cc help                         # Show available commands
```

#### Build Features:
```
/cc build-feature my-feature "Description here"
```

This runs the FULL autonomous workflow:
- Knowledge base check
- Codebase mapping
- Predictive analysis
- Build + test
- Self-review
- Deployment monitoring

#### Knowledge Base:
```
/cc search-solutions "database timeout"
/cc show-recent-solutions
/cc view-stats
```

#### Git Operations:
```
/cc git-status
/cc git-recent 10
/cc git-commit "message"
```

#### Code Analysis:
```
/cc self-review my-feature /path/to/file.ts
/cc predict-issues my-feature /path/to/file.ts
/cc map-codebase
```

### From Terminal:

```bash
# Start/stop
./start-everything.sh
./stop-everything.sh

# View logs
tail -f /tmp/remote-access-startup.log

# Check processes
ps aux | grep start-remote-access

# Manual commands
./build-feature.sh feature-name "description"
./view-solutions.sh stats
./map-codebase.sh
```

---

## 🐛 Troubleshooting

### Problem: "/cc commands don't work"

**Solution 1** - Restart services:
```bash
./stop-everything.sh
./start-everything.sh
```

**Solution 2** - Check if running:
```bash
ps aux | grep start-remote-access
```

If nothing shows up, the service isn't running. Start it:
```bash
./start-everything.sh
```

**Solution 3** - Check logs:
```bash
tail -f /tmp/remote-access-startup.log
```

Look for errors. Common issues:
- API keys not set
- Network connectivity
- Supabase connection

### Problem: "Service keeps crashing"

Check the heartbeat age:
```bash
cat /tmp/claude-remote-access-heartbeat
```

If it's old (>120 seconds), the watchdog should have restarted it. If not:
```bash
./stop-everything.sh
./start-everything.sh
```

### Problem: "Lost all my files" (nightmare scenario)

Don't panic! Everything is backed up:

1. **Git repository** (local):
   ```bash
   git log  # See all commits
   git show <commit>  # View specific commit
   ```

2. **GitHub** (if you pushed):
   ```bash
   git remote -v  # Check if remote configured
   git pull origin main  # Restore from GitHub
   ```

3. **Supabase database** (cloud):
   - Knowledge base persists
   - All analytics data safe
   - Command history preserved

4. **N8n workflows** (cloud):
   - All workflows still configured
   - Nothing to restore

### Problem: "Commands are slow"

This is normal! The system polls every 15 seconds, so:
- Minimum response time: 15 seconds
- Average response time: 30 seconds
- Maximum response time: 60 seconds (if command takes time)

If it's slower than this, check:
```bash
tail -f /tmp/remote-access-startup.log
```

---

## 💡 What You DON'T Need to Reconfigure

✅ N8n workflows (cloud, always running)
✅ Supabase tables (cloud, persist forever)
✅ Slack integration (already set up)
✅ Sentry monitoring (configured)
✅ Git repository (initialized)
✅ MCP servers (configured in ~/.config/claude-code/)
✅ Knowledge base data (in Supabase)
✅ All scripts and documentation (in Git)

## ⚠️ What You DO Need to Start

▶️ **Only this:** `./start-everything.sh`

That's it! One command restarts everything.

---

## 🆕 Opening a New Claude Code Session

When you open a new Claude Code terminal:

1. **Claude has NO memory** of previous conversations
2. **But it HAS access** to all files and scripts
3. **And it CAN use** all configured MCPs

### First message to new Claude instance:
```
I have an autonomous development system set up.
Check GETTING-STARTED.md for full context.
I want to [what you want to do].
```

Claude will read the docs and understand your setup!

---

## 📋 Daily Startup Checklist

```
□ Open terminal
□ cd /Users/christophertolleymacbook2019
□ Run: ./start-everything.sh
□ Wait 30 seconds
□ Test: /cc echo "test" (from Slack)
□ Verify: See response in Slack
□ ✅ Ready to work!
```

---

## 🔒 Before Closing Laptop (Optional but Recommended)

```bash
# Save current work
git add .
git commit -m "Session backup"
git push  # If GitHub configured

# Stop services (optional - they'll survive sleep mode)
./stop-everything.sh
```

---

## 🎯 Quick Tips

### Tip 1: Keep it simple
- Just use `./start-everything.sh` every time
- Don't manually start individual services

### Tip 2: Test immediately
- After starting, test with `/cc echo "test"`
- Confirms everything is working

### Tip 3: Check logs if issues
- `tail -f /tmp/remote-access-startup.log`
- Shows exactly what's happening

### Tip 4: Git is your safety net
- All work is committed to Git
- Never lose code
- Easy to roll back

### Tip 5: Knowledge base grows over time
- Every build adds to the knowledge base
- System gets smarter automatically
- View progress: `./view-solutions.sh stats`

---

## 📞 Emergency Recovery

If everything is broken and nothing works:

```bash
# Nuclear option - restart everything
killall start-remote-access.sh
killall watchdog.sh
rm /tmp/claude-remote-access-heartbeat
./start-everything.sh
```

If that doesn't work, you can manually execute commands:
```bash
# Execute a command directly
./build-feature.sh test-feature "test"
```

---

## 🎓 Summary

**To start after closing laptop:**
```bash
./start-everything.sh
```

**To verify it's working:**
```
/cc echo "test"
```

**To stop (optional):**
```bash
./stop-everything.sh
```

**That's literally all you need to know!** 🎉

Everything else is automatic. Your autonomous system takes care of the rest.

---

## 📚 Learn More

- `QUICK-REFERENCE.txt` - Command cheat sheet
- `ULTIMATE-AUTONOMOUS-SYSTEM.md` - Full system capabilities
- `KNOWLEDGE-BASE-COMPLETE.md` - KB system details
- `GIT-SETUP-COMPLETE.md` - Git integration

---

**Welcome back! Your autonomous development system is ready to go.** 🚀
