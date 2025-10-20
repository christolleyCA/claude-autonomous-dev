# build-feature.sh vs fix-feature.sh

## Quick Comparison

| Feature | build-feature.sh | fix-feature.sh |
|---------|------------------|----------------|
| **Purpose** | Build NEW features from scratch | Fix EXISTING features |
| **Input** | Feature name + description | Feature name + issue description |
| **Starting Point** | Nothing (creates from zero) | Existing deployed code |
| **Analyzes** | Requirements and design | Current code, logs, errors |
| **Generates** | New Edge Function + N8n workflow | Fixed versions of existing code |
| **Deploys** | Creates new deployment | Updates existing deployment |
| **Output** | Production-ready feature | Debugged and fixed feature |
| **Use When** | "I need a new feature" | "This feature is broken" |

## Workflow Examples

### Scenario 1: Building Something New

```bash
# You want a new feature
./build-feature.sh email-sender "Send emails via SendGrid with validation"

# Result: Brand new feature built in 3-5 minutes
# - Edge Function created
# - N8n workflow created
# - Tests created
# - Deployed to production
```

### Scenario 2: Fixing Something Broken

```bash
# Feature exists but has bugs
./fix-feature.sh email-sender "Emails failing with 'API key invalid' error"

# Result: Existing feature fixed in 2-3 minutes
# - Current code analyzed
# - Root cause identified (missing env var)
# - Fixed code deployed
# - Verification tests created
```

## What Each Script Does

### build-feature.sh Phases

```
1. 📋 Planning & Architecture
   - Designs Edge Function
   - Designs N8n Workflow
   - Plans integration
   - Creates test strategy

2. 🔨 Edge Function Implementation
   - Generates TypeScript code
   - Adds Sentry integration
   - Includes error handling
   - Adds validation

3. ⚙️ N8n Workflow Creation
   - Creates workflow JSON
   - Adds Sentry monitoring
   - Sets up error paths
   - Configures triggers

4. 📦 Edge Function Deployment
   - Deploys to Supabase
   - Creates endpoint

5. 🚀 N8n Workflow Activation
   - Prepares for deployment

6. 🧪 Integration Testing
   - Tests happy path
   - Tests error cases
   - Verifies integration

7. 📊 Log Analysis
   - Checks for issues

8. 🔧 Auto-Fix (if needed)
   - Fixes any initial issues

9. ✅ Final Validation
   - Confirms ready for production
```

### fix-feature.sh Phases

```
1. 🔍 Gather Current State
   - Fetches deployed code
   - Retrieves N8n workflow
   - Collects recent logs
   - Gathers error reports

2. 🔬 Analyze Issues
   - AI-powered root cause analysis
   - Identifies bug location
   - Determines impact
   - Plans fixes

3. 🔧 Generate Fixes
   - Creates corrected code
   - Maintains Sentry integration
   - Preserves working parts
   - Adds improvements

4. 📝 Apply Fixes
   - Deploys fixed code
   - Updates production

5. 🧪 Verify Fixes
   - Creates test script
   - Tests all scenarios

6. 📊 Generate Report
   - Documents changes
   - Explains what was fixed
   - Provides next steps
```

## Real-World Examples

### Example 1: New Feature Development

**Scenario**: You need a Stripe payment processor

```bash
# Build it
./build-feature.sh stripe-payment "Process Stripe payments with webhook validation"

# What happens:
# ✅ Creates Edge Function with Stripe SDK integration
# ✅ Creates N8n workflow to handle webhooks
# ✅ Adds validation for Stripe signatures
# ✅ Includes error handling and retries
# ✅ Deploys everything
# ✅ Creates integration tests

# Time: 3-5 minutes
# Result: Production-ready payment processor
```

### Example 2: Debugging Production Issue

**Scenario**: Payment processor is returning 500 errors

```bash
# Fix it
./fix-feature.sh stripe-payment "Returns 500 error with message 'Cannot read property signature of undefined'"

# What happens:
# ✅ Retrieves current Stripe payment code
# ✅ Analyzes recent error logs
# ✅ Identifies: missing null check on webhook.signature
# ✅ Generates fixed code with proper validation
# ✅ Deploys corrected version
# ✅ Creates tests to verify signature handling

# Time: 2-3 minutes
# Result: Bug fixed, deployed, tested
```

### Example 3: Feature Enhancement

**Scenario**: Need to add new functionality

```bash
# Use fix-feature to enhance
./fix-feature.sh stripe-payment "Need to add support for subscription payments, currently only handles one-time charges"

# What happens:
# ✅ Analyzes current payment flow
# ✅ Adds subscription handling logic
# ✅ Updates validation for recurring payments
# ✅ Maintains existing one-time payment logic
# ✅ Deploys enhanced version
# ✅ Creates tests for both payment types

# Time: 2-4 minutes
# Result: Enhanced feature with new capability
```

## When To Use Each

### Use build-feature.sh when:

- ✅ Starting a new feature from scratch
- ✅ No existing code to build on
- ✅ Need both Edge Function AND N8n workflow
- ✅ Want comprehensive planning and architecture
- ✅ Building something new that doesn't exist yet

**Example situations:**
- "I need a new webhook handler for GitHub events"
- "Build me a PDF generator service"
- "Create a user authentication system"
- "I want to process CSV uploads"

