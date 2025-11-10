#!/bin/bash
# ============================================================================
# Multi-Project Setup Script
# ============================================================================
# This script sets up the shared infrastructure for working on multiple
# projects while maintaining access to knowledge base, MCPs, and tools.
#
# Run this once to set up the system:
#   ./bin/setup-multi-project.sh
#
# After setup, create new projects with:
#   ~/projects/launcher/new-project my-awesome-app
# ============================================================================

set -e  # Exit on error

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Multi-Project Development System Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
AUTONOMOUS_DEV="$(dirname "$SCRIPT_DIR")"

echo "📁 Autonomous Dev Directory: $AUTONOMOUS_DEV"
echo ""

# ============================================================================
# Step 1: Create Shared Infrastructure
# ============================================================================

echo "Step 1/6: Creating shared infrastructure..."

SHARED_DIR="$HOME/claude-shared"

if [ -d "$SHARED_DIR" ]; then
    echo "⚠️  Shared directory already exists: $SHARED_DIR"
    read -p "Do you want to continue? This will update existing files. (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Setup cancelled"
        exit 1
    fi
fi

# Create directory structure
mkdir -p "$SHARED_DIR"/{mcp-config,knowledge-base/{solutions,docs},autonomous-tools,edge-functions}

echo "✅ Created shared directory structure:"
echo "   $SHARED_DIR/mcp-config/"
echo "   $SHARED_DIR/knowledge-base/"
echo "   $SHARED_DIR/autonomous-tools/"
echo "   $SHARED_DIR/edge-functions/"
echo ""

# ============================================================================
# Step 2: Copy Autonomous Tools
# ============================================================================

echo "Step 2/6: Copying autonomous tools to shared location..."

# Copy solution searcher
if [ -f "$AUTONOMOUS_DEV/lib/solution-searcher.sh" ]; then
    cp "$AUTONOMOUS_DEV/lib/solution-searcher.sh" "$SHARED_DIR/autonomous-tools/"
    chmod +x "$SHARED_DIR/autonomous-tools/solution-searcher.sh"
    echo "✅ Copied solution-searcher.sh"
else
    echo "⚠️  solution-searcher.sh not found in $AUTONOMOUS_DEV/lib/"
fi

# Copy parallel processing scripts
if [ -f "/tmp/process-all-tavily-parallel.sh" ]; then
    cp "/tmp/process-all-tavily-parallel.sh" "$SHARED_DIR/autonomous-tools/"
    chmod +x "$SHARED_DIR/autonomous-tools/process-all-tavily-parallel.sh"
    echo "✅ Copied process-all-tavily-parallel.sh"
fi

if [ -f "/tmp/classify-parallel.py" ]; then
    cp "/tmp/classify-parallel.py" "$SHARED_DIR/autonomous-tools/"
    chmod +x "$SHARED_DIR/autonomous-tools/classify-parallel.py"
    echo "✅ Copied classify-parallel.py"
fi

echo ""

# ============================================================================
# Step 3: Set Up MCP Configuration Sharing
# ============================================================================

echo "Step 3/6: Setting up MCP configuration sharing..."

MCP_CONFIG="$HOME/.config/claude/mcp.json"
SHARED_MCP="$SHARED_DIR/mcp-config/mcp.json"

if [ -f "$MCP_CONFIG" ] && [ ! -L "$MCP_CONFIG" ]; then
    # MCP config exists and is not a symlink - copy it to shared location
    cp "$MCP_CONFIG" "$SHARED_MCP"
    echo "✅ Copied MCP configuration to shared location"

    # Backup original
    mv "$MCP_CONFIG" "$MCP_CONFIG.backup-$(date +%s)"
    echo "✅ Backed up original MCP config"

    # Create symlink
    ln -s "$SHARED_MCP" "$MCP_CONFIG"
    echo "✅ Created symlink: $MCP_CONFIG -> $SHARED_MCP"
elif [ -L "$MCP_CONFIG" ]; then
    echo "✅ MCP config is already a symlink"
else
    echo "⚠️  No MCP config found at $MCP_CONFIG"
    echo "   Will be created when you first run Claude Code"
fi

echo ""

# ============================================================================
# Step 4: Create Project Launcher Directory
# ============================================================================

echo "Step 4/6: Creating project launcher directory..."

LAUNCHER_DIR="$HOME/projects/launcher"
mkdir -p "$LAUNCHER_DIR"

echo "✅ Created launcher directory: $LAUNCHER_DIR"
echo ""

# ============================================================================
# Step 5: Create Launcher Scripts
# ============================================================================

echo "Step 5/6: Creating launcher scripts..."

# ----------------------------------------------------------------------------
# GrantPilot Launcher
# ----------------------------------------------------------------------------

