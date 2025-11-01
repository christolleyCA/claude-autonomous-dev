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
