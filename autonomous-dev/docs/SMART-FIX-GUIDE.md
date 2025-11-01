# smart-fix.sh - Fix Issues Without Knowing Feature Names

## The Problem It Solves

You have complex workflows like **Grants-Gov** that:
- Weren't built by build-feature.sh
- Have many interconnected parts
- Don't have a simple "feature name"
- Have bugs in specific nodes or database operations

**Example**: "The Grants-Gov workflow works except it's not inserting grant amounts and deadline dates into individual database fields."

You can't use `fix-feature.sh grants-gov` because:
- ❌ "grants-gov" isn't a single edge function
- ❌ It's a complex N8n workflow with many nodes
- ❌ The issue is in a specific part, not the whole thing
- ❌ You don't know the exact workflow ID

## The Solution: smart-fix.sh

**Just describe the problem - it auto-discovers everything!**

```bash
./smart-fix.sh "Grants-Gov workflow not inserting grant amounts and deadlines into database"
```

No feature name needed. No workflow ID needed. Just describe what's broken.

## How It Works

### 6-Phase Auto-Discovery Process

```
1. 🔍 Auto-Discovery
   ├─ Lists ALL N8n workflows
   ├─ Lists ALL Edge Functions
   ├─ Uses AI to identify affected components
   └─ Finds the exact workflow/function with the issue

2. 📊 Gather Detailed State
   ├─ Fetches complete workflow definition
   ├─ Gets recent executions
   ├─ Retrieves database schema
   └─ Collects logs

3. 🔬 Root Cause Analysis
   ├─ Analyzes data flow through nodes
   ├─ Identifies which node(s) have the bug
   ├─ Finds exactly what's wrong
   └─ Determines why data isn't being inserted

4. 🔧 Generate Fixes
   ├─ Creates specific node configuration changes
   ├─ Generates SQL migrations if needed
   ├─ Provides exact field mappings
   └─ Creates verification queries

5. 📝 Apply Fixes
   ├─ Provides step-by-step instructions
   └─ (Manual application for N8n workflows)

6. 📊 Generate Report
   ├─ Complete analysis and fixes
   ├─ Testing strategy
   └─ Verification queries
```

## Real-World Example: Your Grants-Gov Issue

### The Problem
```bash
./smart-fix.sh "Grants-Gov workflow is working well except I discovered that the workflow isn't inserting grant amounts and deadline dates into individual database fields"
```

### What Happens

**Phase 1: Auto-Discovery** (30 seconds)
```
🔍 Fetching all N8n workflows...
Found workflows:
abc123def456|[ACTIVE] Grants-Gov Scraper Main
xyz789ghi012|[ACTIVE] Grants-Gov Intelligence Extraction
...

📦 Fetching all Edge Functions...
Found: grants-gov-scraper-complete, extract-structured-data...

🤖 AI Analysis:
"Based on the issue description, the affected component is:
- Workflow: [ACTIVE] Grants-Gov Intelligence Extraction
- Workflow ID: xyz789ghi012
- Likely issue: Supabase Insert node not mapping grant_amount and deadline fields
- Investigation: Check the 'Insert Grant Data' node configuration"
```

**Phase 2: Gather State** (20 seconds)
```
📊 Fetching workflow definition...
✅ Retrieved 47 nodes, 89 connections

📋 Fetching recent executions...
✅ Found 23 executions in last 24 hours

🗄️ Fetching database schema...
✅ Retrieved 'grants' table with columns:
   - id, title, description, grant_amount, deadline, created_at...
```

**Phase 3: Root Cause Analysis** (30 seconds)
```
🔬 Analyzing data flow...

Root Cause Found:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Node: "Insert Grant Data" (Supabase node)

Current Configuration:
- Mapping 'title' → grants.title ✅
- Mapping 'description' → grants.description ✅
- Missing: grant_amount field mapping ❌
- Missing: deadline field mapping ❌

The data IS available from the previous "Extract Intelligence" node:
- $json.grant_amount = "500000"
- $json.deadline = "2025-12-31"

But the Supabase Insert node isn't configured to insert these fields.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Phase 4: Generate Fixes** (40 seconds)
```
🔧 Generating specific fixes...

Fix for Node: "Insert Grant Data"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current Configuration:
{
  "columns": {
    "title": "={{ $json.title }}",
    "description": "={{ $json.description }}"
  }
}

Fixed Configuration:
{
  "columns": {
    "title": "={{ $json.title }}",
    "description": "={{ $json.description }}",
    "grant_amount": "={{ $json.grant_amount }}",
    "deadline": "={{ $json.deadline }}"
  }
}

What Changed:
✅ Added grant_amount field mapping
✅ Added deadline field mapping

