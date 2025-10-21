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

#### Git Operations (NEW! Automatic Backups):
```
/cc git-commit                    # Smart commit with auto-generated message
/cc git-commit-and-push           # Commit AND push to GitHub automatically
/cc git-status                    # Check uncommitted changes
/cc git-summary                   # Last 5 commits + current state
/cc restore-context               # See what you worked on recently
```

**💡 Pro Tip:** Before closing your laptop, run:
```
/cc git-commit-and-push
```
Everything backed up to GitHub in ONE command!

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

---

## 🔄 Git Operations (Automatic!)

### NEW: Smart Git Automation System

Never lose your work! The system now auto-generates commit messages and backs up to GitHub with ONE command.

### Quick Commit (Smart Messages):
```
/cc git-commit
```

**What happens:**
1. Analyzes all changed files
2. Detects what you worked on (features, docs, scripts, etc.)
3. Creates descriptive commit message automatically
4. Commits locally with attribution to Claude

**Example output:**
```
📊 Analyzing changes...
📝 Changes to commit:
   M  build-feature.sh
   M  restore-context.sh
   A  smart-git-commit.sh

💬 Commit message:
   Session update: Git automation improvements, 3 files

✅ Committed as abc123f
```

### Commit AND Push to GitHub:
```
/cc git-commit-and-push
```

**Does everything:**
1. Creates smart commit message
2. Commits all changes
3. Pushes to GitHub
4. Sends Slack notification with results

**You get notified in Slack:**
```
✅ Git Backup Complete
Commit: `abc123f`
Message: Session update: Enhanced autonomous capabilities, 8 files
Pushed to GitHub ✓
```

### Check Git Status:
```
/cc git-status
```
Shows uncommitted files and current state.

### See Recent Work:
```
/cc git-summary
```
Shows:
- Last 5 commits
- Current branch
- Uncommitted changes

### Restore Context After Restart:
```
/cc restore-context
```

Shows EVERYTHING you need to know:
```
🔍 RESTORING CONTEXT FROM LAST SESSION
════════════════════════════════════════

📅 LAST COMMIT:
   Commit: abc123f
   Date:   2025-10-21 14:30
   Message: Session update: Added git automation

📊 RECENT ACTIVITY (Last 10 commits):
   10/21 14:30 abc123f Session update: Added git automation
   10/21 12:15 def456g Built feature: nonprofit-intelligence-system
   10/20 16:45 ghi789h Documentation updates
   ...

📂 CURRENT STATE:
   Uncommitted changes: 3 files
   Files:
      M  README.md
      A  new-feature.ts
      M  tests/new-test.ts

🚀 SERVICES STATUS:
   ✅ Remote access: Running
   ⚠️  Watchdog: Not running (optional)

════════════════════════════════════════
✅ CONTEXT RESTORED - Ready to continue!
```

---

## 💾 Before Closing Laptop (Recommended Workflow)

### Option 1: Full Backup (Recommended)
```
/cc git-commit-and-push
```
**One command. Everything saved to GitHub. Sleep easy!**

### Option 2: Local Save Only
```
/cc git-commit
```
Commits locally. Push later when you have internet.

### Manual Alternative (if remote access isn't running):
```bash
./smart-git-commit.sh push
```

---

## 🔄 When You Return (New Session)

### Step 1: Start Everything
```bash
./start-everything.sh
```

### Step 2: Restore Context
```
/cc restore-context
```

You'll see:
- What you worked on last
- Recent commits
- Uncommitted changes (if any)
- Service status

### Step 3: Continue Working!
Claude now knows exactly where you left off.

---

## 📖 Git Command Reference

| Command | What It Does | When To Use |
|---------|-------------|-------------|
| `/cc git-commit` | Smart commit with auto message | After work session |
| `/cc git-commit-and-push` | Commit + push to GitHub | Before closing laptop |
| `/cc git-status` | Show uncommitted changes | Check what's modified |
| `/cc git-summary` | Last 5 commits + status | Quick overview |
| `/cc restore-context` | Full session context | When you return |

---

## 🎯 Recommended Daily Workflow

### Morning (When You Start):
```bash
# Terminal
./start-everything.sh

# Slack (after 30 seconds)
/cc restore-context
```

Now you see exactly what you were working on yesterday!

### During Work:
```
# Build features
/cc build-feature my-feature "description"

# Check progress
/cc git-status

# Commit periodically
/cc git-commit
```

### Evening (Before Closing):
```
/cc git-commit-and-push
```

**Done!** Everything backed up. Laptop goes to sleep. Work is safe.

---

## 🆘 Git Recovery Scenarios

### Scenario 1: "I forgot to commit before closing"
**No problem!** Uncommitted changes persist on your machine.

When you return:
```
/cc git-status          # See what wasn't committed
/cc git-commit-and-push # Back it up now
```

### Scenario 2: "I need to see what I did yesterday"
```
/cc restore-context
```

Shows all your recent commits and changes.

### Scenario 3: "I want to undo my last commit"
```bash
git reset --soft HEAD~1   # Undo commit, keep changes
git status                # Verify
```

### Scenario 4: "I pushed by mistake"
Don't panic! Your work is backed up. You can always revert:
```bash
git log              # Find the commit to revert to
git revert <commit>  # Create a new commit that undoes it
```

---

## 💡 Smart Commit Message Examples

The system automatically detects what you worked on:

**Example 1: Built a feature**
```
Session update: Enhanced build-feature system - 5 files
```

**Example 2: Updated docs**
```
Session update: Documentation updates - 12 files
```

**Example 3: Added scripts**
```
Session update: Added/updated scripts, Git automation improvements - 8 files
```

**Example 4: Multiple changes**
```
Session update: Code changes, Database schema updates, Documentation updates - 23 files
```

All messages include:
- Co-authored by Claude
- Generated with Claude Code attribution
- File count

---

## 🔐 Security Note

### What Gets Committed:
✅ Source code
✅ Configuration files
✅ Documentation
✅ Scripts

### What's Ignored (.gitignore):
❌ Environment variables (.env)
❌ API keys
❌ node_modules
❌ Temporary files (/tmp/*)
❌ Build artifacts
❌ Local config

The smart commit analyzer ONLY commits files tracked by Git.

---
