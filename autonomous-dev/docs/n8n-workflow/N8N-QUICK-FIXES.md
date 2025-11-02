# N8N Quick Fix Cheat Sheet

## Error: "Maximum call stack size exceeded"
**Cause:** UPDATE operation on large sheet
**Fix:**
```bash
jq '.nodes[] | select(.name == "Update Sheets") | .parameters.operation = "append"' workflow.json
```

## Error: "Cannot read properties of undefined (reading 'disabled')"
**Cause:** Dangling connections to deleted nodes
**Fix:**
```bash
# Find dangling connections
jq '.connections | keys' workflow.json > connections.txt
jq '.nodes[].name' workflow.json > nodes.txt
# Remove any connection not in nodes list
```

## Error: "Could not get parameter"
**Cause:** Wrong column format in Google Sheets
**Fix:**
```javascript
// Change from:
"columns": { "value": { "Name": "={{$json.Name}}" }}
// To:
"columns": { "value": [{ "column": "Name", "fieldValue": "={{$json.Name}}" }]}
```

## Error: "request/body must NOT have additional properties"
**Cause:** Extra metadata in deployment
**Fix:**
```bash
jq '{name, nodes, connections, settings}' workflow.json > deploy.json
```

## Error: "this.getCredentials is not a function"
**Cause:** Code node can't access OAuth2
**Fix:** Use native Google Sheets node instead of Code node

## Error: Empty response from Gemini
**Cause:** Wrong field reference
**Fix:**
```javascript
const text = response.output || response.text;  // Check both
```

## Validation One-Liner
```bash
jq -r '.connections | to_entries[] | .value | to_entries[] | .value[][] | .node' wf.json | sort -u | while read n; do jq -e ".nodes[] | select(.name == \"$n\")" wf.json > /dev/null || echo "Missing: $n"; done
```

## Deploy One-Liner
```bash
curl -sX PUT "https://n8n.grantpilot.app/api/v1/workflows/ID" -H "X-N8N-API-KEY: KEY" -H "Content-Type: application/json" -d "$(jq '{name,nodes,connections,settings}' wf.json)" | jq '.updatedAt'
```

## Test with 1 Row
```javascript
// Add to Filter node
const testMode = true;  // Toggle for testing
const batchSize = testMode ? 1 : 10;
return rows.slice(0, batchSize);
```

## Emergency Reset
```bash
# Download clean version
curl -s "URL/api/v1/workflows/ID" -H "X-N8N-API-KEY: KEY" > backup.json
# Remove all connections
jq '.connections = {}' backup.json > reset.json
# Manually reconnect in UI
```

---
Remember: **Download JSON first, inspect structure, THEN try fixes**