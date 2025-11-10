# N8N API Deployment Guide
*Session: 2025-11-02 - API Key Management & Deployment Best Practices*

## Critical Lessons: API Key Management

### Problem: API Key Rotation
**Issue:** N8N API keys kept returning "unauthorized" errors during workflow operations.

**Root Cause:** API keys can expire/rotate without notice. Stale keys in documentation cause repeated failures.

**Solution:**
1. **Always request fresh API key** when encountering "unauthorized" errors
2. **Update ALL documentation immediately** - don't proceed until updated
3. **Test connectivity first** before attempting complex operations
4. **Document single source of truth** for credentials

### Finding All API Key References
```bash
# Find all files containing old API key
grep -r "OLD_API_KEY_PATTERN" ~/autonomous-dev/ --include="*.md" --include="*.sh" -l

# Example for our workflow
grep -r "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4MjczNjA3Yy0w" ~/autonomous-dev/ -l
```

### Single Source of Truth
Store current API key in: `autonomous-dev/docs/n8n-workflow/YOUR-WORKFLOW-SPECIFICS.md`

All other references should use environment variables or reference this file.

---

## N8N API Deployment Process

### Step 1: Retrieve Current Workflow
```bash
N8N_API_KEY="your-api-key-here"
WORKFLOW_ID="pc1cMXkDsrWlOpKu"

curl -s "https://n8n.grantpilot.app/api/v1/workflows/${WORKFLOW_ID}" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  > workflow-original.json
```

### Step 2: Validate Workflow Structure
**Always validate before deployment!**

```bash
# Create validation script
cat > validate-workflow.sh << 'EOF'
#!/bin/bash
WORKFLOW_FILE="$1"

echo "=== Validating Workflow ==="

# Get all node names
jq -r '.nodes[].name' "$WORKFLOW_FILE" | sort > /tmp/all-nodes.txt

# Get all connection targets
jq -r '
  .connections
  | to_entries[]
  | .value
  | to_entries[]
  | .value[][]
  | select(.node)
  | .node
' "$WORKFLOW_FILE" | sort -u > /tmp/connection-targets.txt

# Find dangling connections
echo "🔍 Checking for Dangling Connections..."
comm -13 /tmp/all-nodes.txt /tmp/connection-targets.txt > /tmp/dangling.txt

if [ -s /tmp/dangling.txt ]; then
  echo "❌ DANGLING CONNECTIONS FOUND:"
  cat /tmp/dangling.txt
  exit 1
else
  echo "✅ No dangling connections found!"
fi
EOF

chmod +x validate-workflow.sh
./validate-workflow.sh workflow-original.json
```

### Step 3: Clean Workflow for Deployment
**Critical:** Remove ALL read-only properties

```bash
# Properties that MUST be removed:
# - createdAt, updatedAt (timestamps)
# - isArchived, shared, tags (metadata)
# - triggerCount, meta, versionId (runtime data)
# - id (identifier - set in URL instead)
# - staticData, pinData (test data)
# - active (use PATCH separately)

jq '{name, nodes, connections, settings}' workflow-original.json > workflow-deploy.json
```

**Only these 4 properties allowed for PUT:**
- `name` (string)
- `nodes` (array)
- `connections` (object)
- `settings` (object)

### Step 4: Deploy Workflow
```bash
curl -sX PUT "https://n8n.grantpilot.app/api/v1/workflows/${WORKFLOW_ID}" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  -H "Content-Type: application/json" \
  -d @workflow-deploy.json \
  | jq '{id, name, active, nodeCount: (.nodes | length), updatedAt}'
```

**Expected Response:**
```json
{
  "id": "pc1cMXkDsrWlOpKu",
  "name": "NFP Website Finder - Instance 1",
  "active": false,
  "nodeCount": 21,
  "updatedAt": "2025-11-02T15:36:53.970Z"
}
```

### Step 5: Activate Workflow (Optional)
```bash
# Activate workflow to start automatic execution
curl -sX PATCH "https://n8n.grantpilot.app/api/v1/workflows/${WORKFLOW_ID}" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"active": true}' \
  | jq '{id, name, active}'
```

---

## Common Deployment Errors

### Error: "request/body must NOT have additional properties"
**Cause:** Payload contains read-only properties

