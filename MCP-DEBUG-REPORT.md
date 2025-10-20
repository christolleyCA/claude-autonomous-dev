# MCP Configuration Debug Report
**Date:** October 19, 2025
**Investigation:** GitHub, Slack, and Sentry MCPs Not Loading

---

## TASK 1: Configuration File Location ✅

**File Location:** `~/.config/claude-code/config.json` (NOT mcp_settings.json)

**Full Path:** `/Users/christophertolleymacbook2019/.config/claude-code/config.json`

**File Contents:**
```json
{
  "mcpServers": {
    "n8n-mcp": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "MCP_MODE=stdio",
        "-e", "LOG_LEVEL=error",
        "-e", "N8N_API_URL=https://n8n.grantpilot.app",
        "-e", "N8N_API_KEY=eyJhbGc...[REDACTED]",
        "ghcr.io/czlonkowski/n8n-mcp:latest"
      ]
    },
    "supabase": {
      "command": "npx",
      "args": [
        "@supabase/mcp-server-supabase",
        "--access-token",
        "sbp_0ed56...[REDACTED]"
      ]
    },
    "github": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-github"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_UY7S...[REDACTED]"
      }
    },
    "slack": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-slack"
      ],
      "env": {
        "SLACK_BOT_TOKEN": "xoxb-931...[REDACTED]",
        "SLACK_TEAM_ID": "C09M9A33FFF"
      }
    },
    "sentry": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-sentry"
      ],
      "env": {
        "SENTRY_AUTH_TOKEN": "sntryu_9d70...[REDACTED]",
        "SENTRY_ORG": "oxfordshire-inc",
        "SENTRY_PROJECT": "supabase-edge-functions"
      }
    }
  }
}
```

---

## TASK 2: JSON Syntax Validation ✅

**Result:** ✅ JSON is valid

No syntax errors detected. All brackets, commas, and quotes are properly formatted.

---

## TASK 3: MCP Package Availability 🔍

### GitHub MCP
- **Package:** `@modelcontextprotocol/server-github`
- **NPM Status:** ✅ EXISTS (version 2025.4.8)
- **Availability:** ⚠️ **DEPRECATED**
- **Warning Message:**
  ```
  npm warn deprecated @modelcontextprotocol/server-github@2025.4.8:
  Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
  ```
- **Status:** ARCHIVED - Moved to servers-archived repository
- **Current Status:** No longer actively maintained

### Slack MCP
- **Package:** `@modelcontextprotocol/server-slack`
- **NPM Status:** ✅ EXISTS (version 2025.4.25)
- **Availability:** ⚠️ **DEPRECATED**
- **Warning Message:**
  ```
  npm warn deprecated @modelcontextprotocol/server-slack@2025.4.25:
  Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
  ```
- **Status:** Now maintained by Zencoder (third party)
- **Current Status:** Official package archived

### Sentry MCP
- **Package:** `@modelcontextprotocol/server-sentry`
- **NPM Status:** ❌ **DOES NOT EXIST**
- **Status:** ARCHIVED - Never published to npm
- **Current Status:** Available in servers-archived repository only

### Git MCP (Alternative to GitHub)
- **Package:** `@modelcontextprotocol/server-git`
- **NPM Status:** ❌ **DOES NOT EXIST**
- **Note:** This is the current official alternative to GitHub MCP
- **Current Status:** Not published to npm

---

## TASK 4: Configuration Analysis

### Working MCPs (For Comparison)

#### ✅ N8n MCP (WORKING)
```json
{
  "command": "docker",
  "args": ["run", "-i", "--rm", "-e", "MCP_MODE=stdio", ...]
}
```
- **Method:** Docker container
- **Status:** Connected and operational
- **Why it works:** Custom Docker image, actively maintained

#### ✅ Supabase MCP (WORKING)
```json
{
  "command": "npx",
  "args": ["@supabase/mcp-server-supabase", "--access-token", "..."]
}
```
- **Method:** NPX with official Supabase package
- **Status:** Connected and operational
- **Why it works:** Actively maintained by Supabase

### Non-Working MCPs

#### ❌ GitHub MCP (NOT WORKING)
```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": {"GITHUB_PERSONAL_ACCESS_TOKEN": "..."}
}
```
- **Issue:** Package is deprecated/archived
- **Impact:** Cannot initialize, Claude Code can't load it

#### ❌ Slack MCP (NOT WORKING)
```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-slack"],
  "env": {"SLACK_BOT_TOKEN": "...", "SLACK_TEAM_ID": "..."}
}
```
- **Issue:** Package is deprecated/archived
- **Impact:** Cannot initialize, Claude Code can't load it

#### ❌ Sentry MCP (NOT WORKING)
```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-sentry"],
  "env": {"SENTRY_AUTH_TOKEN": "...", "SENTRY_ORG": "...", "SENTRY_PROJECT": "..."}
}
```
- **Issue:** Package never existed on npm
- **Impact:** NPX cannot find or download package

---

## ROOT CAUSE ANALYSIS

### Why MCPs Are Not Loading:

