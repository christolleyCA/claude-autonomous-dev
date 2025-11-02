# N8N Workflow Development - Knowledge Base
*Session: 2025-11-02 - NFP Website Finder Workflow*

## Critical Lessons Learned

### 1. Stack Overflow with Large Google Sheets (151,495 rows)

**Problem:** Google Sheets UPDATE operation loads entire sheet into memory causing "Maximum call stack size exceeded"

**Solutions Attempted:**
- ❌ Chunked search in Code node - Failed: `this.getCredentials is not a function`
- ❌ Using Code node for OAuth2 - Failed: Code nodes can't access credentials directly
- ✅ **APPEND Strategy** - Success: O(1) operation, no search needed

**Key Learning:**
```
NEVER use UPDATE on sheets > 10,000 rows
ALWAYS use APPEND to separate tracking sheet
Let Google Sheets handle VLOOKUP for merging
```

### 2. Dangling Connection Bug - Most Insidious Issue

**Problem:** "Cannot read properties of undefined (reading 'disabled')" persisted through multiple fixes

**Root Cause Discovery Process:**
1. Initial assumption: Node configuration issue
2. Checked Sentry logs: Not accessible via API
3. Checked N8N execution logs: Empty/uninformative
4. **Manual validation revealed:** Connections to deleted nodes remained in JSON
5. **Deep investigation found:** Parse Response had DUPLICATE connections - one valid, one to deleted node

**Critical Finding:**
```javascript
// This caused the error - duplicate connections
"Parse Response": {
  "main": [[
    { "node": "Prepare Batch Completed" },    // Valid
    { "node": "Append to ProcessedResults" }  // Deleted node!
  ]]
}
```

**Validation Script Created:**
```bash
# Always run this after modifying workflow
jq -r '.connections | to_entries[] | .value | to_entries[] | .value[][] | select(.node != null) | .node' workflow.json | sort -u > targets.txt
jq -r '.nodes[].name' workflow.json | sort -u > nodes.txt
diff targets.txt nodes.txt  # Should be empty
```

### 3. Column Schema Format - N8N Google Sheets v4.5

**Problem:** "Could not get parameter" at runtime

**Wrong Format (What I kept doing):**
```json
"columns": {
  "mappingMode": "defineBelow",
  "value": {
    "EIN": "={{ $json.EIN }}",
    "Name": "={{ $json.Name }}"
  }
}
```

**Correct Format (What N8N expects):**
```json
"columns": {
  "mappingMode": "defineBelow",
  "value": [
    { "column": "EIN", "fieldValue": "={{ $json.EIN }}" },
    { "column": "Name", "fieldValue": "={{ $json.Name }}" }
  ]
}
```

**Key Rule:** Column mappings MUST be array of objects with `column` and `fieldValue` keys

### 4. N8N API Deployment Gotchas

**Issue:** "request/body must NOT have additional properties"

**Properties to Remove Before Deploy:**
```javascript
// Remove these from GET response before PUT
del(.createdAt, .updatedAt, .isArchived, .shared, .tags, .triggerCount, .meta.templateCredsSetupCompleted, .versionId)
```

**Required Properties for PUT:**
```javascript
{
  name,      // Required
  nodes,     // Required
  connections, // Required
  settings   // Required - often forgotten!
}
```

### 5. Gemini AI Chain Integration

**Working Configuration:**
- Model: `gemini-2.0-flash-exp` (2.5-pro had issues)
- Temperature: 0.1 (for consistency)
- Max Tokens: 8000
- Connection: Gemini Chat Model → AI Chain node

**Critical:** AI Chain outputs in `$json.output` or `$json.text`, not `$json` directly

## Development Speed Improvements for Future

### 1. Always Start with Validation
```bash
# Before any deployment
./validate-connections.sh
./check-node-references.sh
```

### 2. Use Append Pattern for Scale
```
Read → Filter → Process → APPEND to new sheet
Never: Read → Filter → Process → UPDATE original
```

### 3. Debug Order of Operations
1. Check node connections FIRST (most common issue)
2. Verify parameter schemas match N8N version
3. Test with 1 row before scaling to thousands
4. Use native nodes over Code nodes (credential access)

### 4. Error Investigation Hierarchy
```
1. Download workflow JSON and validate structure
2. Cross-reference all connections with existing nodes
3. Check parameter formats match node documentation
4. Only then check logs/Sentry (often less helpful)
```

### 5. Common N8N Patterns That Work

**Sentry Integration:**
```javascript
// Initialize once, pass config through
const sentryConfig = $('Initialize Sentry').first().json;
// Add to each row: _sentry: sentryConfig
```

**CSV Building for AI:**
```javascript
// No headers, proper escaping
const csv = rows.map(r =>
  `${r.EIN},"${r.Name.replace(/"/g, '""')}",${r.State}`
).join('\n');
```

**Error Handling:**
```
Error Trigger → Prepare Error → Log to Sentry → Mark Rows as ERROR
```

## Critical Reminders

### NEVER DO:
1. ❌ UPDATE operations on sheets > 10K rows
2. ❌ Trust that deleted nodes remove their connections
3. ❌ Use Code nodes for OAuth2 operations
4. ❌ Deploy without validating all connection targets
5. ❌ Assume parameter format - check the node version docs

### ALWAYS DO:
1. ✅ Validate connections after ANY node deletion
2. ✅ Use APPEND strategy for large datasets
3. ✅ Test with 1-2 rows first
4. ✅ Download and inspect workflow JSON when debugging
5. ✅ Keep Sentry config in first node, pass through chain

## Debugging Checklist

When workflow fails with vague error:

- [ ] Download workflow JSON
- [ ] List all connection targets
- [ ] List all node names
- [ ] Diff to find dangling references
- [ ] Check for duplicate connections in arrays
- [ ] Verify parameter schemas (object vs array)
- [ ] Test each node individually if possible
- [ ] Check expressions use correct field names

## Performance Metrics Learned

**Google Sheets:**
- UPDATE: O(n) - fails at ~150K rows
- APPEND: O(1) - handles millions
- Read with filters: ~5-10 seconds for 150K rows

**Gemini Processing:**
- 10 nonprofits: ~20-30 seconds
- Success rate: 70-80% for website finding
- Batch size sweet spot: 10 rows

**N8N Execution:**
- Workflow with 21 nodes: ~45 seconds total
- Rate: ~600 nonprofits/hour
- Memory stable with append strategy

## Session Statistics

**Errors Encountered:** 12+
**Deployments Attempted:** 15+
**Root Causes Found:** 4 major
**Time to Resolution:** ~3 hours
**Final Status:** ✅ Working

## Key Insight

The user's feedback was critical: *"can you also make sure you are looking at the N8N logs and also the sentry outputs when trying to debug and fix and test. please use everything at your disposal to avoid all of these bugs"*

However, the most effective debugging came from **downloading and manually inspecting the workflow JSON**, not from logs. The logs were often empty or unhelpful. The real issues were in the workflow structure itself.

---
*Last Updated: 2025-11-02 13:20 UTC*
*Model Note: User experienced unusual number of bugs with Sonnet 4.5, switched to Opus 4.1*