cat > "$LAUNCHER_DIR/grantpilot" << 'EOF'
#!/bin/bash
export CLAUDE_PROJECT="grantpilot"
export CLAUDE_WORKING_DIR="$HOME/autonomous-dev"
export CLAUDE_SHARED="$HOME/claude-shared"

cd "$CLAUDE_WORKING_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting GrantPilot Project"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 Working Directory: $CLAUDE_WORKING_DIR"
echo "🔧 Shared Resources:  $CLAUDE_SHARED"
echo "🤖 Knowledge Base:    $CLAUDE_SHARED/knowledge-base"
echo "⚡ Autonomous Tools:  $CLAUDE_SHARED/autonomous-tools"
echo "🔌 MCPs: Supabase, Sentry, N8N, Docs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

claude
EOF

chmod +x "$LAUNCHER_DIR/grantpilot"
echo "✅ Created GrantPilot launcher: $LAUNCHER_DIR/grantpilot"

# ----------------------------------------------------------------------------
# New Project Creator
# ----------------------------------------------------------------------------

cat > "$LAUNCHER_DIR/new-project" << 'EOFMAIN'
#!/bin/bash
# ============================================================================
# New Project Creator
# ============================================================================
# Creates a new project with access to shared infrastructure
#
# Usage:
#   new-project my-awesome-app
#   new-project ecommerce-site
# ============================================================================

PROJECT_NAME=$1

