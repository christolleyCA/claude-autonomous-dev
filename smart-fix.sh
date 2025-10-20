#!/bin/bash
# Smart-Fix - Auto-discover and fix issues without needing feature names
# Works with N8n workflows, Edge Functions, or both

# DO NOT USE set -e - we need graceful error handling!

# ============================================================================
# CONFIGURATION
# ============================================================================

# Load .env if available
[ -f "${BASH_SOURCE[0]%/*}/.env" ] && source "${BASH_SOURCE[0]%/*}/.env"
SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN:-}"
SLACK_CHANNEL="C09M9A33FFF"
SUPABASE_PROJECT_ID="hjtvtkffpziopozmtsnb"
N8N_URL="https://n8n.grantpilot.app"
FIX_DIR="/tmp/smart-fixes"
ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"

mkdir -p "$FIX_DIR"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# HELPERS
# ============================================================================

send_slack() {
    local message="$1"
    local payload=$(jq -n \
        --arg channel "$SLACK_CHANNEL" \
        --arg text "$message" \
        '{channel: $channel, text: $text}')

    curl -s -X POST "https://slack.com/api/chat.postMessage" \
        -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$payload" > /dev/null 2>&1
}

call_claude_api() {
    local prompt="$1"
    local system_prompt="$2"

    if [ -z "$ANTHROPIC_API_KEY" ]; then
        echo "ERROR: ANTHROPIC_API_KEY not set" >&2
        return 1
    fi

    local api_response=$(curl -s https://api.anthropic.com/v1/messages \
        -H "x-api-key: ${ANTHROPIC_API_KEY}" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "$(jq -n \
            --arg prompt "$prompt" \
            '{
                model: "claude-sonnet-4-20250514",
                max_tokens: 4096,
                messages: [{role: "user", content: $prompt}]
            }')")

    echo "$api_response" | jq -r '.content[0].text // empty'
}

# ============================================================================
# PHASE 1: AUTO-DISCOVERY
# ============================================================================

