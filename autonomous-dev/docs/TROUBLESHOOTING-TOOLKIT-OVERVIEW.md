# Complete Troubleshooting Toolkit

## All Three Tools at a Glance

```
┌─────────────────────────────────────────────────────────────────────┐
│                    YOUR AUTONOMOUS TOOLKIT                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. build-feature.sh     →  Build NEW features from scratch        │
│  2. fix-feature.sh       →  Fix features with known names          │
│  3. smart-fix.sh         →  Fix issues without knowing names ⭐    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Quick Decision Tree

```
Do you need to...

├─ Build something NEW?
│  └─ Use: build-feature.sh
│     └─ ./build-feature.sh <name> "<description>"
│
├─ Fix something with a known feature name?
│  └─ Use: fix-feature.sh
│     └─ ./fix-feature.sh <feature-name> "<issue>"
│
└─ Fix something but don't know the feature name?
   └─ Use: smart-fix.sh ⭐
      └─ ./smart-fix.sh "<just describe the problem>"
```

## Tool Comparison

| Capability | build-feature.sh | fix-feature.sh | smart-fix.sh |
|------------|------------------|----------------|--------------|
| **Input Required** | Feature name + description | Feature name + issue | Just issue description |
| **Auto-discovers components** | N/A | ❌ No | ✅ Yes |
| **Needs feature name** | ✅ Yes (new name) | ✅ Yes | ❌ No |
| **Needs workflow ID** | N/A | ❌ No | ❌ No |
| **Works with complex workflows** | Creates new | ⚠️ If feature-named | ✅ Yes |
| **Identifies specific nodes** | N/A | ❌ No | ✅ Yes |
| **Database-only issues** | N/A | ⚠️ Limited | ✅ Yes |
| **Partial workflow issues** | N/A | ⚠️ Limited | ✅ Yes |
| **Auto-deploys fixes** | ✅ Yes | ✅ Yes (Edge) | ⚠️ Manual |
| **Best for** | New features | Known features | Unknown components |

## Real-World Scenarios

### Scenario 1: Building Something New
**Situation:** "I need a new webhook handler for GitHub events"

**Use:** `build-feature.sh`
```bash
./build-feature.sh github-webhook "Handle GitHub webhook events with validation and database logging"
```

**Why:** Starting from scratch, need both Edge Function and N8n workflow.

---

### Scenario 2: Feature Bug with Known Name
**Situation:** "My hello-world-test feature returns 500 errors"

**Use:** `fix-feature.sh`
```bash
./fix-feature.sh hello-world-test "Returns 500 error instead of greeting"
```

**Why:** You know it's the "hello-world-test" feature specifically.

---

### Scenario 3: Workflow Bug, Don't Know Feature Name
**Situation:** "Grants-Gov workflow isn't inserting amounts into database"

**Use:** `smart-fix.sh` ⭐
```bash
./smart-fix.sh "Grants-Gov workflow not inserting grant amounts and deadlines into database"
```

**Why:**
- Don't know exact workflow ID
- Complex workflow with many parts
- Issue is specific to database insertion
- Wasn't built by build-feature.sh

---

## Common Use Cases

### Use Case 1: Missing Database Fields

**Problem:**
```
"I noticed in the database that the 'grants' table has
title and description, but grant_amount and deadline
are always NULL even though I see these values in the
N8n execution logs."
```

**Solution:**
```bash
./smart-fix.sh "Grants table missing grant_amount and deadline even though workflow extracts them"
```

**What happens:**
1. Auto-discovers the Grants-Gov workflow
2. Identifies the Supabase Insert node
3. Finds it's missing field mappings
4. Provides exact configuration to add
5. Gives SQL to verify

**Time:** 2-3 minutes
**Manual steps:** Update one node in N8n

---

### Use Case 2: Data Transformation Bug

**Problem:**
```
"Grant amounts are showing as '$500,000' (text with
dollar sign and comma) instead of 500000 as a number
in the database."
```

**Solution:**
```bash
./smart-fix.sh "Grant amounts storing as text like '$500,000' instead of numbers like 500000"
```

**What happens:**
1. Finds the data transformation node
2. Identifies incorrect string-to-number conversion
3. Provides fixed transformation code
4. Shows before/after examples

---

### Use Case 3: Workflow Logic Error

**Problem:**
```
"Closed grants are still being inserted into the
database instead of being skipped. I thought we had
a filter for this but it's not working."
```

**Solution:**
```bash
./smart-fix.sh "Closed grants being inserted instead of skipped, status filter not working"
```

**What happens:**
1. Finds the IF node with status check
2. Identifies logic error in condition
3. Provides corrected condition
4. Shows data flow

---

### Use Case 4: API Integration Issue

**Problem:**
```
"Slack notifications workflow shows success in N8n
but messages aren't actually posting to the Slack
channel."
```

**Solution:**
```bash
./smart-fix.sh "Slack workflow shows success but messages don't post to channel"
```

**What happens:**
1. Finds Slack HTTP Request node
2. Identifies missing channel ID or auth
3. Provides correct configuration
4. Gives test curl command

---

## When to Use Each Tool - Detailed

### Use build-feature.sh when:

✅ **Starting from zero**
- No existing code
- Need complete feature (Edge Function + N8n)
- Want full planning and architecture

✅ **Examples:**
```bash
./build-feature.sh email-sender "Send emails via SendGrid with validation"
./build-feature.sh pdf-generator "Generate PDFs from HTML templates"
./build-feature.sh user-auth "Authenticate users with JWT tokens"
```

---

### Use fix-feature.sh when:

✅ **You know the feature name**
- Feature was built by build-feature.sh
- You know the exact Edge Function name
- Issue affects the entire feature

✅ **Examples:**
```bash
./fix-feature.sh email-sender "Returns 500 error when sending"
./fix-feature.sh pdf-generator "PDFs are corrupted or blank"
./fix-feature.sh user-auth "Rejecting valid JWT tokens"
```

---

### Use smart-fix.sh when:

✅ **Don't know feature/workflow name** ⭐
- Complex workflow with many parts
- Issue in specific node or operation
- Database field not being populated
- Wasn't built by build-feature.sh
- Multiple components involved

✅ **Examples:**
```bash
./smart-fix.sh "Grants workflow not inserting amounts"
./smart-fix.sh "Email body not saving to database"
./smart-fix.sh "Closed items still being processed"
./smart-fix.sh "Slack messages not posting"
```

**Key difference:** Just describe the problem, don't need names!

---

## Output Comparison

### build-feature.sh Output
```
/tmp/autonomous-builds/feature-name-123/
├── plan.md                    # Architecture plan
├── index.ts                   # Edge Function code
├── workflow.json              # N8n workflow
├── test-cases.sh              # Integration tests
└── validation-report.txt      # Final report
```

### fix-feature.sh Output
```
/tmp/autonomous-fixes/feature-name-fix-123/
├── FIX-REPORT.md              # Complete report
├── diagnostic-analysis.md      # Root cause
├── fixed-edge-function.ts      # Fixed code
├── verification-tests.sh       # Tests
└── current-edge-function.ts    # Original code
```

### smart-fix.sh Output ⭐
```
/tmp/smart-fixes/smart-fix-123/
├── SMART-FIX-REPORT.md        # Complete report
├── discovery-analysis.md       # Component identification
├── root-cause-analysis.md      # Detailed bug analysis
├── proposed-fixes.md           # Node configs & SQL ⭐
├── workflow-full.json          # Full workflow def
├── database-migration.sql      # SQL changes
└── all-workflows.json          # All workflows
```

---

## Example: Complete Feature Lifecycle

### Week 1: Build
```bash
# Build new grants processor
./build-feature.sh grants-processor "Process grants.gov data and store in database"

