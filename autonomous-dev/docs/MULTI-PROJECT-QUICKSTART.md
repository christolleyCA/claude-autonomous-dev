# Multi-Project Quickstart Guide

*Last Updated: 2025-11-09*

This guide explains how to work on multiple projects with Claude Code while maintaining access to the shared knowledge base, autonomous tools, and MCP servers.

---

## Quick Start

### Starting Grant Pilot (Current Project)
```bash
cd ~/autonomous-dev
claude
```

### Starting a New Project
```bash
# Will be set up with shared infrastructure
~/projects/launcher/start-newproject.sh my-awesome-app
```

---

## Architecture Overview

```
Your Development Setup:

~/claude-shared/              # Shared across ALL projects
├─ mcp-config/               # MCP servers (Supabase, Sentry, etc.)
├─ knowledge-base/           # Solutions database + docs
├─ autonomous-tools/         # Reusable automation scripts
└─ edge-functions/          # Production Edge Function templates

~/autonomous-dev/            # GrantPilot project
├─ .claude/ → ~/claude-shared/mcp-config/  # Symlink
├─ docs/                    # Project-specific docs
├─ lib/                     # Project code
└─ config/                  # Project config

~/projects/my-new-app/      # New project
├─ .claude/ → ~/claude-shared/mcp-config/  # Same MCPs!
├─ src/                     # Project code
└─ docs/                    # Project docs
```

---

## Setup Instructions

### Step 1: Create Shared Infrastructure

Run this once to set up shared resources:

```bash
# Create shared directory structure
mkdir -p ~/claude-shared/{mcp-config,knowledge-base,autonomous-tools,edge-functions}

# Move MCP configuration to shared location
cp ~/.config/claude/mcp.json ~/claude-shared/mcp-config/mcp.json

# Create symlink (all projects will use this)
rm ~/.config/claude/mcp.json
ln -s ~/claude-shared/mcp-config/mcp.json ~/.config/claude/mcp.json

# Copy autonomous tools to shared location
cp ~/autonomous-dev/lib/solution-searcher.sh ~/claude-shared/autonomous-tools/
cp /tmp/process-all-tavily-parallel.sh ~/claude-shared/autonomous-tools/
cp /tmp/classify-parallel.py ~/claude-shared/autonomous-tools/

# Create project launcher directory
mkdir -p ~/projects/launcher
```

### Step 2: Create Project Launchers

**GrantPilot Launcher** (`~/projects/launcher/start-grantpilot.sh`):
```bash
#!/bin/bash
export CLAUDE_PROJECT="grantpilot"
export CLAUDE_WORKING_DIR="$HOME/autonomous-dev"
export CLAUDE_SHARED="$HOME/claude-shared"

cd "$CLAUDE_WORKING_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting GrantPilot Project"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 Working Directory: $CLAUDE_WORKING_DIR"
echo "🔧 Shared Resources:  $CLAUDE_SHARED"
echo "🤖 Knowledge Base:    $CLAUDE_SHARED/knowledge-base"
echo "⚡ Autonomous Tools:  $CLAUDE_SHARED/autonomous-tools"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

claude
```

