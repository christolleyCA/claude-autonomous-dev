# N8N Workflow Documentation Hub

Complete knowledge base for N8N workflow development, focusing on the NFP Website Finder workflow and best practices learned through production deployment.

---

## 📚 Core Documentation

### [N8N Workflow Knowledge Base](N8N-WORKFLOW-KNOWLEDGE-BASE.md)
**The master document** - Critical lessons learned from building and debugging the NFP Website Finder workflow.

**Contents:**
- Stack overflow solutions for large Google Sheets (151K+ rows)
- Dangling connection bug resolution
- Column schema format requirements
- Gemini AI integration patterns
- Performance metrics and optimization
- Complete debugging checklist

**Read this first** if you're working on the NFP workflow or debugging N8N issues.

---

### [N8N API Deployment Guide](N8N-API-DEPLOYMENT-GUIDE.md)
**Technical reference** - Step-by-step guide for deploying workflows via N8N API.

**Contents:**
- API key rotation and management
- Workflow validation process
- Deployment commands and scripts
- Common error resolution
- Best practices checklist

**Use this when** deploying workflow changes or troubleshooting API issues.

---

### [Your Workflow Specifics](YOUR-WORKFLOW-SPECIFICS.md)
**Quick reference** - Configuration details for your NFP Website Finder workflow.

**Contents:**
- Current credentials (API keys, DSNs)
- Workflow architecture overview
- Performance metrics
- Quick commands for common tasks
- Troubleshooting specific to your setup

**Use this for** quick lookups of URLs, IDs, and deployment commands.

---

### [N8N Technical Patterns](N8N-TECHNICAL-PATTERNS.md)
**Reusable solutions** - Copy-paste patterns that work in production.

**Contents:**
- Sentry integration patterns
- CSV building for AI prompts
- Error handling workflows
- Node connection patterns

**Use this when** building new workflows or adding features.

---

### [N8N Quick Fixes](N8N-QUICK-FIXES.md)
**Cheat sheet** - Common problems and instant solutions.

**Contents:**
- Stack overflow → use APPEND
- Dangling connections → run validator
- Column format errors → use array format
- Model not found → check model name

**Use this when** you hit a known error and need the fix fast.

---

## 🔧 Scripts & Tools

### Workflow Validator
**Location:** `~/autonomous-dev/bin/automation/validate-n8n-workflow.sh`

```bash
# Validate workflow before deployment
~/autonomous-dev/bin/automation/validate-n8n-workflow.sh workflow.json
```

**Checks:**
- ✅ Dangling connections
- ✅ Duplicate node names
- ✅ Isolated nodes
- ✅ JSON structure validity

**Always run before deploying!**

---

## 🚀 Quick Start Workflows

### Deploy Workflow Changes
```bash
# 1. Get current workflow
curl -s "https://n8n.grantpilot.app/api/v1/workflows/pc1cMXkDsrWlOpKu" \
  -H "X-N8N-API-KEY: $(cat YOUR-WORKFLOW-SPECIFICS.md | grep N8N_API_KEY | cut -d'"' -f2)" \
  > workflow.json

# 2. Validate structure
~/autonomous-dev/bin/automation/validate-n8n-workflow.sh workflow.json

# 3. Clean for deployment
jq '{name, nodes, connections, settings}' workflow.json > workflow-clean.json

# 4. Deploy
curl -sX PUT "https://n8n.grantpilot.app/api/v1/workflows/pc1cMXkDsrWlOpKu" \
  -H "X-N8N-API-KEY: your-key-here" \
  -H "Content-Type: application/json" \
  -d @workflow-clean.json
```

### Debug Workflow Issues
```bash
# 1. Download workflow
curl -s "https://n8n.grantpilot.app/api/v1/workflows/pc1cMXkDsrWlOpKu" \
  -H "X-N8N-API-KEY: your-key-here" \
  > workflow-debug.json

# 2. Check for issues
~/autonomous-dev/bin/automation/validate-n8n-workflow.sh workflow-debug.json

# 3. Inspect specific nodes
jq '.nodes[] | select(.name == "Node Name") | .parameters' workflow-debug.json

# 4. Check connections
jq '.connections' workflow-debug.json
```