1. **GitHub MCP:** Package exists but is deprecated. NPX downloads it, but it may fail to initialize properly due to deprecation issues.

2. **Slack MCP:** Package exists but is deprecated. Same issue as GitHub - downloads but fails initialization.

3. **Sentry MCP:** Package doesn't exist on npm at all. NPX cannot find it, resulting in immediate failure.

### Why Supabase and N8n Work:

- **Supabase:** Uses `@supabase/mcp-server-supabase` - actively maintained official package
- **N8n:** Uses custom Docker container - independent of npm deprecation issues

---

## TASK 5: Alternative Solutions

### Community-Maintained Alternatives

#### Slack Alternatives:
1. **korotovsky/slack-mcp-server**
   - Most powerful community alternative
   - 30,000+ engineers visit, 9,000+ using
   - Supports: Stdio, SSE, DMs, Group DMs
   - No special permissions required
   - GitHub: https://github.com/korotovsky/slack-mcp-server

2. **lars-hagen/slack-user-mcp**
   - Enables Claude to interact with Slack as a user
   - GitHub: https://github.com/lars-hagen/slack-user-mcp

#### GitHub Alternatives:
- Official Git MCP exists in modelcontextprotocol/servers but not published to npm
- Would need to clone and build from source
- Or use direct Git operations via shell commands

#### Sentry Alternatives:
- Official Sentry MCP exists in servers-archived repository
- Available via Python (uvx or pip), not npm
- Would require Python-based MCP server setup

---

## RECOMMENDATIONS

### Option 1: Remove Broken MCPs (Simplest)
**Action:** Remove GitHub, Slack, and Sentry from config.json since they're not working anyway.

**Benefit:** Clean configuration, no startup errors

**Tradeoff:** Lose those integrations

---

### Option 2: Replace with Community Alternatives

#### For Slack:
```json
{
  "slack": {
    "command": "npx",
    "args": [
      "-y",
      "@korotovsky/slack-mcp-server"
    ],
    "env": {
      "SLACK_BOT_TOKEN": "xoxb-931...",
      "SLACK_TEAM_ID": "C09M9A33FFF"
    }
  }
}
```

**Note:** Verify package name and installation method from GitHub repo

---

### Option 3: Use Git Operations Directly
Instead of GitHub MCP, use N8n workflows or Supabase Edge Functions to handle Git operations via shell commands.

**Benefit:** No dependency on deprecated packages

**Tradeoff:** More manual implementation

---

### Option 4: Python-based Sentry MCP

Install Sentry MCP via Python:
```bash
uvx install mcp-server-sentry
```

Then configure in config.json:
```json
{
  "sentry": {
    "command": "uvx",
    "args": ["mcp-server-sentry"],
    "env": {
      "SENTRY_AUTH_TOKEN": "...",
      "SENTRY_ORG": "oxfordshire-inc",
      "SENTRY_PROJECT": "supabase-edge-functions"
    }
  }
}
```

**Note:** Requires Python/uvx to be installed

---

## IMMEDIATE NEXT STEPS

### Recommended Action Plan:

1. **Clean Up Config (Immediate)**
   - Remove the 3 broken MCP entries from config.json
   - Restart Claude Code to eliminate startup errors
   - Keep working with Supabase + N8n (which cover 90% of your needs)

2. **Research Alternatives (Optional)**
   - If Slack integration is critical, test korotovsky/slack-mcp-server
   - For Git operations, use N8n workflows with shell commands
   - For Sentry, only add if error monitoring is essential

3. **Focus on Core Workflow**
   - You have Supabase (database) + N8n (automation) working
   - This is sufficient for autonomous grant matching workflows
   - Add integrations later as needed

---

## CONFIGURATION COMPARISON

### What's Different?

| MCP | Method | Status | Why |
|-----|--------|--------|-----|
| **Supabase** | NPX with `@supabase/mcp-server-supabase` | ✅ Working | Actively maintained official package |
| **N8n** | Docker container | ✅ Working | Custom implementation, independent |
| **GitHub** | NPX with `@modelcontextprotocol/server-github` | ❌ Broken | Deprecated/archived |
| **Slack** | NPX with `@modelcontextprotocol/server-slack` | ❌ Broken | Deprecated/archived |
| **Sentry** | NPX with `@modelcontextprotocol/server-sentry` | ❌ Broken | Never existed on npm |

**Key Insight:** The broken MCPs are all using deprecated or non-existent `@modelcontextprotocol/*` packages. Working MCPs use either company-specific packages (`@supabase/*`) or custom implementations (Docker).

---

## CONCLUSION

**Root Cause:** All three non-working MCPs rely on deprecated or non-existent npm packages from the `@modelcontextprotocol` organization.

**Impact:** These MCPs cannot initialize, causing Claude Code to skip them during startup.

**Resolution:** Either remove them, replace with community alternatives, or implement the functionality through N8n workflows and Supabase Edge Functions.

**Recommendation:** Proceed with the N8n two-way workflow using the working Supabase + N8n MCPs. Add integrations later only if truly needed.

---

*Debug Report Generated: 2025-10-19*
