#!/bin/bash
# ============================================================================
# Workspace Organization Script
# Organizes autonomous development system into a clean folder structure
# ============================================================================

set -e  # Exit on error

HOME_DIR="/Users/christophertolleymacbook2019"
PROJECT_DIR="${HOME_DIR}/autonomous-dev"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗂️  ORGANIZING AUTONOMOUS DEVELOPMENT WORKSPACE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================================================
# STEP 1: Create Directory Structure
# ============================================================================
echo "1️⃣  Creating organized directory structure..."
mkdir -p "${PROJECT_DIR}/bin/startup"
mkdir -p "${PROJECT_DIR}/bin/features"
mkdir -p "${PROJECT_DIR}/bin/git"
mkdir -p "${PROJECT_DIR}/bin/database"
mkdir -p "${PROJECT_DIR}/bin/automation"
mkdir -p "${PROJECT_DIR}/lib"
mkdir -p "${PROJECT_DIR}/docs"
mkdir -p "${PROJECT_DIR}/data/nonprofit"
mkdir -p "${PROJECT_DIR}/config"

echo "   ✅ Directory structure created"
echo ""

# ============================================================================
# STEP 2: Move Files to Organized Locations
# ============================================================================
echo "2️⃣  Moving files to organized locations..."

cd "$HOME_DIR"

# --- STARTUP SCRIPTS ---
echo "   📦 Moving startup scripts..."
mv -f start-everything.sh "${PROJECT_DIR}/bin/startup/" 2>/dev/null || true
mv -f start-with-watchdog.sh "${PROJECT_DIR}/bin/startup/" 2>/dev/null || true
mv -f start-remote-access.sh "${PROJECT_DIR}/bin/startup/" 2>/dev/null || true
mv -f start-all-services.sh "${PROJECT_DIR}/bin/startup/" 2>/dev/null || true
mv -f stop-everything.sh "${PROJECT_DIR}/bin/startup/" 2>/dev/null || true
mv -f watchdog.sh "${PROJECT_DIR}/bin/startup/" 2>/dev/null || true

# --- FEATURE BUILDING SCRIPTS ---
echo "   📦 Moving feature building scripts..."
mv -f build-feature.sh "${PROJECT_DIR}/bin/features/" 2>/dev/null || true
mv -f build-feature-old.sh "${PROJECT_DIR}/bin/features/" 2>/dev/null || true
mv -f fix-feature.sh "${PROJECT_DIR}/bin/features/" 2>/dev/null || true
mv -f list-features.sh "${PROJECT_DIR}/bin/features/" 2>/dev/null || true
mv -f smart-fix.sh "${PROJECT_DIR}/bin/features/" 2>/dev/null || true
mv -f autonomous-builder.sh "${PROJECT_DIR}/bin/features/" 2>/dev/null || true

# --- GIT AUTOMATION SCRIPTS ---
echo "   📦 Moving git automation scripts..."
mv -f smart-git-commit.sh "${PROJECT_DIR}/bin/git/" 2>/dev/null || true
mv -f git-helpers.sh "${PROJECT_DIR}/bin/git/" 2>/dev/null || true
mv -f restore-context.sh "${PROJECT_DIR}/bin/git/" 2>/dev/null || true

# --- AUTOMATION SCRIPTS ---
echo "   📦 Moving automation scripts..."
mv -f autonomous-responder.sh "${PROJECT_DIR}/bin/automation/" 2>/dev/null || true
mv -f claude-conversation-service.sh "${PROJECT_DIR}/bin/automation/" 2>/dev/null || true
mv -f claude-ping.sh "${PROJECT_DIR}/bin/automation/" 2>/dev/null || true
mv -f check-slack-messages.sh "${PROJECT_DIR}/bin/automation/" 2>/dev/null || true
mv -f setup-autonomous.sh "${PROJECT_DIR}/bin/automation/" 2>/dev/null || true
mv -f mirror-message.sh "${PROJECT_DIR}/bin/automation/" 2>/dev/null || true
mv -f log-to-slack.sh "${PROJECT_DIR}/bin/automation/" 2>/dev/null || true

# --- DATABASE/NONPROFIT SCRIPTS ---
echo "   📦 Moving database/nonprofit scripts..."
mv -f *nonprofit*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f *nonprofit*.sh "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f load-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f import-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f export-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f apply-*.sh "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f apply-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f fix-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f *-fix-*.sh "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f generate-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f update-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f check-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f check-*.sh "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f scrape-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f process-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f download-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f parse-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f classify-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f spot-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f split-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f split-*.sh "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f convert-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f create-*.sh "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f combine-*.sh "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f run-*.sh "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f batch-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true
mv -f auto-*.py "${PROJECT_DIR}/bin/database/" 2>/dev/null || true