**New Project Launcher** (`~/projects/launcher/start-newproject.sh`):
```bash
#!/bin/bash
PROJECT_NAME=$1

if [ -z "$PROJECT_NAME" ]; then
  echo "Usage: ./start-newproject.sh project-name"
  echo ""
  echo "Examples:"
  echo "  ./start-newproject.sh my-saas-app"
  echo "  ./start-newproject.sh ecommerce-platform"
  exit 1
fi

export CLAUDE_PROJECT="$PROJECT_NAME"
export CLAUDE_WORKING_DIR="$HOME/projects/$PROJECT_NAME"
export CLAUDE_SHARED="$HOME/claude-shared"

# Create project directory if it doesn't exist
mkdir -p "$CLAUDE_WORKING_DIR"
cd "$CLAUDE_WORKING_DIR"

# Create .claude symlink to shared MCP config
mkdir -p .claude
if [ ! -f ".claude/mcp.json" ]; then
  ln -s "$CLAUDE_SHARED/mcp-config/mcp.json" ".claude/mcp.json"
  echo "✅ Linked shared MCP configuration"
fi

# Create basic project structure
mkdir -p {src,docs,tests,config}

# Create README if it doesn't exist
if [ ! -f "README.md" ]; then
  cat > README.md << 'EOF'
# Project Name

Created with Claude Code multi-project setup.

## Shared Resources

This project has access to:
- **Shared Knowledge Base**: `~/claude-shared/knowledge-base`
- **Autonomous Tools**: `~/claude-shared/autonomous-tools`
- **MCP Servers**: Supabase, Sentry, N8N, Docs
- **Edge Functions**: Reusable templates

## Getting Started

See main documentation in `~/claude-shared/knowledge-base/docs/`
EOF
  echo "✅ Created README.md"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting $PROJECT_NAME Project"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 Working Directory: $CLAUDE_WORKING_DIR"
echo "🔧 Shared Resources:  $CLAUDE_SHARED"
echo "🤖 Knowledge Base:    $CLAUDE_SHARED/knowledge-base"
echo "⚡ Autonomous Tools:  $CLAUDE_SHARED/autonomous-tools"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

claude
```

### Step 3: Make Launchers Executable

```bash
chmod +x ~/projects/launcher/start-grantpilot.sh
chmod +x ~/projects/launcher/start-newproject.sh
```

---

## Usage

### Working on GrantPilot

```bash
~/projects/launcher/start-grantpilot.sh
```

Claude will start in `/Users/christophertolleymacbook2019/autonomous-dev` with access to:
- ✅ All GrantPilot code and documentation
- ✅ Shared knowledge base
- ✅ Shared autonomous tools
- ✅ Supabase, Sentry, N8N MCPs

### Starting a New Project

```bash
~/projects/launcher/start-newproject.sh my-saas-app
```

Claude will:
1. Create `~/projects/my-saas-app/` directory
2. Set up basic project structure (src, docs, tests, config)
3. Link shared MCP configuration
4. Create README with shared resources info
5. Start Claude in the new project directory

You'll have access to:
- ✅ Same MCPs as GrantPilot (Supabase, Sentry, etc.)
- ✅ Same knowledge base with all solutions
- ✅ Same autonomous tools and scripts
- ✅ Fresh project directory for new code

### Switching Between Projects

Just run the appropriate launcher:

```bash
# Work on GrantPilot
~/projects/launcher/start-grantpilot.sh

# Work on new app
~/projects/launcher/start-newproject.sh my-saas-app

# Work on another project
~/projects/launcher/start-newproject.sh ecommerce-site
```

---

## Accessing Shared Resources

### Knowledge Base

From any project, Claude can search the knowledge base:

```bash
# Search for solutions
~/claude-shared/autonomous-tools/solution-searcher.sh "database timeout"

# Get specific solution
~/claude-shared/autonomous-tools/solution-searcher.sh --id abc123
```

### Autonomous Tools

All projects can use shared automation:

```bash
# Website discovery (Tavily + Supabase Edge Function)
~/claude-shared/autonomous-tools/process-all-tavily-parallel.sh

# Classification (parallel LLM processing)
python3 ~/claude-shared/autonomous-tools/classify-parallel.py
```

### Edge Functions

Reusable Edge Function templates are in `~/claude-shared/edge-functions/`:

```
edge-functions/
├─ process-nonprofits-tavily/    # Website discovery
├─ extract-location-data/        # Location extraction
└─ classify-nonprofits/          # Classification (future)
```

Copy these to your Supabase project and deploy:

```bash
# Copy template to your project
cp -r ~/claude-shared/edge-functions/process-nonprofits-tavily ./supabase/functions/

# Deploy to your Supabase project
supabase functions deploy process-nonprofits-tavily --project-ref YOUR_PROJECT_REF
```