Verification SQL:
SELECT id, title, grant_amount, deadline
FROM grants
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 10;
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Phase 5: Apply Fixes** (manual)
```
📝 Manual steps to apply fix:

1. Open N8n: https://n8n.grantpilot.app
2. Find workflow: "Grants-Gov Intelligence Extraction" (ID: xyz789ghi012)
3. Locate node: "Insert Grant Data"
4. Update the Columns configuration to add:
   - grant_amount: ={{ $json.grant_amount }}
   - deadline: ={{ $json.deadline }}
5. Save and activate
```

**Phase 6: Report Generated**
```
📊 Complete report saved to:
/tmp/smart-fixes/smart-fix-1234567890/SMART-FIX-REPORT.md

Includes:
- Root cause analysis ✅
- Exact node configurations ✅
- Before/after comparison ✅
- Verification SQL ✅
- Testing strategy ✅
```

## More Real-World Examples

### Example 1: Database Field Missing
```bash
./smart-fix.sh "Email workflow sends emails successfully but doesn't log the recipient email address in the database"
```

**Auto-discovers:**
- Workflow: Email Handler
- Issue: Supabase insert node missing `recipient` column
- Fix: Add field mapping

### Example 2: Data Transformation Bug
```bash
./smart-fix.sh "Payment workflow stores transaction but the amount is always showing as NaN instead of the actual dollar amount"
```

**Auto-discovers:**
- Workflow: Payment Processor
- Issue: Code node converting string to number incorrectly
- Fix: Add `parseFloat()` conversion

### Example 3: Multi-Node Issue
```bash
./smart-fix.sh "User registration workflow creates user but doesn't send welcome email even though the email node is there"
```

**Auto-discovers:**
- Workflow: User Registration
- Issue: Email node isn't connected on the success path
- Fix: Update workflow connections

### Example 4: API Integration Issue
```bash
./smart-fix.sh "Slack notification workflow triggers but messages don't actually post to Slack channel"
```

**Auto-discovers:**
- Workflow: Slack Notifier
- Issue: Slack node missing channel ID parameter
- Fix: Add channel configuration

## Output Files

After running, you get:

```
/tmp/smart-fixes/smart-fix-1234567890/
├── SMART-FIX-REPORT.md          # Complete report ⭐
├── discovery-analysis.md         # Which components affected
├── root-cause-analysis.md        # Detailed bug analysis
├── proposed-fixes.md             # Exact fixes with configs ⭐
├── workflow-full.json            # Complete workflow definition
├── updated-workflow.json         # Fixed workflow (if applicable)
├── database-migration.sql        # SQL changes (if needed)
├── workflow-executions.json      # Recent runs
├── database-schema.json          # DB structure
└── all-workflows.json            # All N8n workflows
```

## How to Apply the Fixes

### For N8n Workflow Issues (Most Common)

1. **Read the fix report:**
   ```bash
   cat /tmp/smart-fixes/*/proposed-fixes.md
   ```

2. **Open N8n:**
   - Go to https://n8n.grantpilot.app
   - Find the workflow (ID provided in report)

3. **Update node configurations:**
   - Locate the specific node(s) mentioned
   - Copy the "Fixed Configuration" from the report
   - Paste into the node settings

4. **Save and test:**
   - Save workflow
   - Trigger manually or wait for next execution
   - Verify with SQL queries provided

### For Database Changes

1. **Check for migration file:**
   ```bash
   cat /tmp/smart-fixes/*/database-migration.sql
   ```

2. **Apply via Supabase:**
   - Open Supabase SQL Editor
   - Paste and run the migration
   - Verify with queries

### For Edge Function Issues

If an Edge Function needs updating:
- Check `proposed-fixes.md` for code changes
- Can use `fix-feature.sh` for auto-deployment
- Or manually update via Supabase dashboard

## Verification After Fix

The report includes verification steps:

```sql
-- Example verification query
SELECT
  id,
  title,
  grant_amount,    -- Should now be populated ✅
  deadline,        -- Should now be populated ✅
  created_at
FROM grants
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 10;
```

Run this to confirm the fix worked!

## Advantages Over fix-feature.sh

| Feature | fix-feature.sh | smart-fix.sh |
|---------|----------------|--------------|
| **Requires feature name?** | ✅ Yes | ❌ No |
| **Requires workflow ID?** | ✅ Yes | ❌ No |
| **Auto-discovers components** | ❌ No | ✅ Yes |
| **Works with complex workflows** | ⚠️ Limited | ✅ Yes |
| **Identifies specific nodes** | ❌ No | ✅ Yes |
| **Works with partial issues** | ❌ No | ✅ Yes |
| **Handles DB-only issues** | ❌ No | ✅ Yes |
| **Multi-component analysis** | ❌ No | ✅ Yes |

## When to Use Each Tool

### Use smart-fix.sh when:
- ✅ Don't know feature name or workflow ID
- ✅ Issue is in specific node or database operation
- ✅ Part of a larger workflow is broken
- ✅ Complex multi-step workflow issue
- ✅ Database fields not being inserted/updated
- ✅ Data transformation bug in specific node