### Use fix-feature.sh when:

- ✅ Feature exists but has bugs
- ✅ Getting errors in production
- ✅ Need to modify existing functionality
- ✅ Performance issues
- ✅ Want to add capabilities to existing feature
- ✅ Validation or error handling broken

**Example situations:**
- "The webhook handler is returning 500 errors"
- "PDF generator is slow, takes 10 seconds"
- "Authentication is rejecting valid tokens"
- "CSV processor crashes on large files"
- "Need to add XML support to existing JSON parser"

## Output Comparison

### build-feature.sh Output

```
/tmp/autonomous-builds/feature-name-1234567890/
├── plan.md                    # Architecture design
├── index.ts                   # Edge Function code
├── workflow.json              # N8n workflow definition
├── test-cases.sh              # Integration tests
├── test-results.txt           # Test results
└── validation-report.txt      # Final validation
```

### fix-feature.sh Output

```
/tmp/autonomous-fixes/feature-name-fix-1234567890/
├── FIX-REPORT.md              # Complete fix report
├── diagnostic-analysis.md      # Root cause analysis
├── proposed-fixes.md           # Detailed fixes
├── current-edge-function.ts    # Original code
├── fixed-edge-function.ts      # Corrected code
├── verification-tests.sh       # Test script
├── edge-function-logs.txt      # Recent logs
└── n8n-executions.json         # Workflow data
```

## Common Workflow Patterns

### Pattern 1: Build → Test → Fix

```bash
# 1. Build new feature
./build-feature.sh my-feature "Description here"

# 2. Test in production
curl https://.../functions/v1/my-feature -d '{"test": true}'

# 3. Discover issue
# "Oh no, it's returning 400 on valid input!"

# 4. Fix the issue
./fix-feature.sh my-feature "Returns 400 error on valid JSON input"

# 5. Verify fix
bash /tmp/autonomous-fixes/my-feature-fix-*/verification-tests.sh

# Done! Feature is now working correctly
```

### Pattern 2: Iterative Enhancement

```bash
# Week 1: Build initial version
./build-feature.sh email-handler "Handle incoming emails and parse them"

# Week 2: Add attachment support
./fix-feature.sh email-handler "Need to add support for email attachments"

# Week 3: Add spam filtering
./fix-feature.sh email-handler "Need to filter out spam emails before processing"

# Week 4: Optimize performance
./fix-feature.sh email-handler "Email processing is slow, need to speed it up"

# Each enhancement builds on the previous version
```

### Pattern 3: Production Debugging

```bash
# Sentry alert: Feature failing in production
# Error: "TypeError: Cannot read property 'data' of undefined"

# 1. Quick fix
./fix-feature.sh problematic-feature "Production errors: 'Cannot read property data of undefined' in line 45"

# 2. Wait 2 minutes

# 3. Verify fix deployed
bash /tmp/autonomous-fixes/problematic-feature-fix-*/verification-tests.sh

# 4. Monitor Sentry
# ✅ No more errors

# Downtime: < 5 minutes total
```

## Tips for Best Results

### For build-feature.sh

1. **Be descriptive**: More details = better architecture
   ```bash
   # ❌ Too vague
   ./build-feature.sh processor "Process data"

   # ✅ Detailed and clear
   ./build-feature.sh csv-processor "Parse CSV files, validate data types, handle up to 10k rows, return JSON with summary and errors"
   ```

2. **Specify integrations**: Mention external services
   ```bash
   ./build-feature.sh email-sender "Send emails via SendGrid API with templating support"
   ```

3. **Include constraints**: Mention requirements
   ```bash
   ./build-feature.sh image-processor "Resize images using Sharp, max 5MB, output WebP format"
   ```

### For fix-feature.sh

1. **Provide error messages**: Copy exact errors
   ```bash
   # ✅ Specific error included
   ./fix-feature.sh my-feature "Returns error: 'ValidationError: name is required' even when name is provided"
   ```

2. **Describe expected vs actual**:
   ```bash
   ./fix-feature.sh my-feature "Expected: returns {success: true}. Actual: returns empty response"
   ```

3. **Mention what you tried**:
   ```bash
   ./fix-feature.sh my-feature "Tried increasing timeout but still fails. Error occurs on line 67 in validation logic."
   ```

## Cost Comparison

### build-feature.sh
- **API Calls**: 6-8 Claude API calls
- **Time**: 3-5 minutes
- **Token Usage**: ~10,000-15,000 tokens
- **Slack Messages**: ~12 messages

### fix-feature.sh
- **API Calls**: 4-5 Claude API calls
- **Time**: 2-3 minutes
- **Token Usage**: ~6,000-10,000 tokens
- **Slack Messages**: ~8 messages

Both are optimized for speed and cost-effectiveness!

## Summary

**Use build-feature.sh to CREATE**
- Starts from zero
- Builds complete feature (Edge Function + N8n)
- Comprehensive planning and testing
- Production-ready output

**Use fix-feature.sh to FIX/ENHANCE**
- Starts from existing code
- Analyzes and debugs issues
- Generates targeted fixes
- Maintains production stability

Together, they give you a complete autonomous development and maintenance system! 🚀
