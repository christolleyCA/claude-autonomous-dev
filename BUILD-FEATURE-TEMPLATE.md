# Autonomous Feature Build Template

Use this template when building new features autonomously with Sentry integration and test-driven development.

---

## Feature Information

**Feature Name:** [FEATURE_NAME]
**Description:** [DESCRIPTION]
**Build Started:** [TIMESTAMP]
**Build Directory:** [BUILD_DIR]

---

## Phase 1: Planning & Design

### Requirements Analysis
- [ ] Understand the feature requirements from description
- [ ] Identify inputs and expected outputs
- [ ] List dependencies (external APIs, database tables, etc.)
- [ ] Define success criteria

### Architecture Design
- [ ] Design edge function structure
- [ ] Define TypeScript types for:
  - [ ] Request body
  - [ ] Response body
  - [ ] Internal data structures
- [ ] Plan database interactions (if any)
- [ ] Plan external API calls (if any)

### Test Strategy
- [ ] Define minimum 5 test cases:
  1. **Valid Input Test**: Test with correct, expected inputs
  2. **Invalid Input Test**: Test with malformed/missing inputs
  3. **Error Scenario Test**: Test error handling (DB failure, API timeout, etc.)
  4. **Edge Case Test**: Test boundary conditions
  5. **Performance Test**: Test with large/complex inputs

### Error Scenarios to Handle
- [ ] Invalid/missing request body
- [ ] Database connection/query errors
- [ ] External API failures/timeouts
- [ ] Authentication/authorization failures
- [ ] Rate limiting scenarios
- [ ] Unexpected data formats

### Sentry Integration Plan
- [ ] Initialize Sentry with proper DSN
- [ ] Add transaction tracking for performance
- [ ] Add breadcrumbs for execution flow
- [ ] Define error tags for categorization
- [ ] Plan error context data to capture

---

## Phase 2: Building

### Setup
- [ ] Create `[feature-name].ts` file
- [ ] Add imports from Sentry template
- [ ] Initialize Sentry with configuration
- [ ] Set up TypeScript types

### Sentry Integration (Copy from template)
```typescript
import * as Sentry from "https://deno.land/x/sentry@7.119.0/index.mjs";

Sentry.init({
  dsn: Deno.env.get("SENTRY_DSN"),
  environment: Deno.env.get("ENVIRONMENT") || "production",
  tracesSampleRate: 1.0,
  initialScope: {
    tags: {
      function: "[feature-name]",
      runtime: "deno",
    },
  },
});
```

### Core Implementation
- [ ] Implement request handler with transaction tracking
- [ ] Add input validation
  - [ ] Validate required fields
  - [ ] Validate data types
  - [ ] Validate data formats
  - [ ] Add validation breadcrumbs
- [ ] Implement core business logic
  - [ ] Add breadcrumbs for key operations
  - [ ] Wrap risky operations in try-catch
  - [ ] Add meaningful error messages
- [ ] Implement response formatting

### Error Handling
Add comprehensive error handling for:
- [ ] **Input Validation Errors**
  ```typescript
  if (!body || !body.requiredField) {
    Sentry.captureMessage("Missing required field", "warning");
    return errorResponse("Missing required field", 400);
  }
  ```
- [ ] **Database Errors**
  ```typescript
  try {
    const data = await supabase.from('table').select();
  } catch (error) {
    Sentry.captureException(error, {
      tags: { errorType: "database" },
      extra: { query: "table_name" }
    });
    return errorResponse("Database error", 500);
  }
  ```
- [ ] **External API Errors**
  ```typescript
  try {
    const response = await fetch(apiUrl);
  } catch (error) {
    Sentry.captureException(error, {
      tags: { errorType: "external_api" },
      extra: { url: apiUrl }
    });
    return errorResponse("External service unavailable", 503);
  }
  ```
- [ ] **Timeout Errors**
  ```typescript
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10000);
  try {
    const response = await fetch(url, { signal: controller.signal });
  } catch (error) {
    if (error.name === 'AbortError') {
      Sentry.captureMessage("Request timeout", "error");
      return errorResponse("Request timeout", 504);
    }
  }
  ```

### Documentation
- [ ] Add JSDoc comments to main function
- [ ] Add JSDoc comments to helper functions
- [ ] Add inline comments for complex logic
- [ ] Document environment variables needed

---

## Phase 3: Testing (Iterate Until Perfect)

### Test Execution Plan
For **EACH** test case, follow this loop:

1. **Deploy to Staging**
   ```bash
   # Deploy function to Supabase
   supabase functions deploy [feature-name]
   ```

2. **Run Test**
   ```bash
   # Execute test case
   curl -X POST "https://[project].supabase.co/functions/v1/[feature-name]" \
     -H "Authorization: Bearer [key]" \
     -H "Content-Type: application/json" \
     -d '[test-data]'
   ```

