# N8N Technical Patterns & Solutions

## Google Sheets at Scale

### Pattern: Append-to-Tracking Strategy
**When to Use:** Processing > 10,000 rows
**Why:** Avoids O(n) search operations that cause stack overflow

```javascript
// WRONG - Causes stack overflow at ~150K rows
{
  "operation": "update",
  "updateKey": "EIN",
  "columns": {...}  // Searches entire sheet
}

// CORRECT - O(1) operation
{
  "operation": "append",
  "sheetName": {
    "__rl": true,
    "mode": "name",  // Use "name" for new sheets without cached GID
    "value": "ProcessedResults"
  },
  "columns": {
    "mappingMode": "defineBelow",
    "value": [  // MUST be array, not object!
      { "column": "EIN", "fieldValue": "={{ $json.EIN }}" },
      { "column": "Name", "fieldValue": "={{ $json.Name }}" }
    ]
  }
}
```

### Pattern: Batch Processing with State Tracking
```
Main Sheet: Status=PENDING, Processor Assignment=0
Process: Read 10 → Process → Append to ProcessedResults
Backfill: VLOOKUP or Apps Script to merge results
```

## Connection Validation Pattern

### The Problem
N8N doesn't clean up connections when nodes are deleted, causing:
```
Cannot read properties of undefined (reading 'disabled')
```

### The Solution
```bash
#!/bin/bash
# validate-connections.sh

WORKFLOW_FILE=$1

# Extract all connection targets
jq -r '.connections | to_entries[] | .value | to_entries[] | .value[][] | select(.node != null) | .node' $WORKFLOW_FILE | sort -u > /tmp/targets.txt

# Extract all node names
jq -r '.nodes[].name' $WORKFLOW_FILE | sort -u > /tmp/nodes.txt

# Find dangling connections
echo "Dangling connections:"
comm -13 /tmp/nodes.txt /tmp/targets.txt

# Check for duplicate connections
echo "Checking for duplicate connections..."
jq -r '.connections | to_entries[] | "\(.key): " + (.value.main[0] | length | tostring) + " connections"' $WORKFLOW_FILE | grep -v ": 1 connections"
```

### Fix Dangling Connections
```javascript
// Remove completely
.connections |= del(."DeletedNodeName")

// Fix duplicates (keep only first)
.connections."NodeName".main[0] = [.connections."NodeName".main[0][0]]
```

## Deployment Patterns

### Clean Workflow for API Deploy
```javascript
// Required fields only
{
  "name": "Workflow Name",
  "nodes": [...],
  "connections": {...},
  "settings": {"executionOrder": "v1"}  // Often forgotten!
}

// Remove these before PUT
del(.createdAt, .updatedAt, .id, .isArchived, .shared, .tags, .versionId, .meta.templateCredsSetupCompleted)
```

### Deploy Script Pattern
```bash
#!/bin/bash
source /tmp/.n8n-credentials

# Clean workflow
jq '{name, nodes, connections, settings}' workflow.json > deploy.json

# Deploy
curl -s -X PUT "${N8N_API_URL}/api/v1/workflows/${WORKFLOW_ID}" \
  -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
  -H "Content-Type: application/json" \
  --data-binary @deploy.json | jq '.'
```

## Gemini AI Integration Patterns

### Working Configuration
```javascript
// Gemini Chat Model Node
{
  "name": "Gemini Chat Model",
  "type": "@n8n/n8n-nodes-langchain.lmChatGoogleGemini",
  "parameters": {
    "modelName": "models/gemini-2.0-flash-exp",  // 2.5-pro has issues
    "options": {
      "temperature": 0.1,  // Low for consistency
      "maxOutputTokens": 8000
    }
  }
}

// AI Chain Node
{
  "name": "Call Gemini",
  "type": "@n8n/n8n-nodes-langchain.chainLlm",
  "parameters": {
    "promptType": "define",
    "text": "={{ $json.prompt }}"
  }
}

// Parse Response
const response = $input.first().json;
const text = response.output || response.text;  // Check both fields
```

### CSV Pattern for AI Processing
```javascript
// Build CSV without headers, proper escaping
const csvRows = rows.map(item => {
  const row = item.json;
  const name = String(row.Name || '').replace(/"/g, '""');
  const city = String(row.City || '').replace(/"/g, '""');
  return `${row.EIN},"${name}","${city}",${row.State}`;
});
const csv = csvRows.join('\n');

// Parse AI response
response = response.replace(/```csv\n?/g, '').replace(/```\n?/g, '');
const lines = response.split('\n');
const startIdx = lines[0]?.includes('EIN') ? 1 : 0;  // Skip header if present
```

## Error Handling Patterns

### Sentry Integration
```javascript
// Initialize once, pass through workflow
const SENTRY_DSN = "https://KEY@HOST/PROJECT";
const match = SENTRY_DSN.match(/https:\/\/(.+)@(.+)\/(.+)/);
const endpoint = `https://${match[2]}/api/${match[3]}/store/`;

// Pass config through workflow
return [{
  json: {
    sentryEndpoint: endpoint,
    sentryAuth: `Sentry sentry_version=7, sentry_key=${match[1]}`,
    ...otherData,
    _sentry: sentryConfig  // Attach to each row
  }
}];
```

### Error Trigger Pattern
```
Error Trigger Node → Prepare Error → Send to Sentry → Mark Rows ERROR
                                                    ↓
                                            Extract Affected Rows
```

## Common Issues & Solutions

| Issue | Symptom | Solution |
|-------|---------|----------|
| Stack Overflow | "Maximum call stack size exceeded" | Use APPEND not UPDATE |
| Dangling Connections | "Cannot read properties of undefined" | Validate connections |
| Parameter Error | "Could not get parameter" | Check array vs object format |
| Deployment Failed | "additional properties" | Remove metadata fields |
| No Gemini Response | Empty output | Check output/text fields |
| Code Node Auth | "getCredentials is not function" | Use native nodes |

## Performance Guidelines

- **Batch Size:** 10 rows optimal for Gemini
- **Sheet Size:** UPDATE fails > 150K rows
- **Execution Time:** ~45 seconds for 21 nodes
- **Rate:** ~600 items/hour with 1-minute schedule
- **Memory:** Stable with APPEND strategy

## Debug Priority Order

1. **Structure Issues** (90% of problems)
   - Download JSON and inspect
   - Validate connections
   - Check parameter formats

2. **Runtime Issues** (8% of problems)
   - Test with 1 row
   - Check field names in expressions
   - Verify credentials

3. **External Issues** (2% of problems)
   - API limits
   - Network timeouts
   - Service availability

---
*Critical Insight: Most N8N errors are structural (connections, parameters) not logical. Always inspect the JSON first.*