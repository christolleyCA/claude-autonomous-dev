# Session Startup Guide

*Last Updated: 2025-11-09*

This guide explains how to start Claude Code sessions and what context to provide at the beginning of each session.

---

## Quick Start

### Starting GrantPilot

```bash
~/projects/launcher/grantpilot
```

This automatically:
1. Changes to `/Users/christophertolleymacbook2019/autonomous-dev`
2. Sets environment variables for shared resources
3. Runs startup checks (`start-everything.sh`)
   - Checks prerequisites (git, curl, jq)
   - Starts remote access service with watchdog (optional Slack integration)
   - Verifies git repository status
   - Checks MCP server connectivity
   - Validates disk space
4. Launches `claude` (Claude Code CLI)

### Starting a New Project

```bash
~/projects/launcher/new-project my-saas-app
```

This automatically creates and starts a new project with shared infrastructure.

---

## What to Say at Session Start

### Recommended Startup Message

When Claude Code starts, provide this context:

```
I have an autonomous development system set up with:

- Multi-project system with shared knowledge base
- Autonomous tools (solution-searcher.sh, parallel processing scripts)
- Supabase Edge Functions for orchestration (primary)
- N8N workflows (secondary, when appropriate)
- MCP servers: Supabase, Sentry, N8N, Docs, GitHub

Current Project: GrantPilot
Recent Activity: [Brief 1-2 sentence summary of what you've been working on]

Please verify MCP connectivity and check docs/GETTING-STARTED.md for full context.
```

**Example:**
```
I have an autonomous development system set up with:

- Multi-project system with shared knowledge base
- Autonomous tools (solution-searcher.sh, parallel processing scripts)
- Supabase Edge Functions for orchestration (primary)
- N8N workflows (secondary, when appropriate)
- MCP servers: Supabase, Sentry, N8N, Docs, GitHub

Current Project: GrantPilot
Recent Activity: Just finished classifying 751K nonprofits and discovering websites for public-facing ones using Tavily API.

Please verify MCP connectivity and check docs/GETTING-STARTED.md for full context.
```

---

##Important Notes

### About `/cc` Commands

**CLARIFICATION:** `/cc` commands are for **remote access** (Slack integration), NOT for Claude Code CLI sessions.

- `/cc echo "Hello"` - Sends command to autonomous system via Slack
- `/cc system-status` - Checks system status via Slack
- `/cc build-feature` - Triggers feature building via Slack

**These do NOT work in Claude Code sessions.** They're only for remote control when you're not at your computer.

### Restoring Context

Claude Code automatically maintains context through:
1. **Git Repository**: All code and documentation
2. **MCP Servers**: Direct connections to Supabase, Sentry, etc.
3. **Documentation**: `docs/GETTING-STARTED.md`, Edge Functions catalog, etc.
4. **Shared Tools**: Knowledge base searcher, autonomous scripts

**No manual "restore-context" command needed** - just provide the startup message above.

---

## Verification Steps

After starting Claude, verify system readiness:

### 1. Check MCP Servers

The `start-everything.sh` script already checks MCPs, but you can manually verify:

```bash
claude mcp list
```

Expected output:
```
✓ Connected: supabase
✓ Connected: n8n-mcp
✓ Connected: sentry
✓ Connected: github
✓ Connected: docs
```

### 2. Check Git Status

```bash
git status
git log -1 --oneline
```

### 3. Access Knowledge Base

```bash
~/claude-shared/autonomous-tools/solution-searcher.sh "recent solutions"
```

### 4. Verify Shared Resources

```bash
ls ~/claude-shared/
# Should show: mcp-config/ knowledge-base/ autonomous-tools/ edge-functions/
```

---

## What start-everything.sh Does

When you run `~/projects/launcher/grantpilot`, it automatically executes `start-everything.sh` which:

### Checks Prerequisites
- Git installed
- curl installed
- jq installed (optional)

### Starts Services
- Remote access polling with watchdog (for Slack integration)
- Background monitoring services

### System Health Checks
- Git repository status
- Service heartbeat verification
- Running process counts
- Disk space validation
- MCP server connectivity

### Output Example
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 STARTING AUTONOMOUS DEVELOPMENT SYSTEM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Checking prerequisites...
✓ Prerequisites OK

📋 Starting services...

1️⃣ Starting remote access service with watchdog...
   ✓ Already running (PID: 12345)

🔍 System Status Check...

2️⃣ Checking Git repository...
   ✓ Git repository OK
   Branch: main
   Last commit: 9412c20 - Multi-Project Development System (2 hours ago)

3️⃣ Checking service heartbeat...
   ✓ Service is healthy (heartbeat 45s ago)

4️⃣ Checking running processes...
   Polling services: 1
   Watchdog services: 1

5️⃣ Checking disk space...
   ✓ Disk space OK (45% used)

6️⃣ Checking MCP servers...
   Running MCP health check...
   ✓ 5 MCP(s) connected
   ✓ supabase
   ✓ n8n-mcp
   ✓ sentry

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ SYSTEM READY!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Differences Between Old and New Method

### OLD Method (Manual)
```bash
cd ~/autonomous-dev
./start-everything.sh
claude --model opusplan
```

### NEW Method (Automated)
```bash
~/projects/launcher/grantpilot
```

**What Changed:**
- ✅ Automatic `start-everything.sh` execution
- ✅ Environment variables set automatically
- ✅ No need to specify `--model opusplan` (Claude Code uses default model)
- ✅ Simpler one-command startup
- ✅ Works from any directory

---

## Troubleshooting

### MCPs Not Connected

If `start-everything.sh` shows MCPs disconnected:

```bash
# Check MCP configuration
cat ~/.config/claude/mcp.json

# Verify symlink
ls -la ~/.config/claude/mcp.json
# Should show: ~/.config/claude/mcp.json -> ~/claude-shared/mcp-config/mcp.json
```

### Remote Access Service Not Starting

Check logs:
```bash
tail -f /tmp/remote-access-startup.log
```

### Git Issues

Verify working directory:
```bash
pwd
# Should show: /Users/christophertolleymacbook2019/autonomous-dev

git status
```

---

## Summary

**Starting Claude Code:**
```bash
~/projects/launcher/grantpilot
```

**Startup Message (copy-paste to first Claude message):**
```
I have an autonomous development system set up with:

- Multi-project system with shared knowledge base
- Autonomous tools (solution-searcher.sh, parallel processing scripts)
- Supabase Edge Functions for orchestration (primary)
- N8N workflows (secondary, when appropriate)
- MCP servers: Supabase, Sentry, N8N, Docs, GitHub

Current Project: GrantPilot
Recent Activity: [Your brief summary here]

Please verify MCP connectivity and check docs/GETTING-STARTED.md for full context.
```

**No manual context restoration needed** - everything loads automatically!

---

**Related Documentation:**
- [Multi-Project Quickstart](./MULTI-PROJECT-QUICKSTART.md)
- [Getting Started Guide](./GETTING-STARTED.md)
- [Edge Functions Catalog](./supabase-edge-functions/EDGE-FUNCTIONS-CATALOG.md)
