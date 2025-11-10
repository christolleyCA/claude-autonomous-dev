# N8N Webhook API Limitation

## Problem

The N8N REST API consistently strips webhook node parameters during PUT/deployment operations.

## Evidence

**Date**: 2025-11-02
**Workflow ID**: pc1cMXkDsrWlOpKu
**Attempts**: 5+ deployment attempts

### What Happens
1. Webhook node configured with:
   ```json
   {
     "path": "nfp-website-finder-instance-1",
     "responseMode": "onReceived",
     "options": {"httpMethod": "GET,POST"}
   }
   ```

2. Deploy via API: `PUT /api/v1/workflows/{id}`

3. After deployment, parameters become:
   ```json
   {
     "path": null,
     "responseMode": null,
     "options": null
   }
   ```

4. Result: Webhook returns HTTP 404

## Tested Approaches (All Failed)

1. ✗ Deployment format with only name/nodes/connections/settings
2. ✗ Complete workflow JSON with all original fields
3. ✗ Using typeVersion 2 explicitly
4. ✗ Multiple deployment formats and variations

## Root Cause

N8N API likely treats webhook configuration as "runtime" or "activation" state rather than persistent configuration. The API may require separate webhook registration/activation endpoints that are not publicly documented.

## Solution

**Manual UI Configuration Required**

Users must:
1. Open N8N workflow in UI
2. Click on Webhook Trigger node
3. Manually set:
   - **Path**: `nfp-website-finder-instance-1`
   - **Response Mode**: `On Received` (onReceived)
   - **HTTP Method**: `GET, POST` (in Options)
4. Save workflow
5. Toggle workflow active (if needed)

## Impact

This limitation prevents fully autonomous workflow deployment and testing. Workflows with webhook triggers require manual configuration steps in the UI after API-based deployment.

## Recommendation

For autonomous development systems:
- Use manual trigger nodes for testing when possible
- Document required manual UI steps for webhooks
- Consider alternative approaches like scheduled triggers
- Report this limitation to N8N team for API enhancement

## References

- Previous session documentation: AUTONOMOUS-TESTING-WORKFLOW.md
- N8N API Docs: https://docs.n8n.io/api/
- Workflow: NFP Website Finder - Instance 1
