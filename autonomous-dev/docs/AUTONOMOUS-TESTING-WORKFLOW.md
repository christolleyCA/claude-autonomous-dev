# Autonomous N8N Workflow Testing - Lessons Learned
*Session: 2025-11-02 20:45-20:55 UTC*

## Goal
Create a fully autonomous test-fix-verify cycle for N8N workflows that:
1. Triggers workflow via webhook
2. Checks N8N execution logs
3. Checks Sentry for events
4. Verifies Google Sheet results
5. Diagnoses issues and fixes automatically
6. Repeats until working

## Critical Discoveries

### 1. Webhook HTTP Method Configuration
**Problem:** N8N webhook nodes default to GET-only. POST requests return 404.

**Solution:**
```javascript
// Webhook node parameters
{
  "path": "workflow-path-here",
  "responseMode": "lastNode",
  "options": {
    "httpMethod": "POST"  // or "GET,POST" for both
  }
}
```

**Key Learning:** After changing webhook configuration, the workflow MUST be deactivated and reactivated for changes to take effect. API deployment alone is insufficient.

### 2. N8N API Activation Limitations
**Problem:** `PATCH /api/v1/workflows/{id}` with `{"active": true}` doesn't properly activate webhooks.

**Workaround:** Must activate via UI:
1. Go to workflow in N8N UI
2. Toggle switch off, then on
3. Webhook will then be registered

**This blocks fully autonomous testing** - requires manual intervention.

### 3. Column Schema Evolution (v4.5+)
**Problem:** Google Sheets node v4.5 requires BOTH `value` array AND `schema` array.

**Working Format:**
```json
{
  "mappingMode": "defineBelow",
  "value": [
    {"column": "EIN", "fieldValue": "={{ $json.EIN }}"}
  ],
  "schema": [
    {"id": "EIN", "displayName": "EIN", "type": "string", "required": false}
  ]
}
```

**Broken Format** (what was deployed):
```json
{
  "mappingMode": "defineBelow",
  "value": [null, null, ...],
  "schema": [...]
}
```

### 4. Sentry Configuration Flow
**Problem:** `startTime` undefined in Prepare Batch Completed node.

**Root Cause:** Sentry config needs to flow through:
- Initialize Sentry (creates startTime)
- Filter Pending Rows (adds to each row as `_sentry`)
- Build CSV Input (passes as `sentryConfig`)
- Parse Response (preserves in results)
- Prepare Batch Completed (accesses via `$input.all()[0].json._sentry`)

**Fix Applied:** Ensured `startTime` is in Initialize Sentry output.

### 5. N8N Execution API Limitations
**Problem:** Execution details API doesn't return meaningful error information.

**API Response:**
```json
{
  "id": "95250",
  "status": "error",
  "error": null  // Always null!
}
```

**Workaround:** Must check Sentry logs or manually inspect workflow in UI.

### 6. Sentry MCP Issues
**Problem:** `search_events` and `search_issues` tools return schema errors.

**Error:**
```
Invalid schema for response_format 'response': In context=(),
'required' is required to be supplied and to be an array
including every key in properties. Missing 'query'.
```

**Impact:** Cannot autonomously verify Sentry events via MCP.

**Workaround:** Check Sentry UI manually or use direct API calls.

### 7. AI Language Model Connection Loss
**Problem:** When deploying workflow via API, AI language model connections can be lost.

**Symptoms:**
- Workflow deployed successfully via API
- Connections object shows empty ai_languageModel array: `"ai_languageModel": [[]]`
- Workflow fails immediately when triggered

**Root Cause:** AI model connections use a special connection type (`ai_languageModel`) that connects FROM the model TO the calling node. When filtering/modifying the connections object, this can be accidentally removed.

**Correct Format:**
```json
{
  "connections": {
    "Gemini Chat Model": {
      "ai_languageModel": [
        [
          {
            "node": "Call Gemini",
            "type": "ai_languageModel",
            "index": 0
          }
        ]
      ]
    }
  }
}
```

**Fix:** Always preserve the AI model connections when modifying workflow via API. Use the original workflow's connections as base and only modify specific connections.

### 8. Webhook Response Mode Impact
**Problem:** When `responseMode: "lastNode"`, webhook waits for entire workflow to complete before responding. If workflow errors, webhook returns error message.

**Solution:** Set `responseMode: "onReceived"` for immediate response:
```json
{
  "parameters": {
    "path": "nfp-website-finder-instance-1",
    "responseMode": "onReceived",  // Respond immediately
    "options": {
      "httpMethod": "GET,POST"
    }
  }
}
```

**Benefit:** Workflow runs asynchronously after webhook responds, preventing timeout issues for long-running workflows.

## Current Workflow Status

**Last Deployed:** 2025-11-02 21:15:01 UTC
**Workflow ID:** pc1cMXkDsrWlOpKu
**Webhook Path:** `/nfp-website-finder-instance-1`
**Status:** Webhook responding but workflow execution inconsistent

**Issues Fixed:**
✅ Replaced Schedule trigger with Webhook trigger
✅ Fixed column schema format (added both value + schema arrays)
✅ Fixed Sentry config flow (startTime now preserved)
✅ Removed orphaned Webhook Response node
✅ Changed webhook responseMode to "onReceived" for immediate response
✅ Fixed AI language model connection (Gemini Chat Model → Call Gemini)
✅ Webhook now accepts GET requests and returns HTTP 200

**Issues Discovered:**
⚠️ Workflow execution is highly inconsistent:
  - Most executions fail in <10ms
  - One execution (95362) ran for 20 seconds before failing
  - Suggests race condition or timing issue
