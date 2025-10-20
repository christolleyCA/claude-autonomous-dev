# Feature Registry - Track All Your Features

## What Is It?

A persistent registry that tracks every feature built by `build-feature.sh`. You can query it later to remember:
- What features you've built
- When they were built
- Where the code is located
- What they do

## Quick Start

```bash
# See all features you've built
./list-features.sh

# See everything (registry + Supabase + N8n discovery)
./list-features.sh --all

# Search for a feature
./list-features.sh --search email
./list-features.sh --search "grant"

# Get details on a specific feature
./list-features.sh --details hello-world-test

# Quick discovery of what's deployed
./list-features.sh --edge-functions
./list-features.sh --workflows
```

## How It Works

### Automatic Registration

Every time you run `build-feature.sh`, it automatically registers the feature:

```bash
# Build a feature
./build-feature.sh my-feature "Description here"

# Automatically registered!
# No extra steps needed
```

The registry file is stored at:
```
~/.feature-registry.json
```

### What Gets Saved

For each feature:
```json
{
  "name": "hello-world-test",
  "description": "Multilingual greeting function with validation",
  "build_dir": "/tmp/autonomous-builds/hello-world-test-1760978777",
  "timestamp": "03:45 PM",
  "status": "deployed"
}
```

## Using list-features.sh

### 1. Show Registry (Default)

```bash
./list-features.sh
```

Output:
```
📋 Feature Registry (3 features)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: email-sender
  Description: Send emails via SendGrid with validation
  Built: 02:15 PM
  Status: deployed
  Build Dir: /tmp/autonomous-builds/email-sender-1760930497
  Edge Function: https://hjtvtkffpziopozmtsnb.supabase.co/functions/v1/email-sender

Feature: hello-world-test
  Description: Multilingual greeting function with validation
  Built: 03:45 PM
  Status: deployed
  Build Dir: /tmp/autonomous-builds/hello-world-test-1760978777
  Edge Function: https://hjtvtkffpziopozmtsnb.supabase.co/functions/v1/hello-world-test

Feature: payment-processor
  Description: Process Stripe payments with webhooks
  Built: 04:30 PM
  Status: deployed
  Build Dir: /tmp/autonomous-builds/payment-processor-1760985000
  Edge Function: https://hjtvtkffpziopozmtsnb.supabase.co/functions/v1/payment-processor

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 2. Complete Inventory

```bash
./list-features.sh --all
```

Shows:
- ✅ Feature Registry (built with build-feature.sh)
- ✅ All Supabase Edge Functions (auto-discovered)
- ✅ All N8n Workflows (auto-discovered)
- ✅ Recent build directories

Perfect for seeing **everything** in your system!

### 3. Search Features

```bash
# Search by name
./list-features.sh --search email

# Search by description
./list-features.sh --search "stripe"
./list-features.sh --search "grant"
```

Output:
```
🔍 Searching for: "email"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: email-sender
  Description: Send emails via SendGrid with validation
  Built: 02:15 PM

Feature: email-notifier
  Description: Send email notifications to users
  Built: 03:20 PM

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 4. Feature Details

```bash
./list-features.sh --details email-sender
```

Output:
```
📋 Feature Details: email-sender
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Name:        email-sender
Description: Send emails via SendGrid with validation
Status:      deployed
Built:       02:15 PM
Build Dir:   /tmp/autonomous-builds/email-sender-1760930497

Edge Function URL:
  https://hjtvtkffpziopozmtsnb.supabase.co/functions/v1/email-sender

N8n Workflow:
  Search for: [ACTIVE] [email-sender]

Files:
  - Plan:      /tmp/autonomous-builds/email-sender-1760930497/plan.md
  - Code:      /tmp/autonomous-builds/email-sender-1760930497/index.ts
  - Workflow:  /tmp/autonomous-builds/email-sender-1760930497/workflow.json
  - Tests:     /tmp/autonomous-builds/email-sender-1760930497/test-cases.sh

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 5. Quick Discovery

```bash
# Just show Edge Functions
./list-features.sh --edge-functions