### MCP Servers

All projects share the same MCP configuration automatically:

- **Supabase**: Direct database access and Edge Functions
- **Sentry**: Error tracking and monitoring
- **N8N**: Workflow automation (when needed)
- **Docs**: Access to documentation servers

No setup required - they just work in every project!

---

## Best Practices

### 1. Keep Project-Specific Code Separate

```
✅ Good:
~/projects/my-app/src/          # App-specific code here
~/claude-shared/autonomous-tools/  # Reusable tools here

❌ Bad:
~/projects/my-app/shared-stuff/    # Don't duplicate shared code
```

### 2. Add Solutions to Shared Knowledge Base

When you solve a problem in any project, add it to the shared knowledge base:

```sql
INSERT INTO claude_solutions (issue_title, solution_summary, ...)
VALUES ('Fixed database connection timeout', '...', ...);
```

All projects can now benefit from this solution!

### 3. Contribute Edge Functions Back

If you create a useful Edge Function in one project, add it to the shared library:

```bash
# After testing in your project
cp ./supabase/functions/my-awesome-function ~/claude-shared/edge-functions/

# Document it
# Update ~/autonomous-dev/docs/supabase-edge-functions/EDGE-FUNCTIONS-CATALOG.md
```

### 4. Use Environment Variables for Project-Specific Config

```bash
# Each project has its own .env
~/autonomous-dev/.env                 # GrantPilot config
~/projects/my-saas-app/.env          # SaaS app config

# But shares MCP config
~/.config/claude/mcp.json → ~/claude-shared/mcp-config/mcp.json
```

---

## Troubleshooting

### MCPs Not Working in New Project

**Problem**: MCP servers not available in new project

**Solution**: Check symlink exists
```bash
ls -la ~/projects/my-project/.claude/mcp.json

# Should show: .claude/mcp.json -> /Users/.../claude-shared/mcp-config/mcp.json

# If missing, create it:
ln -s ~/claude-shared/mcp-config/mcp.json ~/.config/claude/mcp.json
```

### Can't Access Knowledge Base

**Problem**: Solution searcher script not found

**Solution**: Verify shared tools are in place
```bash
ls ~/claude-shared/autonomous-tools/

# Should see:
# - solution-searcher.sh
# - process-all-tavily-parallel.sh
# - classify-parallel.py
```

### Wrong Working Directory

**Problem**: Claude starts in wrong directory

**Solution**: Use launcher scripts, don't run `claude` directly
```bash
# ❌ Don't do this:
cd ~/projects/my-app && claude

# ✅ Do this instead:
~/projects/launcher/start-newproject.sh my-app
```

---

## Summary

### What's Shared Across Projects

✅ MCP Configuration (Supabase, Sentry, etc.)
✅ Knowledge Base (all solutions)
✅ Autonomous Tools (scripts, automation)
✅ Edge Function Templates
✅ Documentation

### What's Project-Specific

📁 Source code (`src/`, `lib/`, etc.)
📁 Project docs (`docs/`)
📁 Environment variables (`.env`)
📁 Git repository (`.git/`)
📁 Dependencies (`package.json`, `requirements.txt`)

### Quick Reference

```bash
# Work on GrantPilot
~/projects/launcher/start-grantpilot.sh

# Create new project
~/projects/launcher/start-newproject.sh project-name

# Search knowledge base
~/claude-shared/autonomous-tools/solution-searcher.sh "query"

# List shared tools
ls ~/claude-shared/autonomous-tools/

# List Edge Function templates
ls ~/claude-shared/edge-functions/
```

---

**Next Steps:**
1. Run setup instructions (Step 1)
2. Create launcher scripts (Step 2)
3. Test with new project: `~/projects/launcher/start-newproject.sh test-app`
4. Verify MCPs and knowledge base are accessible
5. Start building!