⚠️ N8N Execution API provides no error details for debugging
⚠️ Cannot autonomously verify via Sentry MCP (schema errors)
⚠️ Cannot access Google Sheets via WebFetch (requires different access method)

**Recent Executions:**
- 95372: Failed in 10ms (2025-11-02 21:16:55)
- 95365: Failed in 7ms (2025-11-02 21:15:38)
- 95362: Ran 20 seconds before failing (2025-11-02 21:15:18) ⚠️ ANOMALY
- 95353: Failed in 9ms (2025-11-02 21:13:25)

## Autonomous Testing Script (Partial)

```bash
#!/bin/bash
# Autonomous N8N Workflow Testing
#
# Usage: ./test-workflow.sh <workflow-id> <webhook-path>

WORKFLOW_ID="$1"
WEBHOOK_PATH="$2"
N8N_URL="https://n8n.grantpilot.app"
N8N_API_KEY="your-key-here"

echo "🚀 Triggering workflow..."
RESPONSE=$(curl -sX POST "${N8N_URL}/webhook/${WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{}')

echo "📊 Response: $RESPONSE"

# Wait for execution
sleep 10

# Get latest execution
echo "📋 Checking execution logs..."
EXECUTION=$(curl -s "${N8N_URL}/api/v1/executions?workflowId=${WORKFLOW_ID}&limit=1" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}")

echo "$EXECUTION" | jq '.data[0] | {id, status, stoppedAt}'

STATUS=$(echo "$EXECUTION" | jq -r '.data[0].status')

if [ "$STATUS" = "success" ]; then
  echo "✅ Workflow executed successfully"

  # TODO: Check Sentry for events
  # TODO: Verify Google Sheet results
  # TODO: Return success

elif [ "$STATUS" = "error" ]; then
  echo "❌ Workflow failed"

  # TODO: Diagnose error
  # TODO: Apply fix
  # TODO: Retry

fi
```

## Recommendations for Full Autonomy

### Short-term Workarounds:
1. **Manual UI activation step** after each deployment
2. **Direct Sentry API calls** instead of MCP
3. **Google Sheets API** instead of WebFetch

### Long-term Solutions:
1. **Fix N8N API** to properly activate webhooks
2. **Fix Sentry MCP** schema validation errors
3. **Add Google Sheets MCP** for autonomous verification
4. **Enhanced execution API** with actual error details

## Testing Workflow (Manual Steps Required)

**After Deployment:**
1. Go to N8N UI: https://n8n.grantpilot.app/workflow/pc1cMXkDsrWlOpKu
2. Toggle OFF then ON
3. Run: `curl -X POST https://n8n.grantpilot.app/webhook/nfp-website-finder-instance-1`
4. Check execution in UI
5. Check Sentry UI: https://oxfordshire-inc.sentry.io
6. Check Google Sheet: https://docs.google.com/spreadsheets/d/1bbwJfvO8kEFwXaQAAf9K_ZXMl3QWj3vzyvPxaQNUZk4

**Repeat until working.**

## Key Takeaways

1. **N8N API is limited** - doesn't support full workflow lifecycle automation
2. **Webhook configuration changes require UI reactivation** - API deployment insufficient
3. **Multi-tool verification needed** - N8N logs + Sentry + Google Sheets
4. **MCP tools have limitations** - Sentry search broken, no Sheets access
5. **Manual intervention still required** - cannot achieve 100% autonomy yet

## Future Implementation

To achieve true autonomy, need:
- Selenium/Playwright for N8N UI automation (toggle activation)
- Direct Sentry Ingest API integration (bypass MCP)
- Google Sheets API with service account (bypass WebFetch)
- Enhanced error handling and retry logic
- Automated workflow validation before deployment

---

## Session Summary (2025-11-02 21:00-21:20 UTC)

### What Worked
1. ✅ Webhook successfully configured and responds with HTTP 200
2. ✅ Workflow triggers and starts execution
3. ✅ AI language model connection issue identified and fixed
4. ✅ Webhook response mode changed to async execution

### What Didn't Work
1. ❌ Workflow execution highly inconsistent (fails in <10ms most times)
2. ❌ No access to detailed error logs from N8N API
3. ❌ Sentry MCP broken - cannot verify events autonomously
4. ❌ One execution ran 20 seconds (anomaly) but still failed

### Current Blockers for Full Autonomy
1. **No error visibility** - N8N API doesn't return error details
2. **Sentry MCP broken** - Schema validation errors prevent event checking
3. **No Google Sheets MCP** - Cannot verify results autonomously
4. **Inconsistent execution** - Race condition or timing issue suspected

### Next Steps (Requires Manual Intervention)
1. Check N8N UI for execution 95362 error details (the 20-second run)
2. Check Sentry UI for any captured events
3. Verify Google Sheets credentials are working
4. Consider adding error handling/logging to workflow nodes
5. Test workflow with manual trigger in N8N UI to isolate webhook vs workflow issues

### Autonomous Testing Status
**Current Capability:** ~40% autonomous
- ✅ Can deploy workflows
- ✅ Can trigger via webhook
- ✅ Can check execution status
- ❌ Cannot get error details
- ❌ Cannot verify Sentry events
- ❌ Cannot verify Google Sheets results
- ❌ Cannot diagnose root cause without UI access

**Required for 100% Autonomy:**
- Enhanced N8N Execution API with error details
- Working Sentry MCP or direct API integration
- Google Sheets MCP or API integration
- Selenium/Playwright for N8N UI automation

---

*Last Updated: 2025-11-02 21:20 UTC*
*Sessions: Initial attempt (20:45-20:55), Continued debugging (21:00-21:20)*
