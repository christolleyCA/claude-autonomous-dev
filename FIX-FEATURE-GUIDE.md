# fix-feature.sh - Troubleshooting & Fixing Guide

## What It Does

`fix-feature.sh` is the troubleshooting companion to `build-feature.sh`. It analyzes broken or misbehaving features, identifies root causes, generates fixes, and re-deploys - all autonomously.

## When To Use

- ✅ Feature deployed but not working as expected
- ✅ Getting errors in production
- ✅ Validation not working correctly
- ✅ N8n workflow or Edge Function needs modification
- ✅ Performance issues or bugs discovered
- ✅ Need to add new functionality to existing feature

## How It Works

### 6-Phase Autonomous Fix Process

```
1. 🔍 Gather Current State
   - Fetches current Edge Function code from Supabase
   - Retrieves N8n workflow definition
   - Collects recent logs (Supabase + N8n)
   - Checks for errors in Sentry

2. 🔬 Analyze Issues
   - AI-powered root cause analysis
   - Identifies where the bug is occurring
   - Determines impact (critical vs edge case)
   - Suggests specific fixes

3. 🔧 Generate Fixes
   - Creates corrected Edge Function code
   - Recommends N8n workflow changes
   - Maintains Sentry integration
   - Generates testing strategy

4. 📝 Apply Fixes
   - Deploys fixed code to Supabase
   - Updates Edge Function
   - Preserves production URL

5. 🧪 Verify Fixes
   - Generates test script with 3 test cases
   - Tests happy path, error cases, edge cases
   - Provides executable verification commands

6. 📊 Generate Report
   - Creates comprehensive fix report
   - Documents what was changed and why
   - Provides next steps
```

## Usage

### Basic Usage

```bash
./fix-feature.sh <feature-name> "<issue-description>"
```

### Real-World Examples

#### Example 1: Validation Not Working
```bash
./fix-feature.sh hello-world-test "Validation errors return empty responses instead of error messages"
```

**What happens:**
1. Fetches current `hello-world-test` code
2. Analyzes validation logic
3. Identifies that error path isn't returning responses
4. Fixes the validation error handling
5. Re-deploys to Supabase
6. Creates tests to verify error messages work

#### Example 2: 500 Errors in Production
```bash
./fix-feature.sh email-sender "Function returns 500 error when trying to send emails"
```

**What happens:**
1. Retrieves `email-sender` code and logs
2. Analyzes recent 500 errors in logs
3. Identifies missing API key or incorrect configuration
4. Fixes error handling and configuration
5. Deploys corrected version
6. Tests email sending end-to-end

#### Example 3: Performance Issues
```bash
./fix-feature.sh payment-processor "Stripe API calls are slow, timing out after 10 seconds"
```

**What happens:**
1. Gets `payment-processor` code and execution logs
2. Identifies slow Stripe API calls
3. Adds timeout handling, retries, better error messages
4. Optimizes code with caching if appropriate
5. Re-deploys with performance improvements
6. Creates load tests to verify speed

#### Example 4: Need to Add New Functionality
```bash
./fix-feature.sh user-registration "Need to add email verification step after registration"
```

**What happens:**
1. Retrieves current registration code
2. Analyzes existing flow
3. Adds email verification logic
4. Updates validation and error handling
5. Deploys enhanced version
6. Creates tests for new verification flow

## Output

After running, you get:

```
/tmp/autonomous-fixes/feature-name-fix-1234567890/
├── FIX-REPORT.md                  # Complete fix report
├── diagnostic-analysis.md          # Root cause analysis
├── proposed-fixes.md               # All fixes with explanations
├── current-edge-function.ts        # Original code (before fix)
├── fixed-edge-function.ts          # New code (after fix)
├── verification-tests.sh           # Executable test script
├── edge-function-logs.txt          # Recent logs
├── n8n-executions.json             # N8n execution data
└── workflow-search.json            # N8n workflow info
```

## Verification Tests

After the fix completes, run the generated tests:

```bash
# Run verification tests
bash /tmp/autonomous-fixes/feature-name-fix-*/verification-tests.sh
```

The test script will:
- Test happy path (valid input)
- Test error handling (invalid input)
- Test edge cases
- Display clear results for each test

## Slack Notifications

You'll get real-time Slack notifications at each phase:

```
🔧 AUTONOMOUS FIX STARTED
🔍 Phase 1: Gathering Current State
🔬 Phase 2: Analyzing Issues
🔧 Phase 3: Generating Fixes
📝 Phase 4: Applying Fixes
🧪 Phase 5: Verifying Fixes
📊 Phase 6: Generating Report
🎉 FIX COMPLETE
```

## Common Use Cases

### 1. Quick Bug Fix

```bash
# You notice validation isn't working
./fix-feature.sh my-feature "Validation allows empty strings when it shouldn't"

# Wait 2-3 minutes
# Check Slack for completion
# Run verification tests
bash /tmp/autonomous-fixes/my-feature-fix-*/verification-tests.sh
```

### 2. Production Error Investigation

```bash
# You see errors in Sentry
./fix-feature.sh my-feature "Getting 'undefined is not a function' errors in production"

# AI analyzes logs and code
# Identifies missing null check
# Fixes and re-deploys
# You verify with tests
```

### 3. Feature Enhancement