# --- LIBRARY/HELPER SCRIPTS (sourced by others) ---
echo "   📦 Moving library scripts..."
mv -f claude-poll-commands.sh "${PROJECT_DIR}/lib/" 2>/dev/null || true
mv -f claude-write-response.sh "${PROJECT_DIR}/lib/" 2>/dev/null || true
mv -f claude-respond.sh "${PROJECT_DIR}/lib/" 2>/dev/null || true
mv -f slack-logger.sh "${PROJECT_DIR}/lib/" 2>/dev/null || true
mv -f solution-logger.sh "${PROJECT_DIR}/lib/" 2>/dev/null || true
mv -f solution-searcher.sh "${PROJECT_DIR}/lib/" 2>/dev/null || true
mv -f view-solutions.sh "${PROJECT_DIR}/lib/" 2>/dev/null || true

# --- REMAINING SCRIPTS ---
echo "   📦 Moving remaining automation scripts..."
mv -f *.sh "${PROJECT_DIR}/bin/automation/" 2>/dev/null || true

# --- DOCUMENTATION ---
echo "   📦 Moving documentation..."
mv -f *.md "${PROJECT_DIR}/docs/" 2>/dev/null || true
mv -f *.txt "${PROJECT_DIR}/docs/" 2>/dev/null || true

# --- DATA FILES ---
echo "   📦 Moving data files..."
mv -f nonprofit_*.sql "${PROJECT_DIR}/data/nonprofit/" 2>/dev/null || true
mv -f *nonprofit*.csv "${PROJECT_DIR}/data/nonprofit/" 2>/dev/null || true
mv -f irs_bmf_ein_to_name.json "${PROJECT_DIR}/data/nonprofit/" 2>/dev/null || true
mv -f *.sql "${PROJECT_DIR}/data/nonprofit/" 2>/dev/null || true

# --- DATA DIRECTORIES ---
echo "   📦 Moving data directories..."
mv -f nonprofit_name_fixes "${PROJECT_DIR}/data/nonprofit/" 2>/dev/null || true
mv -f nonprofit_address_fixes "${PROJECT_DIR}/data/nonprofit/" 2>/dev/null || true
mv -f nonprofit_sql_inserts "${PROJECT_DIR}/data/nonprofit/" 2>/dev/null || true
mv -f nonprofit_classification_updates "${PROJECT_DIR}/data/nonprofit/" 2>/dev/null || true
mv -f nonprofit_website_updates "${PROJECT_DIR}/data/nonprofit/" 2>/dev/null || true
mv -f 990_nonprofit_data "${PROJECT_DIR}/data/nonprofit/" 2>/dev/null || true
mv -f irs_bmf_data "${PROJECT_DIR}/data/nonprofit/" 2>/dev/null || true

echo "   ✅ Files moved"
echo ""

# ============================================================================
# STEP 3: Create Symlinks for Backward Compatibility
# ============================================================================
echo "3️⃣  Creating symlinks for backward compatibility..."

# Key startup scripts that may be called directly
ln -sf "${PROJECT_DIR}/bin/startup/start-everything.sh" "${HOME_DIR}/start-everything.sh"
ln -sf "${PROJECT_DIR}/bin/startup/stop-everything.sh" "${HOME_DIR}/stop-everything.sh"
ln -sf "${PROJECT_DIR}/bin/git/smart-git-commit.sh" "${HOME_DIR}/smart-git-commit.sh"
ln -sf "${PROJECT_DIR}/bin/git/restore-context.sh" "${HOME_DIR}/restore-context.sh"
ln -sf "${PROJECT_DIR}/lib/view-solutions.sh" "${HOME_DIR}/view-solutions.sh"
ln -sf "${PROJECT_DIR}/docs/GETTING-STARTED.md" "${HOME_DIR}/GETTING-STARTED.md"

echo "   ✅ Symlinks created"
echo ""

# ============================================================================
# STEP 4: Update Path References in Scripts
# ============================================================================
echo "4️⃣  Updating path references in scripts..."

# Update SCRIPT_DIR in start-with-watchdog.sh
if [ -f "${PROJECT_DIR}/bin/startup/start-with-watchdog.sh" ]; then
    sed -i.bak 's|SCRIPT_DIR="/Users/christophertolleymacbook2019"|SCRIPT_DIR="/Users/christophertolleymacbook2019/autonomous-dev"|g' \
        "${PROJECT_DIR}/bin/startup/start-with-watchdog.sh"
    echo "   ✅ Updated start-with-watchdog.sh"
fi