### Use fix-feature.sh when:
- ✅ You know the exact feature name
- ✅ Feature was built by build-feature.sh
- ✅ Issue affects entire Edge Function
- ✅ Need to redeploy Edge Function code

### Use build-feature.sh when:
- ✅ Building something completely new
- ✅ Starting from scratch

## Tips for Best Results

### 1. Be Specific About the Issue
```bash
# ❌ Too vague
./smart-fix.sh "Something is broken with grants"

# ✅ Specific and detailed
./smart-fix.sh "Grants-Gov workflow successfully scrapes grants and creates database records, but the grant_amount and deadline columns are always NULL instead of containing the actual values from grants.gov"
```

### 2. Include What IS Working
```bash
# ✅ Helpful context
./smart-fix.sh "Email workflow sends emails successfully and logs to_address, but doesn't save the subject line or email body to the database"
```

### 3. Mention Where You See the Issue
```bash
# ✅ Very helpful
./smart-fix.sh "When I check the database, the grants table has title and description filled in, but grant_amount and deadline are always NULL. The N8n execution shows these values are extracted correctly."
```

### 4. Include Database/Table Names if Known
```bash
# ✅ Speeds up analysis
./smart-fix.sh "The 'grants' table is missing data in the 'funding_amount' column even though the workflow extracts this data"
```

## Common Use Cases

### Use Case 1: Missing Database Fields
**Problem:** Workflow works but some database columns are NULL

```bash
./smart-fix.sh "Grants workflow inserts title and agency but doesn't insert eligibility criteria or application_deadline into the grants table"
```

**What it finds:**
- Exact Supabase node with incomplete field mapping
- Fields available but not mapped
- Exact configuration to add

### Use Case 2: Data Transformation Error
**Problem:** Data is being transformed incorrectly

```bash
./smart-fix.sh "Grant amounts are showing as '$500,000' as text instead of 500000 as a number in the database"
```

**What it finds:**
- Code node doing the transformation
- Type conversion issue
- Fixed conversion logic

### Use Case 3: Workflow Logic Error
**Problem:** Conditional logic not working

```bash
./smart-fix.sh "Grants marked as 'closed' are still being inserted into the database instead of being skipped"
```

**What it finds:**
- IF node with incorrect condition
- Current logic vs expected logic
- Corrected condition configuration

### Use Case 4: API Integration Issue
**Problem:** External API call failing

```bash
./smart-fix.sh "Slack notifications aren't posting to channel even though the workflow shows success"
```

**What it finds:**
- HTTP Request node missing auth header
- Incorrect API endpoint
- Fixed configuration with proper auth

## Example Full Workflow: Grants-Gov Fix

```bash
# 1. Discover the issue
# "Grant amounts and deadlines aren't in the database"

# 2. Run smart-fix
./smart-fix.sh "Grants-Gov workflow not inserting grant amounts and deadlines into database even though the workflow extracts them successfully"

# 3. Wait 2-3 minutes
# Check Slack for progress updates

# 4. Review the fix report
cat /tmp/smart-fixes/*/SMART-FIX-REPORT.md

# Output shows:
# - Workflow: "Grants-Gov Intelligence Extraction"
# - Node: "Insert Grant Data"
# - Issue: Missing field mappings for grant_amount and deadline
# - Fix: Add two field mappings

# 5. Apply the fix
# Open N8n at https://n8n.grantpilot.app
# Find "Grants-Gov Intelligence Extraction" workflow
# Edit "Insert Grant Data" node
# Add fields:
#   - grant_amount: ={{ $json.grant_amount }}
#   - deadline: ={{ $json.deadline }}
# Save

# 6. Verify the fix
# Trigger workflow or wait for next automatic run

# 7. Check database
psql -c "SELECT id, title, grant_amount, deadline FROM grants ORDER BY created_at DESC LIMIT 5;"

# Output:
# id  | title                    | grant_amount | deadline
# ----+--------------------------+--------------+------------
# 123 | Research Grant Program   | 500000       | 2025-12-31
# 122 | Innovation Fund          | 1000000      | 2025-11-15
# 121 | Community Development    | 250000       | 2025-10-30

# ✅ Fixed! Grant amounts and deadlines now populating correctly!
```

## Summary

**smart-fix.sh** = No feature name needed!

Just describe the problem:
- "Workflow not inserting X into database"
- "Data showing as Y instead of Z"
- "Feature works except for this one part"

It auto-discovers:
- Which workflow is affected
- Which nodes have bugs
- What's wrong and how to fix it

Perfect for:
- Complex workflows
- Partial issues
- Database problems
- Specific node bugs
- Unknown feature names

**Your new workflow:**
1. Notice a bug
2. Describe it to smart-fix.sh
3. Get exact fix with node configurations
4. Apply in 2 minutes
5. Verify with provided SQL
6. Done! ✅