# Result: Working feature deployed
```

### Week 2: Discover Bug (Known Feature)
```bash
# Notice the Edge Function has an error
./fix-feature.sh grants-processor "Edge function timeout after 10 seconds"

# Result: Edge Function fixed and redeployed
```

### Week 3: Discover Workflow Issue (Unknown Location)
```bash
# Notice data missing from database
./smart-fix.sh "Grants workflow not inserting grant amounts and deadlines"

# Result: Specific node identified and fixed
```

---

## Your Grants-Gov Example - Which Tool?

### The Issue
```
"My Grants-Gov workflow is working well except I discovered
that the workflow isn't inserting grant amounts and deadline
dates into individual DB fields."
```

### Analysis
- ❌ Can't use `build-feature.sh` - feature already exists
- ❌ Can't use `fix-feature.sh "grants-gov" ...` - not a feature name
- ✅ **Use `smart-fix.sh`** - perfect fit!

### Why smart-fix.sh?
1. ✅ Don't need to know workflow ID
2. ✅ Issue is specific to database insertion
3. ✅ Complex workflow with many parts
4. ✅ Just need to describe the problem

### Solution
```bash
./smart-fix.sh "Grants-Gov workflow not inserting grant amounts and deadline dates into individual database fields"
```

### What You Get
```
📊 Auto-discovers:
- Workflow: "Grants-Gov Intelligence Extraction" (ID: xyz123)
- Issue: Supabase Insert node "Insert Grant Data"
- Missing: grant_amount and deadline field mappings

🔧 Provides exact fix:
Node: "Insert Grant Data"
Add fields:
  - grant_amount: ={{ $json.grant_amount }}
  - deadline: ={{ $json.deadline }}

✅ Verification SQL:
SELECT id, title, grant_amount, deadline
FROM grants
ORDER BY created_at DESC LIMIT 10;
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────────┐
│                    WHICH TOOL DO I USE?                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  "I need to BUILD something new"                                   │
│  → build-feature.sh <name> "<description>"                         │
│                                                                     │
│  "I know the FEATURE NAME that's broken"                           │
│  → fix-feature.sh <feature-name> "<issue>"                         │
│                                                                     │
│  "Something's broken but I DON'T KNOW the feature name"            │
│  → smart-fix.sh "<just describe what's wrong>" ⭐                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Tips for Success

### For smart-fix.sh (Most Important) ⭐

**Be Specific:**
```bash
# ❌ Too vague
./smart-fix.sh "grants broken"

# ✅ Specific
./smart-fix.sh "Grants-Gov workflow successfully scrapes grants and creates database records, but grant_amount and deadline columns are NULL"
```

**Include Context:**
```bash
# ✅ Very helpful
./smart-fix.sh "When I check the grants table, title and agency are filled but grant_amount is NULL. N8n execution logs show grant_amount is extracted successfully as '$500,000'"
```

**Mention What Works:**
```bash
# ✅ Helps narrow down issue
./smart-fix.sh "Email workflow sends emails successfully and logs sender, but doesn't save email subject or body to database"
```

---

## Summary

You now have **3 powerful tools:**

1. **build-feature.sh** - Build from scratch
   - Input: Feature name + description
   - Output: Complete new feature

2. **fix-feature.sh** - Fix known features
   - Input: Feature name + issue
   - Output: Fixed and redeployed

3. **smart-fix.sh** ⭐ - Fix unknown issues
   - Input: Just describe the problem
   - Output: Auto-discovered fix with exact configs

**For your Grants-Gov issue:**
```bash
./smart-fix.sh "Grants-Gov workflow not inserting grant amounts and deadlines into database"
```

That's it! No feature name, no workflow ID, just describe the problem. ✨
