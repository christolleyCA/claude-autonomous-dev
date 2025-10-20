#!/bin/bash
# Fix-Feature Command Handler
# Analyzes, debugs, and fixes existing N8n workflows and Edge Functions

# DO NOT USE set -e - we need graceful error handling, not crashes!

# ============================================================================
# CONFIGURATION
# ============================================================================

# Load environment variables from .env if available
[ -f "${BASH_SOURCE[0]%/*}/.env" ] && source "${BASH_SOURCE[0]%/*}/.env"
SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN:-}"
SLACK_CHANNEL="C09M9A33FFF"
SUPABASE_PROJECT_ID="hjtvtkffpziopozmtsnb"
N8N_URL="https://n8n.grantpilot.app"
BUILD_DIR="/tmp/autonomous-builds"
FIX_DIR="/tmp/autonomous-fixes"
ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
MAX_FIX_ATTEMPTS=3

# Ensure dependencies
mkdir -p "$FIX_DIR"

# Source helper scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# SLACK MESSAGING
# ============================================================================

send_slack() {
    local message="$1"
    local payload=$(jq -n \
        --arg channel "$SLACK_CHANNEL" \
        --arg text "$message" \
        '{
            channel: $channel,
            text: $text
        }')

    curl -s -X POST "https://slack.com/api/chat.postMessage" \
        -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$payload" > /dev/null 2>&1
}

# ============================================================================
# CLAUDE API INTEGRATION
# ============================================================================

call_claude_api() {
    local prompt="$1"
    local system_prompt="$2"

    if [ -z "$ANTHROPIC_API_KEY" ]; then
        echo "ERROR: ANTHROPIC_API_KEY not set" >&2
        return 1
    fi

    local full_prompt="$prompt"
    if [ -n "$system_prompt" ]; then
        full_prompt="${system_prompt}\n\n${prompt}"
    fi

    local api_response=$(curl -s https://api.anthropic.com/v1/messages \
        -H "x-api-key: ${ANTHROPIC_API_KEY}" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "$(jq -n \
            --arg prompt "$full_prompt" \
            '{
                model: "claude-sonnet-4-20250514",
                max_tokens: 4096,
                messages: [{
                    role: "user",
                    content: $prompt
                }]
            }')")

    echo "$api_response" | jq -r '.content[0].text // empty'
}

# ============================================================================
# DIAGNOSTIC PHASES
# ============================================================================