if [ -z "$PROJECT_NAME" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 New Project Creator"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Usage: new-project <project-name>"
  echo ""
  echo "Examples:"
  echo "  new-project my-saas-app"
  echo "  new-project ecommerce-platform"
  echo "  new-project data-analytics-tool"
  echo ""
  echo "This will create:"
  echo "  • ~/projects/<project-name>/ directory"
  echo "  • Basic project structure (src, docs, tests, config)"
  echo "  • Symlink to shared MCP configuration"
  echo "  • README with shared resources info"
  echo "  • Launcher script at ~/projects/launcher/<project-name>"
  echo ""
  exit 1
fi

# Validate project name (alphanumeric, hyphens, underscores only)
if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "❌ Invalid project name: $PROJECT_NAME"
    echo "   Use only letters, numbers, hyphens, and underscores"
    exit 1
fi

export CLAUDE_PROJECT="$PROJECT_NAME"
export CLAUDE_WORKING_DIR="$HOME/projects/$PROJECT_NAME"
export CLAUDE_SHARED="$HOME/claude-shared"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Creating New Project: $PROJECT_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if project already exists
if [ -d "$CLAUDE_WORKING_DIR" ]; then
    echo "⚠️  Project directory already exists: $CLAUDE_WORKING_DIR"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Project creation cancelled"
        exit 1
    fi
fi

# Create project directory
mkdir -p "$CLAUDE_WORKING_DIR"
cd "$CLAUDE_WORKING_DIR"

echo "✅ Created project directory: $CLAUDE_WORKING_DIR"

# Create basic structure
mkdir -p {src,docs,tests,config,.claude}

echo "✅ Created project structure:"
echo "   src/     - Source code"
echo "   docs/    - Documentation"
echo "   tests/   - Tests"
echo "   config/  - Configuration"
echo ""

# Create symlink to shared MCP config
if [ -f "$CLAUDE_SHARED/mcp-config/mcp.json" ]; then
    if [ ! -f ".claude/mcp.json" ]; then
        ln -s "$CLAUDE_SHARED/mcp-config/mcp.json" ".claude/mcp.json"
        echo "✅ Linked shared MCP configuration"
    else
        echo "⚠️  MCP config already exists, skipping"
    fi
fi

# Create README
if [ ! -f "README.md" ]; then
  cat > README.md << EOFREADME
# $PROJECT_NAME

Created with Claude Code multi-project setup on $(date +"%Y-%m-%d").

## Quick Start

\`\`\`bash
# Start working on this project
~/projects/launcher/$PROJECT_NAME
\`\`\`

## Shared Resources

This project has access to:

- **📚 Knowledge Base**: \`~/claude-shared/knowledge-base\`
  - All solutions from previous projects
  - Searchable with: \`~/claude-shared/autonomous-tools/solution-searcher.sh\`

- **⚡ Autonomous Tools**: \`~/claude-shared/autonomous-tools\`
  - \`process-all-tavily-parallel.sh\` - Website discovery
  - \`classify-parallel.py\` - LLM classification
  - \`solution-searcher.sh\` - Knowledge base search

- **🔌 MCP Servers**:
  - Supabase (database + Edge Functions)
  - Sentry (error tracking)
  - N8N (workflow automation)
  - Docs (documentation search)

- **🚀 Edge Functions**: \`~/claude-shared/edge-functions\`
  - Reusable templates for common tasks
  - See catalog: \`~/autonomous-dev/docs/supabase-edge-functions/EDGE-FUNCTIONS-CATALOG.md\`

## Documentation

For setup and usage guides, see:
- Multi-Project Guide: \`~/autonomous-dev/docs/MULTI-PROJECT-QUICKSTART.md\`
- Orchestration Strategy: \`~/autonomous-dev/docs/ORCHESTRATION-STRATEGY.md\`

## Development

\`\`\`bash
# Your code goes in src/
# Documentation in docs/
# Tests in tests/
# Configuration in config/
\`\`\`

All standard development tools and MCPs are available automatically!
EOFREADME

  echo "✅ Created README.md with shared resources info"
fi

# Create .gitignore
if [ ! -f ".gitignore" ]; then
  cat > .gitignore << 'EOFGITIGNORE'
# Environment
.env
.env.local
.env.*.local

# Dependencies
node_modules/
__pycache__/
*.pyc
.pytest_cache/
venv/
env/

# Build outputs
dist/
build/
*.egg-info/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
EOFGITIGNORE

  echo "✅ Created .gitignore"
fi

# Create project-specific launcher
LAUNCHER_SCRIPT="$HOME/projects/launcher/$PROJECT_NAME"

cat > "$LAUNCHER_SCRIPT" << EOFLAUNCHER
#!/bin/bash
export CLAUDE_PROJECT="$PROJECT_NAME"
export CLAUDE_WORKING_DIR="$HOME/projects/$PROJECT_NAME"
export CLAUDE_SHARED="$HOME/claude-shared"

cd "\$CLAUDE_WORKING_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting $PROJECT_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 Working Directory: \$CLAUDE_WORKING_DIR"
echo "🔧 Shared Resources:  \$CLAUDE_SHARED"
echo "🤖 Knowledge Base:    \$CLAUDE_SHARED/knowledge-base"
echo "⚡ Autonomous Tools:  \$CLAUDE_SHARED/autonomous-tools"
echo "🔌 MCPs: Supabase, Sentry, N8N, Docs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

claude
EOFLAUNCHER

chmod +x "$LAUNCHER_SCRIPT"

echo "✅ Created launcher script: $LAUNCHER_SCRIPT"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Project Created Successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Project Location: $CLAUDE_WORKING_DIR"
echo ""
echo "To start working:"
echo "  ~/projects/launcher/$PROJECT_NAME"
echo ""
echo "Or use the shortcut:"
echo "  $LAUNCHER_SCRIPT"
echo ""
echo "Available shared resources:"
echo "  • Knowledge base with all solutions"
echo "  • Autonomous tools (website discovery, classification, etc.)"
echo "  • MCP servers (Supabase, Sentry, N8N, Docs)"
echo "  • Edge Function templates"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
EOFMAIN

chmod +x "$LAUNCHER_DIR/new-project"
echo "✅ Created new-project creator: $LAUNCHER_DIR/new-project"
echo ""

# ============================================================================
# Step 6: Add to PATH (Optional)
# ============================================================================

echo "Step 6/6: Finalizing setup..."

# Create a convenient alias file
ALIAS_FILE="$SHARED_DIR/shortcuts.sh"

cat > "$ALIAS_FILE" << 'EOF'
# Claude Code Multi-Project Shortcuts
# Source this in your ~/.bashrc or ~/.zshrc:
#   source ~/claude-shared/shortcuts.sh

# Project launchers
alias grantpilot="~/projects/launcher/grantpilot"
alias new-project="~/projects/launcher/new-project"

# Shared tools
alias search-solutions="~/claude-shared/autonomous-tools/solution-searcher.sh"
alias list-projects="ls -la ~/projects/"

echo "Claude Code shortcuts loaded!"
EOF

echo "✅ Created shortcuts file: $ALIAS_FILE"
echo ""

# ============================================================================
# Setup Complete!
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Multi-Project System Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 Quick Reference:"
echo ""
echo "  Work on GrantPilot:"
echo "    ~/projects/launcher/grantpilot"
echo ""
echo "  Create new project:"
echo "    ~/projects/launcher/new-project my-awesome-app"
echo ""
echo "  Search knowledge base:"
echo "    ~/claude-shared/autonomous-tools/solution-searcher.sh 'query'"
echo ""
echo "  List autonomous tools:"
echo "    ls ~/claude-shared/autonomous-tools/"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Optional: Add shortcuts to your shell"
echo "  echo 'source ~/claude-shared/shortcuts.sh' >> ~/.bashrc"
echo "  echo 'source ~/claude-shared/shortcuts.sh' >> ~/.zshrc"
echo ""
echo "Then you can use:"
echo "  grantpilot           # Start GrantPilot"
echo "  new-project my-app   # Create new project"
echo "  search-solutions     # Search knowledge base"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