# Just show N8n Workflows
./list-features.sh --workflows

# Just show build directories
./list-features.sh --builds
```

## Real-World Use Cases

### Case 1: "What did I call that email feature?"

```bash
./list-features.sh --search email
```

Instantly see all email-related features!

### Case 2: "When did I build the payment processor?"

```bash
./list-features.sh --details payment-processor
```

Shows exact timestamp and build location.

### Case 3: "What features do I have deployed?"

```bash
./list-features.sh
```

See complete list of all registered features.

### Case 4: "What's the URL for my hello-world function?"

```bash
./list-features.sh --details hello-world-test
```

Shows full Edge Function URL and all files.

### Case 5: "Let me see everything in my system"

```bash
./list-features.sh --all
```

Complete inventory:
- Features built with build-feature.sh
- All Edge Functions in Supabase
- All N8n Workflows
- Recent build directories

## Answering Your Question

> "Do you record all the feature names? Can I ask you later on what the names are?"

**Yes!** Now you can:

### Ask Me Anytime

```
You: "What features have I built?"
Claude: Let me check...
```

I'll run:
```bash
./list-features.sh
```

And show you everything!

### Ask for Specific Features

```
You: "What was that email feature called?"
Claude: Let me search...
```

I'll run:
```bash
./list-features.sh --search email
```

And find it for you!

### Ask for Details

```
You: "What's the URL for hello-world-test?"
Claude: Let me get those details...
```

I'll run:
```bash
./list-features.sh --details hello-world-test
```

And show you the complete info!

## Export Registry

Want to backup or share your registry?

```bash
# Export to JSON
./list-features.sh --export my-features.json

# Export with custom name
./list-features.sh --export backup-2025-01-20.json
```

## Integration with Other Tools

### With fix-feature.sh

```bash
# See what features exist
./list-features.sh

# Pick one to fix
./fix-feature.sh email-sender "Issue description"
```

### With smart-fix.sh

```bash
# List all features and workflows
./list-features.sh --all

# Fix something (no name needed!)
./smart-fix.sh "Description of issue"
```

## Registry Location

The registry is stored at:
```
/Users/christophertolleymacbook2019/.feature-registry.json
```

It's a hidden file (starts with `.`) and persists between sessions.

## What About Features Built Before?

Features built **before** the registry system won't be in the registry, but you can still see them:

```bash
# See recent build directories
./list-features.sh --builds

# Discover deployed Edge Functions
./list-features.sh --edge-functions

# Discover N8n Workflows
./list-features.sh --workflows

# Or see everything
./list-features.sh --all
```

From now on, every feature built with `build-feature.sh` will be automatically registered!

## Example Conversation

**You:** "What features have I built?"

**Me:**
```bash
./list-features.sh
```

```
📋 Feature Registry (5 features)

Feature: hello-world-test
Feature: email-sender
Feature: payment-processor
Feature: grants-scraper
Feature: user-auth
```

**You:** "What was that grants one called exactly?"

**Me:**
```bash
./list-features.sh --search grants
```

```
Feature: grants-scraper
  Description: Scrape grants.gov and extract data
  Built: 10:30 AM
```

**You:** "What's the URL for that?"

**Me:**
```bash
./list-features.sh --details grants-scraper
```

```
Edge Function URL:
  https://hjtvtkffpziopozmtsnb.supabase.co/functions/v1/grants-scraper
```

Done! ✨

## Summary

✅ **Automatic** - Features are registered automatically when built
✅ **Searchable** - Find features by name or description
✅ **Persistent** - Registry survives restarts
✅ **Queryable** - Ask me anytime what features you've built
✅ **Discoverable** - Can also discover existing Edge Functions and N8n Workflows

You'll never forget what you named a feature again! 🎉