**Solution:** Use clean payload with only `{name, nodes, connections, settings}`

### Error: "request/body/active is read-only"
**Cause:** Trying to set `active` flag in PUT request

**Solution:** Use PATCH method separately after deployment

### Error: "unauthorized"
**Cause:** API key expired or invalid

**Solution:**
1. Request fresh API key from user
2. Update YOUR-WORKFLOW-SPECIFICS.md
3. Test with simple GET request
4. Retry deployment

### Error: "Cannot read properties of undefined (reading 'disabled')"
**Cause:** Dangling connections to deleted nodes

**Solution:** Run validation script before deployment

---

## Workflow Configuration Verification

### Check Critical Nodes
```bash
# Verify Gemini model
jq '.nodes[] | select(.name == "Gemini Chat Model") | {name, modelName: .parameters.modelName}' workflow.json

# Verify Append node column format (MUST be array)
jq '.nodes[] | select(.name == "Append to ProcessedResults") | .parameters.columns' workflow.json

# Verify Read node filters
jq '.nodes[] | select(.name == "Read All Rows") | .parameters.filtersUI' workflow.json
```

### Expected Configurations

**Gemini Model (User Preference):**
```json
{
  "name": "Gemini Chat Model",
  "modelName": "models/gemini-2.5-pro"
}
```

**Append Node (Array Format - Critical!):**
```json
{
  "mappingMode": "defineBelow",
  "value": [
    {"column": "EIN", "fieldValue": "={{ $json.EIN }}"},
    {"column": "Name", "fieldValue": "={{ $json.Name }}"}
  ]
}
```

**NOT** object format (this will fail):
```json
{
  "mappingMode": "defineBelow",
  "value": {
    "EIN": "={{ $json.EIN }}",
    "Name": "={{ $json.Name }}"
  }
}
```

---

## Best Practices

### 1. Always Test API Connectivity First
```bash
# Simple health check
curl -s "https://n8n.grantpilot.app/api/v1/workflows/${WORKFLOW_ID}" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  | jq '{id, name, active}'
```

If this fails with "unauthorized", **STOP** and get new API key.

### 2. Validate Before Deploy
Never skip the validation step. Dangling connections are silent killers.

### 3. Keep Credentials Updated
Update YOUR-WORKFLOW-SPECIFICS.md immediately when credentials change.

### 4. Use Version Control
```bash
# Save workflow versions
curl -s "https://n8n.grantpilot.app/api/v1/workflows/${WORKFLOW_ID}" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  > "workflow-backup-$(date +%Y%m%d-%H%M%S).json"
```

### 5. Test Before Activating
Always test workflow manually before activating automatic execution.

---

## Quick Reference Commands

```bash
# Set variables
export N8N_API_KEY="your-key-here"
export WORKFLOW_ID="pc1cMXkDsrWlOpKu"
export N8N_URL="https://n8n.grantpilot.app"

# Get workflow
curl -s "${N8N_URL}/api/v1/workflows/${WORKFLOW_ID}" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  > workflow.json

# Validate
./validate-workflow.sh workflow.json

# Clean for deployment
jq '{name, nodes, connections, settings}' workflow.json > workflow-clean.json

# Deploy
curl -sX PUT "${N8N_URL}/api/v1/workflows/${WORKFLOW_ID}" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  -H "Content-Type: application/json" \
  -d @workflow-clean.json

# Activate
curl -sX PATCH "${N8N_URL}/api/v1/workflows/${WORKFLOW_ID}" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"active": true}'
```

---

## Verified Working Configuration (2025-11-02)

- **Workflow ID:** pc1cMXkDsrWlOpKu
- **Name:** NFP Website Finder - Instance 1
- **Nodes:** 21 (all validated, no dangling connections)
- **Trigger:** Schedule - "Run Every Minute"
- **Model:** gemini-2.5-pro (user preference)
- **Batch Size:** 10 rows
- **Target:** 23,871 nonprofits (Public Facing=True)
- **Processing Rate:** ~600/hour when active
- **Status:** Deployed successfully, ready for activation

---

*Last Updated: 2025-11-02 15:40 UTC*
*Session: Opus 4.1 - API Key Management Resolution*