---

## 📊 Workflow Status

**Current Configuration (as of 2025-11-02 15:36 UTC):**

| Property | Value |
|----------|-------|
| **ID** | pc1cMXkDsrWlOpKu |
| **Name** | NFP Website Finder - Instance 1 |
| **Status** | Inactive (ready for testing) |
| **Nodes** | 21 (validated) |
| **Model** | gemini-2.5-pro |
| **Batch Size** | 10 rows |
| **Target** | 23,871 nonprofits |
| **Rate** | ~600/hour when active |

---

## 🐛 Common Issues & Solutions

| Issue | Document | Section |
|-------|----------|---------|
| Stack overflow with large sheets | Knowledge Base | Section 1 |
| Dangling connections error | Knowledge Base | Section 2 |
| Column format "could not get parameter" | Knowledge Base | Section 3 |
| API unauthorized errors | Deployment Guide | API Key Management |
| Deployment validation errors | Deployment Guide | Common Errors |
| Gemini model not found | Your Workflow | Section 4 |

---

## 🎯 Decision Trees

### "My workflow won't deploy"
1. Check API key → [Deployment Guide - API Key Management](N8N-API-DEPLOYMENT-GUIDE.md#problem-api-key-rotation)
2. Validate structure → Run `validate-n8n-workflow.sh`
3. Check payload → [Deployment Guide - Clean Workflow](N8N-API-DEPLOYMENT-GUIDE.md#step-3-clean-workflow-for-deployment)
4. Review errors → [Deployment Guide - Common Errors](N8N-API-DEPLOYMENT-GUIDE.md#common-deployment-errors)

### "My workflow runs but fails"
1. Check Sentry → [Your Workflow - Check Sentry](YOUR-WORKFLOW-SPECIFICS.md#check-your-sentry)
2. Validate connections → Run `validate-n8n-workflow.sh`
3. Check node configs → [Knowledge Base - Debugging Checklist](N8N-WORKFLOW-KNOWLEDGE-BASE.md#debugging-checklist)
4. Review patterns → [Technical Patterns](N8N-TECHNICAL-PATTERNS.md)

### "I need to build a new workflow"
1. Review patterns → [Technical Patterns](N8N-TECHNICAL-PATTERNS.md)
2. Check quick fixes → [Quick Fixes](N8N-QUICK-FIXES.md)
3. Learn from history → [Knowledge Base - Lessons Learned](N8N-WORKFLOW-KNOWLEDGE-BASE.md#critical-lessons-learned)
4. Use validation → Always run validator before deploy

---

## 📝 Contributing to Knowledge Base

When you discover new issues or solutions:

1. **Update the main Knowledge Base** with detailed findings
2. **Add quick fix** to N8N-QUICK-FIXES.md if it's a common issue
3. **Create reusable pattern** in N8N-TECHNICAL-PATTERNS.md if applicable
4. **Update this README** if you add new documents

---

## 🔄 Version History

| Date | Session | Changes | Model |
|------|---------|---------|-------|
| 2025-11-02 13:20 | Initial | Created knowledge base from NFP workflow debugging | Sonnet 4.5 → Opus 4.1 |
| 2025-11-02 15:45 | API Deployment | Added API guide, validator script, and documentation hub | Opus 4.1 |

---

## 💡 Best Practices Summary

### Before Deployment
1. ✅ Validate workflow structure
2. ✅ Test API connectivity
3. ✅ Clean payload (only 4 properties)
4. ✅ Check credentials are current

### During Development
1. ✅ Use APPEND for large datasets
2. ✅ Test with 1 row first
3. ✅ Validate after any node deletion
4. ✅ Use array format for columns

### After Issues
1. ✅ Download workflow JSON first
2. ✅ Run validation script
3. ✅ Check structure before logs
4. ✅ Document the solution

---

**Need help?** Start with the [Knowledge Base](N8N-WORKFLOW-KNOWLEDGE-BASE.md) - it has the answers to 90% of N8N issues!

---

*Last Updated: 2025-11-02 15:50 UTC*