# Update source paths in start-remote-access.sh
if [ -f "${PROJECT_DIR}/bin/startup/start-remote-access.sh" ]; then
    sed -i.bak 's|source "${SCRIPT_DIR}/claude-poll-commands.sh"|source "${SCRIPT_DIR}/lib/claude-poll-commands.sh"|g' \
        "${PROJECT_DIR}/bin/startup/start-remote-access.sh"
    sed -i.bak 's|source "${SCRIPT_DIR}/claude-write-response.sh"|source "${SCRIPT_DIR}/lib/claude-write-response.sh"|g' \
        "${PROJECT_DIR}/bin/startup/start-remote-access.sh"
    sed -i.bak 's|"${SCRIPT_DIR}/build-feature.sh"|"${SCRIPT_DIR}/bin/features/build-feature.sh"|g' \
        "${PROJECT_DIR}/bin/startup/start-remote-access.sh"
    sed -i.bak 's|"${SCRIPT_DIR}/smart-git-commit.sh"|"${SCRIPT_DIR}/bin/git/smart-git-commit.sh"|g' \
        "${PROJECT_DIR}/bin/startup/start-remote-access.sh"
    sed -i.bak 's|"${SCRIPT_DIR}/restore-context.sh"|"${SCRIPT_DIR}/bin/git/restore-context.sh"|g' \
        "${PROJECT_DIR}/bin/startup/start-remote-access.sh"
    echo "   ✅ Updated start-remote-access.sh"
fi

# Update relative paths in start-everything.sh
if [ -f "${PROJECT_DIR}/bin/startup/start-everything.sh" ]; then
    sed -i.bak 's|./start-with-watchdog.sh|'"${PROJECT_DIR}"'/bin/startup/start-with-watchdog.sh|g' \
        "${PROJECT_DIR}/bin/startup/start-everything.sh"
    echo "   ✅ Updated start-everything.sh"
fi

echo "   ✅ Path references updated"
echo ""

# ============================================================================
# STEP 5: Create .gitignore for the project
# ============================================================================
echo "5️⃣  Creating .gitignore..."

cat > "${PROJECT_DIR}/.gitignore" << 'GITIGNORE_EOF'
# System files
.DS_Store
.Trash
.localized
*.bak

# IDE
.vscode/
.idea/

# Logs
*.log
/tmp/

# Sensitive data
.env
*.key
*.pem

# Large data files (keep structure, not content)
data/**/*.csv
data/**/*.json
data/**/*.sql

# Build artifacts
*.pyc
__pycache__/

# Node modules (if any)
node_modules/
GITIGNORE_EOF

echo "   ✅ .gitignore created"
echo ""

# ============================================================================
# STEP 6: Create README in project directory
# ============================================================================
echo "6️⃣  Creating project README..."

cat > "${PROJECT_DIR}/README.md" << 'README_EOF'
# Autonomous Development System

Organized workspace for autonomous development with Claude Code.

## Directory Structure

```
autonomous-dev/
├── bin/
│   ├── startup/         # System startup and service scripts
│   ├── features/        # Feature building and management
│   ├── git/            # Git automation and version control
│   ├── database/       # Database and nonprofit data scripts
│   └── automation/     # General automation scripts
├── lib/                # Shared libraries and helper scripts
├── docs/               # All documentation
├── data/
│   └── nonprofit/      # Nonprofit organization data
└── config/             # Configuration files
```

## Quick Start

From your home directory:
```bash
./start-everything.sh
```

Or from the project directory:
```bash
cd ~/autonomous-dev
./bin/startup/start-everything.sh
```

## Documentation

See `docs/GETTING-STARTED.md` for complete setup and usage instructions.

## Symlinks

Key scripts have symlinks in your home directory for convenience:
- `~/start-everything.sh` → `autonomous-dev/bin/startup/start-everything.sh`
- `~/stop-everything.sh` → `autonomous-dev/bin/startup/stop-everything.sh`
- `~/smart-git-commit.sh` → `autonomous-dev/bin/git/smart-git-commit.sh`
- `~/GETTING-STARTED.md` → `autonomous-dev/docs/GETTING-STARTED.md`
README_EOF

echo "   ✅ README created"
echo ""

# ============================================================================
# Done!
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ WORKSPACE ORGANIZATION COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Project Location:"
echo "   ${PROJECT_DIR}"
echo ""
echo "🔗 Symlinks in home directory for convenience:"
echo "   ~/start-everything.sh"
echo "   ~/stop-everything.sh"
echo "   ~/smart-git-commit.sh"
echo "   ~/GETTING-STARTED.md"
echo ""
echo "📊 Directory Structure:"
echo "   autonomous-dev/"
echo "   ├── bin/          # All executable scripts"
echo "   ├── lib/          # Helper libraries"
echo "   ├── docs/         # Documentation"
echo "   ├── data/         # Data files"
echo "   └── config/       # Configuration"
echo ""
echo "🚀 Your startup routine still works:"
echo "   cd ~"
echo "   ./start-everything.sh"
echo ""
echo "📖 Documentation updated at:"
echo "   ~/autonomous-dev/docs/GETTING-STARTED.md"
echo ""
