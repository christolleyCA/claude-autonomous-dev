#!/bin/bash
# ============================================================================
# N8N WORKFLOW VALIDATOR
# Validates N8N workflow JSON for dangling connections and structure issues
# ============================================================================

WORKFLOW_FILE="$1"

if [ -z "$WORKFLOW_FILE" ]; then
  echo "Usage: $0 <workflow.json>"
  exit 1
fi

if [ ! -f "$WORKFLOW_FILE" ]; then
  echo "❌ File not found: $WORKFLOW_FILE"
  exit 1
fi

echo "═══════════════════════════════════════════════════════════"
echo "    N8N WORKFLOW VALIDATOR"
echo "═══════════════════════════════════════════════════════════"
echo "Workflow: $WORKFLOW_FILE"
echo

# Validate JSON format
if ! jq empty "$WORKFLOW_FILE" 2>/dev/null; then
  echo "❌ Invalid JSON format"
  exit 1
fi

# Extract workflow info
WORKFLOW_NAME=$(jq -r '.name // "Unknown"' "$WORKFLOW_FILE")
NODE_COUNT=$(jq '.nodes | length' "$WORKFLOW_FILE")
echo "📋 Workflow: $WORKFLOW_NAME"
echo "📊 Total Nodes: $NODE_COUNT"
echo

# Get all node names
echo "1️⃣  Extracting all node names..."
jq -r '.nodes[].name' "$WORKFLOW_FILE" | sort > /tmp/all-nodes.txt
cat /tmp/all-nodes.txt | nl
echo

# Get all connection targets
echo "2️⃣  Extracting connection targets..."
jq -r '
  .connections
  | to_entries[]
  | .value
  | to_entries[]
  | .value[][]
  | select(.node)
  | .node
' "$WORKFLOW_FILE" | sort -u > /tmp/connection-targets.txt

UNIQUE_TARGETS=$(wc -l < /tmp/connection-targets.txt | tr -d ' ')
echo "   Found $UNIQUE_TARGETS unique connection targets"
echo

# Find dangling connections
echo "3️⃣  Checking for dangling connections..."
comm -13 /tmp/all-nodes.txt /tmp/connection-targets.txt > /tmp/dangling.txt

if [ -s /tmp/dangling.txt ]; then
  echo "   ❌ DANGLING CONNECTIONS FOUND!"
  echo
  echo "   These connection targets do not exist as nodes:"
  cat /tmp/dangling.txt | sed 's/^/   → /'
  echo
  echo "   🔧 Fix: Remove these connections from the workflow JSON"
  echo "   or add the missing nodes."
  echo
  exit 1
else
  echo "   ✅ No dangling connections found!"
fi
echo

# Check for duplicate node names
echo "4️⃣  Checking for duplicate node names..."
DUPLICATES=$(jq -r '.nodes[].name' "$WORKFLOW_FILE" | sort | uniq -d)
if [ -n "$DUPLICATES" ]; then
  echo "   ❌ DUPLICATE NODE NAMES FOUND!"
  echo
  echo "$DUPLICATES" | sed 's/^/   → /'
  echo
  echo "   🔧 Fix: Each node must have a unique name"
  echo
  exit 1
else
  echo "   ✅ All node names are unique!"
fi
echo

# Check for nodes without connections
echo "5️⃣  Checking for isolated nodes..."
comm -23 /tmp/all-nodes.txt /tmp/connection-targets.txt > /tmp/isolated-nodes.txt

# Filter out trigger and AI model nodes (these don't need incoming connections)
ISOLATED=$(grep -v -E "(Trigger|Model|Error)" /tmp/isolated-nodes.txt || true)

if [ -n "$ISOLATED" ]; then
  echo "   ⚠️  Warning: These nodes have no incoming connections:"
  echo "$ISOLATED" | sed 's/^/   → /'
  echo
  echo "   💡 This might be OK for trigger/model nodes, but verify others"
else
  echo "   ✅ All non-trigger nodes have incoming connections"
fi
echo

# Summary
echo "═══════════════════════════════════════════════════════════"
echo "    VALIDATION COMPLETE"
echo "═══════════════════════════════════════════════════════════"
echo "✅ Workflow structure is valid!"
echo "✅ Safe to deploy to N8N"
echo
echo "Next steps:"
echo "1. Clean workflow: jq '{name, nodes, connections, settings}' $WORKFLOW_FILE > workflow-clean.json"
echo "2. Deploy: curl -X PUT https://n8n.grantpilot.app/api/v1/workflows/{id} -H 'X-N8N-API-KEY: {key}' -d @workflow-clean.json"
echo

# Cleanup
rm -f /tmp/all-nodes.txt /tmp/connection-targets.txt /tmp/dangling.txt /tmp/isolated-nodes.txt

exit 0