```bash
# Customer requests new capability
./fix-feature.sh webhook-handler "Need to add support for JSON and XML payloads, currently only handles JSON"

# AI analyzes current implementation
# Adds XML parsing logic
# Updates validation
# Re-deploys with new capability
```

### 4. Performance Optimization

```bash
./fix-feature.sh data-processor "Function takes 8 seconds, need it under 2 seconds"

# AI analyzes performance
# Identifies slow database queries
# Adds caching layer
# Optimizes algorithm
# Re-deploys faster version
```

## Integration with build-feature.sh

Both scripts work together:

```bash
# Build a new feature
./build-feature.sh new-feature "Description here"

# Test it... discover it's not working right
# Fix it
./fix-feature.sh new-feature "Issue: returns 400 on valid input"

# Feature is now working correctly!
```

## What Gets Fixed

### Edge Functions
- ✅ Validation logic
- ✅ Error handling
- ✅ API integrations
- ✅ Database queries
- ✅ Performance issues
- ✅ CORS problems
- ✅ Authentication issues
- ✅ Rate limiting

### N8n Workflows
- ⚠️ Currently: Provides recommendations
- 🔜 Future: Auto-update N8n workflows via MCP

### Monitoring
- ✅ Maintains Sentry integration
- ✅ Preserves error tracking
- ✅ Keeps performance monitoring

## Advanced Usage

### Fix with Specific Context

```bash
# Provide detailed error context
./fix-feature.sh my-feature "User reported: clicking submit button returns error 'Invalid request body'. Expected: form should validate and show success message. Current behavior: immediate error without validation feedback."
```

More detail = better fixes!

### Iterative Fixing

If the first fix doesn't completely solve it:

```bash
# First fix attempt
./fix-feature.sh my-feature "Still getting validation errors"

# Test the fix
bash /tmp/autonomous-fixes/my-feature-fix-*/verification-tests.sh

# If still broken, run again with more context
./fix-feature.sh my-feature "Validation now works for strings but fails for numbers with error: 'NaN is not a valid input'"

# Each fix builds on the previous deployment
```

## Limitations

1. **N8n Workflow Updates**: Currently provides recommendations but doesn't auto-deploy N8n changes (MCP support coming)
2. **Max Complexity**: Very complex multi-service issues may need manual intervention
3. **Database Migrations**: Doesn't handle database schema changes (use migrations instead)
4. **Environment Variables**: Doesn't update Supabase secrets (do manually via dashboard)

## Troubleshooting fix-feature.sh

### "Edge function not found"
The feature name must match exactly what's deployed in Supabase.

**Solution:**
```bash
# List all functions
claude code execute mcp__supabase__list_edge_functions --project_id hjtvtkffpziopozmtsnb

# Use exact name
./fix-feature.sh exact-function-name "Issue here"
```

### "No logs found"
Feature may not have been called recently.

**Solution:**
```bash
# Trigger the feature first
curl -X POST "https://hjtvtkffpziopozmtsnb.supabase.co/functions/v1/feature-name" \
  -H "Content-Type: application/json" \
  -d '{"test": true}'

# Then run fix
./fix-feature.sh feature-name "Issue description"
```

### "Deployment failed"
May need manual intervention.

**Solution:**
Check `/tmp/autonomous-fixes/feature-name-fix-*/fixed-edge-function.ts` for the corrected code and deploy manually via Supabase dashboard if needed.

## Best Practices

1. **Be Specific**: More detailed issue descriptions = better fixes
   - ❌ "It's broken"
   - ✅ "Returns 500 error when input contains special characters"

2. **Include Context**: Share what you've tried
   - ✅ "Expected X but got Y. Tried Z, still doesn't work."

3. **Test After Fixing**: Always run verification tests
   ```bash
   bash /tmp/autonomous-fixes/*/verification-tests.sh
   ```

4. **Check Logs**: Review the diagnostic analysis
   ```bash
   cat /tmp/autonomous-fixes/*/diagnostic-analysis.md
   ```

5. **Iterate if Needed**: Run fix-feature multiple times if first attempt doesn't fully solve it

## Next Steps After Fix

1. **Run verification tests** to confirm fix works
2. **Check Sentry** for any new errors
3. **Monitor Supabase logs** for 24 hours
4. **Update documentation** if behavior changed
5. **Consider adding to build-feature.sh** if issue was common

## Example Full Workflow

```bash
# 1. Discover issue
# User reports: "Form validation not working"

# 2. Run fix
./fix-feature.sh user-form "Validation not showing error messages, form submits with invalid data"

# 3. Wait for completion (check Slack)
# ✅ FIX COMPLETE (2m 34s)

# 4. Review fix report
cat /tmp/autonomous-fixes/user-form-fix-*/FIX-REPORT.md

# 5. Run verification tests
bash /tmp/autonomous-fixes/user-form-fix-*/verification-tests.sh

# 6. Output:
# Test 1: Valid input - ✅ PASSED
# Test 2: Invalid input - ✅ PASSED (shows error message)
# Test 3: Edge case - ✅ PASSED

# 7. Monitor in production
# Check Sentry dashboard for 24 hours

# Done! 🎉
```

## Summary

`fix-feature.sh` is your autonomous debugging assistant:
- Analyzes broken features
- Identifies root causes
- Generates fixes
- Re-deploys automatically
- Creates verification tests
- Documents everything

Use it whenever a feature isn't working as expected. It will save you hours of debugging time!