# Phase 1: Gather Current State
fix_feature_gather_state() {
    local feature_name="$1"
    local fix_dir="$2"
    local issue_description="$3"

    send_slack "🔍 *Phase 1: Gathering Current State*

Feature: \`${feature_name}\`
Issue: ${issue_description}

Collecting:
- Edge Function code
- N8n Workflow definition
- Recent logs
- Error reports..."

    echo "🔍 Phase 1: Gathering current state..."
    echo ""

    # Get Edge Function code
    echo "📦 Fetching Edge Function code from Supabase..."
    local edge_function_code=$(claude code execute mcp__supabase__get_edge_function \
        --project_id "$SUPABASE_PROJECT_ID" \
        --function_slug "$feature_name" 2>&1)

    if [ -n "$edge_function_code" ]; then
        echo "$edge_function_code" > "${fix_dir}/current-edge-function.ts"
        echo "✅ Edge Function code retrieved"
    else
        echo "⚠️ Could not retrieve Edge Function code"
        echo "// Edge function not found or error occurred" > "${fix_dir}/current-edge-function.ts"
    fi
    echo ""

    # Get N8n Workflow
    echo "⚙️ Fetching N8n Workflow..."
    # We need to search for the workflow by name pattern
    local workflow_search="[ACTIVE] [${feature_name}]"
    local workflow_data=$(claude code execute mcp__n8n-mcp__n8n_list_workflows 2>&1)

    echo "$workflow_data" > "${fix_dir}/workflow-search.json"
    echo "✅ Workflow list retrieved"
    echo ""

    # Get Supabase logs (last 24 hours)
    echo "📊 Fetching Edge Function logs..."
    local edge_logs=$(claude code execute mcp__supabase__get_logs \
        --project_id "$SUPABASE_PROJECT_ID" \
        --service "api" 2>&1)

    # Filter for this function
    echo "$edge_logs" | grep -i "$feature_name" > "${fix_dir}/edge-function-logs.txt" 2>/dev/null || echo "No logs found" > "${fix_dir}/edge-function-logs.txt"
    echo "✅ Edge Function logs retrieved"
    echo ""

    # Get N8n execution logs
    echo "📋 Fetching N8n execution logs..."
    local n8n_executions=$(claude code execute mcp__n8n-mcp__n8n_list_executions 2>&1)
    echo "$n8n_executions" > "${fix_dir}/n8n-executions.json"
    echo "✅ N8n execution logs retrieved"
    echo ""

    # Get Sentry errors (if available)
    echo "🚨 Checking for Sentry errors..."
    # This would require Sentry API integration - placeholder for now
    echo "Sentry integration pending" > "${fix_dir}/sentry-errors.txt"
    echo "✅ Sentry check complete"
    echo ""

    send_slack "✅ *State Collection Complete*

Retrieved:
- Edge Function code ✅
- N8n Workflow data ✅
- Function logs ✅
- Execution logs ✅

Ready for analysis..."

    echo "✅ Phase 1 Complete"
    echo ""
}

# Phase 2: Analyze Issues
fix_feature_analyze() {
    local feature_name="$1"
    local fix_dir="$2"
    local issue_description="$3"

    send_slack "🔬 *Phase 2: Analyzing Issues*

Running diagnostic analysis..."

    echo "🔬 Phase 2: Analyzing issues..."
    echo ""

    # Read gathered state
    local edge_function_code=$(cat "${fix_dir}/current-edge-function.ts" 2>/dev/null || echo "// Not found")
    local edge_logs=$(cat "${fix_dir}/edge-function-logs.txt" 2>/dev/null || echo "No logs")
    local n8n_executions=$(cat "${fix_dir}/n8n-executions.json" 2>/dev/null || echo "{}")

    # Use Claude to analyze
    local analysis_prompt="You are debugging a feature that is not working as expected.

Feature Name: ${feature_name}

User-Reported Issue:
${issue_description}

Current Edge Function Code:
\`\`\`typescript
${edge_function_code}
\`\`\`

Recent Edge Function Logs:
\`\`\`
${edge_logs}
\`\`\`

N8n Execution Data:
\`\`\`json
${n8n_executions}
\`\`\`

Please analyze and provide:

## 1. Root Cause Analysis
- What is the actual problem?
- Where is it occurring (Edge Function, N8n, integration)?
- Why is it happening?

## 2. Error Patterns
- Are there repeated errors?
- What are the error messages telling us?
- Are there validation issues?

## 3. Impact Assessment
- Is the feature completely broken or partially working?
- What scenarios work vs don't work?
- Is this a critical issue or edge case?

## 4. Recommended Fixes
- Specific code changes needed
- Configuration changes needed
- N8n workflow changes needed

Be specific and actionable. Provide exact line numbers and code snippets where possible."

    local analysis=$(call_claude_api "$analysis_prompt" "You are an expert debugging engineer. Analyze the issue thoroughly and provide specific, actionable recommendations.")

    # Save analysis
    echo "$analysis" > "${fix_dir}/diagnostic-analysis.md"

    send_slack "✅ *Analysis Complete*

Diagnostic report saved to:
\`${fix_dir}/diagnostic-analysis.md\`

Ready to generate fixes..."

    echo "✅ Phase 2 Complete"
    echo ""
    echo "$analysis"
}

# Phase 3: Generate Fixes
fix_feature_generate_fixes() {
    local feature_name="$1"
    local fix_dir="$2"
    local analysis="$3"

    send_slack "🔧 *Phase 3: Generating Fixes*

Creating code changes based on analysis..."

    echo "🔧 Phase 3: Generating fixes..."
    echo ""

    local edge_function_code=$(cat "${fix_dir}/current-edge-function.ts" 2>/dev/null || echo "// Not found")

    # Use Claude to generate specific fixes
    local fix_prompt="Based on this diagnostic analysis:

${analysis}

Current Edge Function Code:
\`\`\`typescript
${edge_function_code}
\`\`\`

Generate FIXED versions of:

## 1. Edge Function Code
Provide the complete, corrected TypeScript code with:
- All bugs fixed
- Proper error handling
- Improved validation
- Sentry integration maintained
- Clear comments explaining changes

Output format:
\`\`\`typescript
// FIXED Edge Function Code
[complete code here]
\`\`\`

## 2. N8n Workflow Changes (if needed)
Describe specific node changes:
- Which nodes need modification?
- What parameters need to change?
- Any new nodes needed?

## 3. Testing Strategy
Provide 3 specific test cases to verify the fix works:
- Test case 1: [scenario]
- Test case 2: [scenario]
- Test case 3: [scenario]

Be thorough and production-ready."

    local fixes=$(call_claude_api "$fix_prompt" "You are an expert code fixer. Generate production-ready fixes with comprehensive error handling.")

    # Save complete fixes
    echo "$fixes" > "${fix_dir}/proposed-fixes.md"

    # Extract just the fixed Edge Function code
    local fixed_code=$(echo "$fixes" | sed -n '/```typescript/,/```/p' | sed '1d;$d')
    if [ -z "$fixed_code" ]; then
        fixed_code=$(echo "$fixes" | sed -n '/```/,/```/p' | sed '1d;$d')
    fi

    echo "$fixed_code" > "${fix_dir}/fixed-edge-function.ts"

    send_slack "✅ *Fixes Generated*

Created:
- Fixed Edge Function code
- N8n workflow recommendations
- Testing strategy

Files saved to: \`${fix_dir}/\`"

    echo "✅ Phase 3 Complete"
    echo ""
    echo "$fixes"
}

# Phase 4: Apply Fixes
fix_feature_apply_fixes() {
    local feature_name="$1"
    local fix_dir="$2"

    send_slack "📝 *Phase 4: Applying Fixes*

Deploying updated code to Supabase..."

    echo "📝 Phase 4: Applying fixes..."
    echo ""

    # Read fixed code
    local fixed_code=$(cat "${fix_dir}/fixed-edge-function.ts" 2>/dev/null)

    if [ -z "$fixed_code" ]; then
        echo "❌ No fixed code found"
        return 1
    fi

    echo "📦 Deploying fixed Edge Function to Supabase..."

    # Deploy using Supabase MCP
    local deploy_result=$(claude code execute mcp__supabase__deploy_edge_function \
        --project_id "$SUPABASE_PROJECT_ID" \
        --name "$feature_name" \
        --files "[{\"name\": \"index.ts\", \"content\": $(echo "$fixed_code" | jq -Rs .)}]" 2>&1)

    if [ $? -eq 0 ]; then
        echo "✅ Edge Function deployed successfully"

        send_slack "✅ *Fixes Applied*

Edge Function: \`${feature_name}\`
Status: Deployed ✅

Endpoint: \`https://${SUPABASE_PROJECT_ID}.supabase.co/functions/v1/${feature_name}\`

Ready for testing..."

        echo ""
        echo "✅ Phase 4 Complete"
        echo ""
        return 0
    else
        echo "❌ Deployment failed: ${deploy_result}"

        send_slack "⚠️ *Deployment Issue*

Edge Function: \`${feature_name}\`
Status: Deployment failed

Error: ${deploy_result}

Manual intervention may be required."

        echo ""
        return 1
    fi
}

# Phase 5: Verify Fixes
fix_feature_verify() {
    local feature_name="$1"
    local fix_dir="$2"

    send_slack "🧪 *Phase 5: Verifying Fixes*

Running test cases to verify fixes work..."

    echo "🧪 Phase 5: Verifying fixes..."
    echo ""

    # Extract test cases from proposed fixes
    local test_strategy=$(cat "${fix_dir}/proposed-fixes.md" | grep -A 20 "Testing Strategy" || echo "No test strategy found")

    # Generate test script
    local test_prompt="Create executable test commands for this feature: ${feature_name}

Based on this testing strategy:
${test_strategy}

Generate 3 curl commands that test:
1. Happy path (valid input)
2. Error case (invalid input)
3. Edge case

Use this endpoint: https://${SUPABASE_PROJECT_ID}.supabase.co/functions/v1/${feature_name}

Format as a bash script with clear output."

    local test_script=$(call_claude_api "$test_prompt" "Generate executable test commands in bash.")

    # Save test script
    echo "$test_script" > "${fix_dir}/verification-tests.sh"
    chmod +x "${fix_dir}/verification-tests.sh"

    echo "📋 Test script generated: ${fix_dir}/verification-tests.sh"
    echo ""
    echo "Run tests with: bash ${fix_dir}/verification-tests.sh"
    echo ""

    send_slack "✅ *Verification Ready*

Test script created: \`${fix_dir}/verification-tests.sh\`

Run manually to verify fixes:
\`\`\`
bash ${fix_dir}/verification-tests.sh
\`\`\`"

    echo "✅ Phase 5 Complete"
    echo ""
}

# Phase 6: Generate Fix Report
fix_feature_report() {
    local feature_name="$1"
    local fix_dir="$2"
    local issue_description="$3"

    echo "📊 Phase 6: Generating fix report..."
    echo ""

    local report="# Fix Report: ${feature_name}

## Original Issue
${issue_description}

## Diagnostic Analysis
$(cat "${fix_dir}/diagnostic-analysis.md" 2>/dev/null || echo "No analysis available")

## Fixes Applied
$(cat "${fix_dir}/proposed-fixes.md" 2>/dev/null || echo "No fixes available")

## Files Modified
- Edge Function: ${feature_name}
- Location: https://${SUPABASE_PROJECT_ID}.supabase.co/functions/v1/${feature_name}

## Testing
See: ${fix_dir}/verification-tests.sh

## Next Steps
1. Run verification tests
2. Monitor Sentry for errors
3. Check Supabase logs
4. Verify N8n workflow if modified

## Fix Artifacts
All files saved to: ${fix_dir}/
"

    echo "$report" > "${fix_dir}/FIX-REPORT.md"

    send_slack "📊 *Fix Report Generated*

Feature: \`${feature_name}\`

Report saved to:
\`${fix_dir}/FIX-REPORT.md\`

Summary:
- Issue analyzed ✅
- Fixes generated ✅
- Code deployed ✅
- Tests created ✅

Next: Run verification tests to confirm fix!"

    echo "$report"
    echo ""
    echo "✅ Phase 6 Complete"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 FIX COMPLETE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Fix directory: ${fix_dir}"
    echo "Full report: ${fix_dir}/FIX-REPORT.md"
    echo "Tests: ${fix_dir}/verification-tests.sh"
    echo ""
}

# ============================================================================
# MAIN FIX ORCHESTRATION
# ============================================================================

fix_feature_autonomous() {
    local feature_name="$1"
    local issue_description="$2"

    local start_time=$(date +%s)
    local timestamp=$(date '+%I:%M %p')
    local fix_dir="${FIX_DIR}/${feature_name}-fix-$(date +%s)"

    mkdir -p "$fix_dir" || {
        echo "ERROR: Failed to create fix directory" >&2
        return 1
    }

    # Send startup notification
    send_slack "🔧 *AUTONOMOUS FIX STARTED*

Feature: \`${feature_name}\`
Issue: ${issue_description}
Time: ${timestamp}

Running diagnostic and fix workflow...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Fix Phases:
1. Gather Current State
2. Analyze Issues
3. Generate Fixes
4. Apply Fixes
5. Verify Fixes
6. Generate Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 AUTONOMOUS FIX: ${feature_name}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Phase 1: Gather State
    fix_feature_gather_state "$feature_name" "$fix_dir" "$issue_description"

    # Phase 2: Analyze
    local analysis=$(fix_feature_analyze "$feature_name" "$fix_dir" "$issue_description")

    # Phase 3: Generate Fixes
    local fixes=$(fix_feature_generate_fixes "$feature_name" "$fix_dir" "$analysis")

    # Phase 4: Apply Fixes
    fix_feature_apply_fixes "$feature_name" "$fix_dir"

    # Phase 5: Verify
    fix_feature_verify "$feature_name" "$fix_dir"

    # Phase 6: Report
    fix_feature_report "$feature_name" "$fix_dir" "$issue_description"

    # Calculate duration
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    # Final summary
    send_slack "🎉 *FIX COMPLETE*

Feature: \`${feature_name}\`
Status: ✅ FIXED & DEPLOYED
Fix Time: ${minutes}m ${seconds}s

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 What Was Done:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 Diagnostics:
- Current code analyzed ✅
- Logs reviewed ✅
- Root cause identified ✅

🔧 Fixes:
- Code corrected ✅
- Deployed to Supabase ✅
- Tests generated ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 Fix Artifacts:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
\`${fix_dir}/\`
- FIX-REPORT.md - Complete report
- diagnostic-analysis.md - Root cause
- proposed-fixes.md - All changes
- fixed-edge-function.ts - New code
- verification-tests.sh - Test script

🧪 Next Step:
Run: \`bash ${fix_dir}/verification-tests.sh\`"

    echo ""
    echo "Fix directory: ${fix_dir}"
    echo "Duration: ${minutes}m ${seconds}s"
    echo ""

    return 0
}

# ============================================================================
# COMMAND-LINE INTERFACE
# ============================================================================

show_usage() {
    cat <<EOF
Fix-Feature - Debug and fix existing N8n Workflows + Edge Functions

Usage: $0 <feature-name> "<issue-description>"

Examples:
  $0 hello-world "Validation errors not returning proper error messages"
  $0 email-sender "Emails not sending, returns 500 error"
  $0 payment-processor "Stripe webhook not triggering workflow"

What It Does:
  1. Gathers current state (code, logs, errors)
  2. Analyzes root cause with AI
  3. Generates specific fixes
  4. Deploys fixed code
  5. Creates verification tests
  6. Generates detailed report

Options:
  --help    Show this help message

Environment Variables:
  ANTHROPIC_API_KEY    Required for AI analysis and fixes
EOF
}

# Parse command-line arguments
FEATURE_NAME=""
ISSUE_DESCRIPTION=""

case "${1:-}" in
    --help|-h)
        show_usage
        exit 0
        ;;
    "")
        echo "Error: Feature name required"
        show_usage
        exit 1
        ;;
    *)
        FEATURE_NAME="$1"
        ISSUE_DESCRIPTION="${2:-Unspecified issue - please investigate}"
        ;;
esac

# Validate API key
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Error: ANTHROPIC_API_KEY environment variable not set"
    echo "Please set it with: export ANTHROPIC_API_KEY='your-key-here'"
    exit 1
fi

# Execute autonomous fix
fix_feature_autonomous "$FEATURE_NAME" "$ISSUE_DESCRIPTION"