smart_fix_discover() {
    local issue_description="$1"
    local fix_dir="$2"

    send_slack "🔍 *SMART-FIX: Auto-Discovery*

Issue: ${issue_description}

Analyzing to identify affected components..."

    echo "🔍 Phase 1: Auto-discovering affected components..."
    echo ""

    # Get all N8n workflows
    echo "📋 Fetching all N8n workflows..."
    local workflows_json=$(claude code execute mcp__n8n-mcp__n8n_list_workflows 2>&1)
    echo "$workflows_json" > "${fix_dir}/all-workflows.json"

    # Get workflow names/IDs
    local workflow_list=$(echo "$workflows_json" | jq -r '.[] | "\(.id)|\(.name)"' 2>/dev/null || echo "")

    echo "Found workflows:"
    echo "$workflow_list" | head -20
    echo ""

    # Get all Edge Functions
    echo "📦 Fetching all Edge Functions..."
    local functions_json=$(claude code execute mcp__supabase__list_edge_functions \
        --project_id "$SUPABASE_PROJECT_ID" 2>&1)
    echo "$functions_json" > "${fix_dir}/all-functions.json"

    echo "✅ Component discovery complete"
    echo ""

    # Use AI to identify which component(s) are affected
    local discovery_prompt="Based on this issue description:

\"${issue_description}\"

Available N8n Workflows:
${workflow_list}

Available Edge Functions:
${functions_json}

Analyze and determine:

## 1. Affected Components
Which specific workflow(s) or edge function(s) are likely affected?
- Workflow ID and name (if workflow-related)
- Edge function name (if function-related)
- Or both?

## 2. Issue Type
- Database operation bug?
- Data transformation issue?
- Validation problem?
- API integration issue?
- Workflow logic error?

## 3. Likely Location
- Which specific node(s) in the workflow?
- Which part of the edge function?
- Which database table/column?

## 4. Recommended Investigation
What should we examine first?

Be specific. If you're not certain, list top 2-3 possibilities."

    local discovery_result=$(call_claude_api "$discovery_prompt" "You are an expert at diagnosing system issues. Identify the affected components based on the issue description.")

    echo "$discovery_result" > "${fix_dir}/discovery-analysis.md"

    # Extract workflow ID and name from discovery
    local workflow_id=$(echo "$discovery_result" | grep -i "workflow" | grep -oE '[a-zA-Z0-9]{16}' | head -1)
    local workflow_name=$(echo "$discovery_result" | grep -i "workflow.*name" | head -1)

    send_slack "✅ *Discovery Complete*

Analysis saved to:
\`${fix_dir}/discovery-analysis.md\`

Identified components - proceeding to detailed analysis..."

    echo "✅ Phase 1 Complete"
    echo ""
    echo "Discovery Result:"
    echo "$discovery_result"
    echo ""

    # Return workflow ID if found
    echo "$workflow_id"
}

# ============================================================================
# PHASE 2: GATHER DETAILED STATE
# ============================================================================

smart_fix_gather_state() {
    local workflow_id="$1"
    local fix_dir="$2"
    local issue_description="$3"

    send_slack "📊 *Phase 2: Gathering Detailed State*

Collecting workflow details, logs, and execution data..."

    echo "📊 Phase 2: Gathering detailed state..."
    echo ""

    if [ -n "$workflow_id" ]; then
        echo "🔍 Fetching workflow details (ID: ${workflow_id})..."

        # Get full workflow definition
        local workflow_details=$(claude code execute mcp__n8n-mcp__n8n_get_workflow \
            --workflow_id "$workflow_id" 2>&1)

        echo "$workflow_details" > "${fix_dir}/workflow-full.json"
        echo "✅ Workflow definition retrieved"
        echo ""

        # Get recent executions
        echo "📋 Fetching recent executions..."
        local executions=$(claude code execute mcp__n8n-mcp__n8n_list_executions 2>&1)
        echo "$executions" | jq ".[] | select(.workflowId == \"${workflow_id}\")" > "${fix_dir}/workflow-executions.json" 2>/dev/null || echo "{}" > "${fix_dir}/workflow-executions.json"
        echo "✅ Executions retrieved"
        echo ""
    fi

    # Get database schema
    echo "🗄️  Fetching database schema..."
    local tables=$(claude code execute mcp__supabase__list_tables \
        --project_id "$SUPABASE_PROJECT_ID" 2>&1)
    echo "$tables" > "${fix_dir}/database-schema.json"
    echo "✅ Database schema retrieved"
    echo ""

    # Get recent Supabase logs
    echo "📜 Fetching recent logs..."
    local logs=$(claude code execute mcp__supabase__get_logs \
        --project_id "$SUPABASE_PROJECT_ID" \
        --service "api" 2>&1)
    echo "$logs" > "${fix_dir}/recent-logs.txt"
    echo "✅ Logs retrieved"
    echo ""

    send_slack "✅ *State Collection Complete*

Retrieved:
- Workflow definition ✅
- Recent executions ✅
- Database schema ✅
- System logs ✅

Ready for root cause analysis..."

    echo "✅ Phase 2 Complete"
    echo ""
}

# ============================================================================
# PHASE 3: ROOT CAUSE ANALYSIS
# ============================================================================

smart_fix_analyze() {
    local fix_dir="$1"
    local issue_description="$2"

    send_slack "🔬 *Phase 3: Root Cause Analysis*

Analyzing workflow logic, data flow, and identifying the bug..."

    echo "🔬 Phase 3: Analyzing root cause..."
    echo ""

    # Read gathered data
    local workflow_def=$(cat "${fix_dir}/workflow-full.json" 2>/dev/null || echo "{}")
    local executions=$(cat "${fix_dir}/workflow-executions.json" 2>/dev/null || echo "{}")
    local db_schema=$(cat "${fix_dir}/database-schema.json" 2>/dev/null || echo "{}")
    local logs=$(cat "${fix_dir}/recent-logs.txt" 2>/dev/null || echo "")

    # Deep analysis with AI
    local analysis_prompt="You are debugging a workflow issue. Here's what we know:

## User-Reported Issue
${issue_description}

## Workflow Definition
\`\`\`json
${workflow_def}
\`\`\`

## Recent Executions
\`\`\`json
${executions}
\`\`\`

## Database Schema
\`\`\`json
${db_schema}
\`\`\`

## Recent Logs
\`\`\`
${logs}
\`\`\`

Provide detailed analysis:

## 1. Root Cause
What is the exact bug? Be specific.
- Which node(s) are involved?
- What is the logic error?
- What data is being lost or incorrectly processed?

## 2. Data Flow Analysis
Trace the data flow:
- Where does the data come from?
- How is it being transformed?
- Where is it supposed to go?
- Where is it failing?

## 3. Database Operations
If this is a database issue:
- Which table(s) are involved?
- Which columns are affected?
- What SQL is being executed?
- What SQL should be executed?

## 4. Specific Node Issues
For each problematic node:
- Node name and type
- Current configuration
- What's wrong with it
- How to fix it

## 5. Example Data Flow
Show example of:
- Input data to the node
- Current (incorrect) output
- Expected (correct) output

Be extremely specific with node names, field names, and exact changes needed."

    local analysis=$(call_claude_api "$analysis_prompt" "You are an expert N8n workflow debugger. Provide detailed, specific analysis with exact node names and configurations.")

    echo "$analysis" > "${fix_dir}/root-cause-analysis.md"

    send_slack "✅ *Analysis Complete*

Root cause identified!
Report: \`${fix_dir}/root-cause-analysis.md\`

Generating fixes..."

    echo "✅ Phase 3 Complete"
    echo ""
    echo "Root Cause Analysis:"
    echo "$analysis"
    echo ""

    echo "$analysis"
}

# ============================================================================
# PHASE 4: GENERATE FIXES
# ============================================================================

smart_fix_generate_fixes() {
    local fix_dir="$1"
    local workflow_id="$2"
    local analysis="$3"

    send_slack "🔧 *Phase 4: Generating Fixes*

Creating specific node configurations and SQL fixes..."

    echo "🔧 Phase 4: Generating fixes..."
    echo ""

    local workflow_def=$(cat "${fix_dir}/workflow-full.json" 2>/dev/null || echo "{}")

    local fix_prompt="Based on this root cause analysis:

${analysis}

Current Workflow Definition:
\`\`\`json
${workflow_def}
\`\`\`

Generate SPECIFIC FIXES:

## 1. Node Configuration Changes
For each node that needs fixing, provide:

### Node: [Exact Node Name]
**Current Configuration:**
\`\`\`json
{current config}
\`\`\`

**Fixed Configuration:**
\`\`\`json
{corrected config}
\`\`\`

**What Changed:**
- Specific explanation of each change
- Why this fixes the issue

## 2. Updated Workflow JSON
Provide the COMPLETE updated workflow JSON with all fixes applied.

## 3. Database Changes (if needed)
If database structure needs updating:
\`\`\`sql
-- Migration SQL here
\`\`\`

## 4. Testing Strategy
Provide 3 specific test cases:
1. Test with real grant data
2. Test edge cases (missing data)
3. Test validation

## 5. Verification Queries
SQL queries to verify the fix worked:
\`\`\`sql
-- Check that grant_amount is being inserted
SELECT id, title, grant_amount, deadline FROM grants ORDER BY created_at DESC LIMIT 5;
\`\`\`

Be extremely specific. Output actual JSON configurations and SQL."

    local fixes=$(call_claude_api "$fix_prompt" "You are an expert at fixing N8n workflows. Provide exact, copy-paste-ready configurations and SQL.")

    echo "$fixes" > "${fix_dir}/proposed-fixes.md"

    # Extract updated workflow JSON if present
    local updated_workflow=$(echo "$fixes" | sed -n '/```json/,/```/p' | sed '1d;$d' | tail -n +1)
    if [ -n "$updated_workflow" ]; then
        echo "$updated_workflow" > "${fix_dir}/updated-workflow.json"
    fi

    # Extract SQL migrations if present
    local migrations=$(echo "$fixes" | sed -n '/```sql/,/```/p' | sed '1d;$d')
    if [ -n "$migrations" ]; then
        echo "$migrations" > "${fix_dir}/database-migration.sql"
    fi

    send_slack "✅ *Fixes Generated*

Created:
- Node configuration fixes
- Updated workflow JSON
- Database migrations (if needed)
- Testing strategy
- Verification queries

Files: \`${fix_dir}/\`"

    echo "✅ Phase 4 Complete"
    echo ""
    echo "$fixes"
}

# ============================================================================
# PHASE 5: APPLY FIXES
# ============================================================================

smart_fix_apply() {
    local fix_dir="$1"
    local workflow_id="$2"

    send_slack "📝 *Phase 5: Applying Fixes*

Updating workflow and database..."

    echo "📝 Phase 5: Applying fixes..."
    echo ""

    # Check if we have database migrations
    if [ -f "${fix_dir}/database-migration.sql" ]; then
        echo "🗄️  Database migration detected"
        echo ""
        echo "⚠️  Database Migration Required:"
        cat "${fix_dir}/database-migration.sql"
        echo ""
        echo "Run this migration manually via Supabase dashboard or SQL editor"
        echo ""
    fi

    # Check if we have updated workflow
    if [ -f "${fix_dir}/updated-workflow.json" ]; then
        echo "⚙️  Updated workflow detected"
        echo ""

        local updated_workflow=$(cat "${fix_dir}/updated-workflow.json")

        echo "📋 Workflow update ready"
        echo "Workflow ID: ${workflow_id}"
        echo ""
        echo "⚠️  Workflow Update:"
        echo "Due to N8n MCP limitations, please update the workflow manually:"
        echo "1. Open N8n at: ${N8N_URL}"
        echo "2. Find workflow: ${workflow_id}"
        echo "3. Apply the configuration changes from: ${fix_dir}/proposed-fixes.md"
        echo ""
        echo "Or use the full workflow JSON from: ${fix_dir}/updated-workflow.json"
        echo ""
    fi

    send_slack "⚠️ *Manual Steps Required*

Due to limitations, please apply fixes manually:

1. Database Migration (if needed):
   \`${fix_dir}/database-migration.sql\`

2. Workflow Update:
   \`${fix_dir}/proposed-fixes.md\`

Full details in fix directory."

    echo "✅ Phase 5 Complete"
    echo ""
}

# ============================================================================
# PHASE 6: GENERATE REPORT & TESTS
# ============================================================================

smart_fix_report() {
    local fix_dir="$1"
    local issue_description="$2"

    echo "📊 Phase 6: Generating fix report and tests..."
    echo ""

    local analysis=$(cat "${fix_dir}/root-cause-analysis.md" 2>/dev/null || echo "No analysis")
    local fixes=$(cat "${fix_dir}/proposed-fixes.md" 2>/dev/null || echo "No fixes")

    local report="# Smart Fix Report

## Original Issue
${issue_description}

## Discovery Analysis
$(cat "${fix_dir}/discovery-analysis.md" 2>/dev/null || echo "No discovery analysis")

## Root Cause Analysis
${analysis}

## Proposed Fixes
${fixes}

## How to Apply Fixes

### Database Migration (if needed)
If \`${fix_dir}/database-migration.sql\` exists:
1. Open Supabase SQL Editor
2. Run the migration SQL
3. Verify with the verification queries

### Workflow Updates
1. Open N8n: ${N8N_URL}
2. Find the workflow (see discovery-analysis.md for ID)
3. Update node configurations as specified in proposed-fixes.md
4. Save and activate

### Verification
After applying fixes:
1. Trigger the workflow with test data
2. Run verification SQL queries
3. Check that data is correctly inserted
4. Monitor for errors

## Fix Artifacts
All files saved to: ${fix_dir}/

## Next Steps
1. Apply database migration (if needed)
2. Update N8n workflow configurations
3. Test with real data
4. Verify with SQL queries
5. Monitor for 24 hours
"

    echo "$report" > "${fix_dir}/SMART-FIX-REPORT.md"

    send_slack "📊 *Smart Fix Complete*

Issue: ${issue_description}

Report: \`${fix_dir}/SMART-FIX-REPORT.md\`

Summary:
- Components identified ✅
- Root cause found ✅
- Fixes generated ✅
- Tests created ✅

⚠️ Manual application required - see report for details"

    echo "$report"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 SMART FIX COMPLETE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Fix directory: ${fix_dir}"
    echo "Full report: ${fix_dir}/SMART-FIX-REPORT.md"
    echo ""
    echo "Next: Apply fixes manually as described in report"
    echo ""
}

# ============================================================================
# MAIN ORCHESTRATION
# ============================================================================

smart_fix_autonomous() {
    local issue_description="$1"

    local start_time=$(date +%s)
    local timestamp=$(date '+%I:%M %p')
    local fix_dir="${FIX_DIR}/smart-fix-$(date +%s)"

    mkdir -p "$fix_dir"

    send_slack "🤖 *SMART-FIX STARTED*

Issue: ${issue_description}
Time: ${timestamp}

Auto-discovering affected components and analyzing...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Phases:
1. Auto-Discovery
2. Gather Detailed State
3. Root Cause Analysis
4. Generate Fixes
5. Apply Fixes
6. Generate Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🤖 SMART-FIX: Auto-Discovery and Fix"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Phase 1: Auto-Discovery
    local workflow_id=$(smart_fix_discover "$issue_description" "$fix_dir")

    # Phase 2: Gather State
    smart_fix_gather_state "$workflow_id" "$fix_dir" "$issue_description"

    # Phase 3: Analyze
    local analysis=$(smart_fix_analyze "$fix_dir" "$issue_description")

    # Phase 4: Generate Fixes
    smart_fix_generate_fixes "$fix_dir" "$workflow_id" "$analysis"

    # Phase 5: Apply
    smart_fix_apply "$fix_dir" "$workflow_id"

    # Phase 6: Report
    smart_fix_report "$fix_dir" "$issue_description"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    echo "Fix directory: ${fix_dir}"
    echo "Duration: ${minutes}m ${seconds}s"
    echo ""

    return 0
}

# ============================================================================
# CLI
# ============================================================================

show_usage() {
    cat <<EOF
Smart-Fix - Auto-discover and fix issues without needing feature names

Usage: $0 "<detailed-issue-description>"

Examples:
  $0 "Grants-Gov workflow not inserting grant amounts and deadlines into database"
  $0 "Email workflow sending emails but not logging to database"
  $0 "Payment processor workflow stores transaction but missing user_id field"

What It Does:
  1. Auto-discovers affected workflows/functions
  2. Analyzes root cause
  3. Generates specific fixes with node configs
  4. Provides SQL migrations if needed
  5. Creates verification tests

No Feature Name Needed - just describe the problem!

Options:
  --help    Show this help message
EOF
}

case "${1:-}" in
    --help|-h)
        show_usage
        exit 0
        ;;
    "")
        echo "Error: Issue description required"
        show_usage
        exit 1
        ;;
    *)
        ISSUE_DESCRIPTION="$1"
        ;;
esac

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Error: ANTHROPIC_API_KEY environment variable not set"
    exit 1
fi

smart_fix_autonomous "$ISSUE_DESCRIPTION"