3. **Wait for Sentry**
   ```bash
   # Wait 10 seconds for Sentry to receive data
   sleep 10
   ```

4. **Check Sentry for Errors**
   ```bash
   ./sentry-helpers.sh check_sentry_for_errors "10m" "[feature-name]"
   ```

5. **If Errors Found:**
   - Read full error details from Sentry
   - Analyze root cause
   - Implement fix in code
   - Add additional error handling if needed
   - Redeploy to staging
   - Retest (max 5 attempts per test)

6. **If No Errors:**
   - Mark test as passed
   - Move to next test case

7. **Update Slack**
   ```bash
   ./mirror-message.sh "Test [N]: [PASS/FAIL] - [test description]"
   ```

### Test Cases

#### Test 1: Valid Input
- [ ] Description: [What this tests]
- [ ] Input Data: `[JSON]`
- [ ] Expected Output: `[JSON]`
- [ ] Sentry Status: [ ] Clean

#### Test 2: Invalid Input
- [ ] Description: [What this tests]
- [ ] Input Data: `[JSON]`
- [ ] Expected Output: `[JSON]`
- [ ] Sentry Status: [ ] Clean

#### Test 3: Error Scenario
- [ ] Description: [What this tests]
- [ ] Input Data: `[JSON]`
- [ ] Expected Output: `[JSON]`
- [ ] Sentry Status: [ ] Clean

#### Test 4: Edge Case
- [ ] Description: [What this tests]
- [ ] Input Data: `[JSON]`
- [ ] Expected Output: `[JSON]`
- [ ] Sentry Status: [ ] Clean

#### Test 5: Performance
- [ ] Description: [What this tests]
- [ ] Input Data: `[JSON]`
- [ ] Expected Output: `[JSON]`
- [ ] Sentry Status: [ ] Clean

### Testing Loop Criteria
- ✅ Continue testing until ALL tests pass
- ✅ Continue until Sentry shows ZERO errors
- ✅ Maximum 5 fix attempts per test
- ✅ If max attempts reached, escalate to human review

---

## Phase 4: Deployment

### Pre-Deployment Checklist
- [ ] All tests passing (5/5)
- [ ] Zero errors in Sentry
- [ ] Code is fully typed (TypeScript)
- [ ] Code is documented (JSDoc)
- [ ] Error handling is comprehensive
- [ ] Environment variables documented

### Production Deployment
```bash
# Deploy to production
supabase functions deploy [feature-name] --project-ref [production-project]
```

### Smoke Tests
- [ ] Run basic functionality test in production
- [ ] Verify Sentry is receiving production data
- [ ] Check response times are acceptable
- [ ] Verify error handling works in production

### Post-Deployment Monitoring
- [ ] Monitor Sentry for 5 minutes after deployment
- [ ] Check for any unexpected errors
- [ ] Verify success rate is 100% for valid requests
- [ ] Confirm performance is within acceptable range

---

## Phase 5: Completion Report

### Build Summary
```
Feature: [feature-name]
Status: [Success/Failed]
Total Time: [X minutes]
Total Iterations: [N]
Tests Run: [N]
Tests Passed: [N]
Sentry Errors Found: [N]
Sentry Errors Fixed: [N]
```

### Issues Found & Fixed
1. **Issue**: [Description]
   - **Root Cause**: [Analysis]
   - **Fix Applied**: [Solution]
   - **Test Result**: [Pass/Fail]

### Final Slack Message
```
✅ *AUTONOMOUS BUILD COMPLETE*

Feature: `[feature-name]`
Status: ✅ SUCCESS
Build Time: [X minutes]

📊 Statistics:
- Tests: [N/N] passed
- Iterations: [N]
- Sentry errors fixed: [N]

🔗 Links:
- Sentry Dashboard: [URL]
- Supabase Function: [URL]
- Build Log: [PATH]

The feature is live and ready to use! 🚀
```

---

## Success Criteria Checklist

- [ ] ✅ All tests pass (100%)
- [ ] ✅ Zero errors in Sentry
- [ ] ✅ Code is fully typed with TypeScript
- [ ] ✅ Code is documented with JSDoc
- [ ] ✅ Error handling is comprehensive
- [ ] ✅ Deployed to production successfully
- [ ] ✅ Smoke tests pass
- [ ] ✅ 5-minute monitoring shows no issues
- [ ] ✅ Completion report sent to Slack

---

## Notes

- If any test fails after 5 attempts, pause and request human review
- Always wait at least 10 seconds after deployment before checking Sentry
- Mark each Sentry error as "resolved" after fixing
- Keep Slack updated after each phase
- Save all logs to build directory for debugging

---

**Template Version:** 1.0
**Last Updated:** 2025-10-19
