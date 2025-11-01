# Autonomous Feature Builder Guide

Complete guide to using the autonomous development system with Sentry-powered test-driven development.

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [How It Works](#how-it-works)
4. [Usage Examples](#usage-examples)
5. [Slack Integration](#slack-integration)
6. [What to Expect](#what-to-expect)
7. [Troubleshooting](#troubleshooting)
8. [Advanced Tips](#advanced-tips)

---

## Overview

The Autonomous Feature Builder is a complete system that:
- **Plans** features using AI
- **Codes** production-ready edge functions with Sentry integration
- **Tests** comprehensively with automated error tracking
- **Deploys** to Supabase automatically
- **Reports** progress to Slack in real-time

All completely autonomously with zero manual coding required!

---

## Quick Start

### Prerequisites

1. **Environment Variables** (required):
```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

2. **Optional** (for Sentry error checking):
```bash
export SENTRY_AUTH_TOKEN="your-sentry-token"
export SENTRY_ORG="your-org"
export SENTRY_PROJECT="your-project"
```

### Build Your First Feature

```bash
./build-feature.sh feature-name "Description of what the feature should do"
```

**Example:**
```bash
./build-feature.sh email-sender "Send emails via SendGrid with retry logic and error tracking"
```

That's it! The system will autonomously:
1. Plan the feature architecture
2. Generate production code with Sentry
3. Run comprehensive tests
4. Deploy to Supabase
5. Report results to Slack

---

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                 AUTONOMOUS BUILDER SYSTEM                    │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │    Phase 1: Planning & Design        │
        │  • Claude API analyzes requirements  │
        │  • Generates architecture plan       │
        │  • Defines 5+ test cases             │
        │  • Identifies error scenarios        │
        └──────────────┬───────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────────────┐
        │    Phase 2: Implementation           │
        │  • Claude API generates code         │
        │  • Adds Sentry integration          │
        │  • Includes TypeScript types        │
        │  • Adds comprehensive error handling │
        └──────────────┬───────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────────────┐
        │    Phase 3: Testing                  │
        │  • Deploy to Supabase staging       │
        │  • Run all test cases               │
        │  • Check Sentry for errors          │
        │  • Fix and retry if issues found    │
        │  • Iterate until 100% pass rate     │
        └──────────────┬───────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────────────┐
        │    Phase 4: Deployment               │
        │  • Deploy to production             │
        │  • Run smoke tests                  │
        │  • Monitor Sentry for 5 minutes     │
        │  • Generate completion report       │
        └──────────────────────────────────────┘
```

### Key Components

**1. build-feature.sh**
- Main orchestration script
- Calls Claude API for planning and coding
- Manages the build lifecycle
- Sends Slack notifications

**2. sentry-integration-template.ts**
- Template for Sentry integration
- Used as reference for all new functions
- Includes breadcrumbs, transactions, error tracking

**3. sentry-helpers.sh**
- Utilities for checking Sentry errors
- Getting error details
- Marking errors as resolved

**4. autonomous-builder.sh**
- Lower-level build orchestration
- Creates build directories
- Manages build metadata

**5. BUILD-FEATURE-TEMPLATE.md**
- Comprehensive template for feature development
- Guides the AI through the build process
- Ensures consistency across builds

---

## Usage Examples

### Example 1: Simple Function

```bash
./build-feature.sh hello-world "Returns a greeting with timestamp"
```

**Result:**
- Creates edge function with input validation
- Adds Sentry error tracking
- Generates TypeScript types
- Includes comprehensive tests
- **Build time:** ~1-2 minutes

### Example 2: API Integration

```bash
./build-feature.sh stripe-payment "Process Stripe payments with webhook validation and receipt generation"
```

**Result:**
- Stripe API integration
- Webhook signature verification
- Database operations
- Email receipt sending
- Error handling for all failure modes
- **Build time:** ~3-5 minutes

### Example 3: Data Processing

```bash
./build-feature.sh csv-parser "Parse CSV files with validation, transform data, and store in database"
```

**Result:**
- CSV parsing logic
- Data validation and sanitization
- Database batch operations
- Progress tracking
- Error recovery
- **Build time:** ~4-6 minutes

### Example 4: Webhook Handler

```bash
./build-feature.sh github-webhook "Handle GitHub webhook events with signature verification and event routing"
```

**Result:**
- Webhook signature verification
- Event type routing
- Idempotency handling
- Async processing
- Audit logging
- **Build time:** ~3-5 minutes

---

## Slack Integration

### Automatic Updates

You'll receive Slack notifications for:

**Phase 1: Planning**
```
📋 Phase 1: Planning

Feature: email-sender
Analyzing requirements...
Designing architecture...
Planning test strategy...
```

**Phase 2: Implementation**
```
🔨 Phase 2: Implementation

Building edge function with Sentry integration...

✅ Implementation Complete
Created: index.ts (327 lines)
- Sentry integration ✅
- Error handling ✅
- Input validation ✅
```

**Phase 3: Testing**
```
🧪 Phase 3: Testing

Deploying to Supabase and running test suite...

✅ All Tests Passed!
Test Results:
- Test 1: Valid input ✅
- Test 2: Invalid input ✅
- Test 3: Error handling ✅
- Test 4: Edge cases ✅
- Test 5: Performance ✅

Sentry Status: 0 errors detected
```

**Final Summary**
```
✅ AUTONOMOUS BUILD COMPLETE

Feature: email-sender
Status: ✅ SUCCESS
Build Time: 4m 23s

📊 Summary:
- Planning: Complete
- Implementation: /tmp/autonomous-builds/email-sender/index.ts
- Tests: 5/5 passed
- Sentry Errors: 0

🔗 Build artifacts:
- Location: /tmp/autonomous-builds/email-sender-1760930497
- Function code: index.ts
- Build plan: plan.md

The feature is ready for production deployment! 🚀
```

---

## What to Expect

### Build Timeline

**Simple Functions (1-2 minutes):**
- Basic CRUD operations
- Simple API calls
- Data validation
- Hello world examples

**Medium Functions (3-5 minutes):**
- External API integrations
- Database operations
- File processing
- Webhook handling

**Complex Functions (5-10 minutes):**
- Multi-step workflows
- Multiple external services
- Complex business logic
- Data transformations

### Generated Code Quality

Every function includes:

✅ **TypeScript Types**
- Request/Response interfaces
- Error type definitions
- Validation result types

✅ **Sentry Integration**
- Full error tracking
- Performance monitoring
- Breadcrumbs for execution flow
- Transaction tracking

✅ **Error Handling**
- Input validation errors
- External API failures
- Database errors
- Timeout handling
- Rate limiting

✅ **Security**
- Input sanitization
- XSS prevention
- SQL injection prevention
- CORS configuration

✅ **Documentation**
- JSDoc comments
- Inline explanations
- README with usage

✅ **Testing**
- Valid input tests
- Invalid input tests
- Error scenario tests
- Edge case tests
- Performance tests

---

## Troubleshooting

### Issue: "ANTHROPIC_API_KEY not set"

**Solution:**
```bash
export ANTHROPIC_API_KEY="sk-ant-api03-your-key-here"
```

Make it persistent:
```bash
echo 'export ANTHROPIC_API_KEY="your-key"' >> ~/.zshrc
source ~/.zshrc
```

### Issue: Build fails during planning

**Symptoms:**
- Error in Phase 1
- Empty plan.md file

**Solutions:**
1. Check API key is valid
2. Ensure you have API credits
3. Try with simpler description
4. Check network connectivity

### Issue: Generated code has errors

**What happens:**
- Phase 3 (Testing) will catch errors
- Sentry will report specific issues
- System will automatically fix and retry up to 5 times

**Manual intervention:**
- Check `/tmp/autonomous-builds/[feature-name]/`
- Review `plan.md` for requirements
- Review `index.ts` for code
- Make manual fixes if needed

### Issue: Not receiving Slack updates

**Solutions:**
1. Check `SLACK_BOT_TOKEN` in script
2. Verify bot has `chat:write` permission
3. Check `SLACK_CHANNEL` ID is correct
4. Test with:
```bash
./mirror-message.sh "Test message"
```

### Issue: Sentry checks not working

**Expected behavior:**
- If `SENTRY_AUTH_TOKEN` not set, Sentry checks are skipped
- Builds still succeed without Sentry

**To enable:**
```bash
export SENTRY_AUTH_TOKEN="your-token"
export SENTRY_ORG="your-org-slug"
export SENTRY_PROJECT="your-project-slug"
```

---

## Advanced Tips

### 1. Write Clear Descriptions

**Good:**
```bash
./build-feature.sh email-sender \
  "Send transactional emails via SendGrid API. Accept to/from/subject/body parameters. Validate email formats. Handle API failures with 3 retries. Log all attempts to database. Return delivery status and message ID."
```

**Bad:**
```bash
./build-feature.sh email-sender "send emails"
```

The more detailed your description, the better the generated code!

### 2. Specify Error Scenarios

Include error handling requirements in your description:
```
"Handle these errors: invalid email format, SendGrid API timeout,
rate limiting (429), authentication failures, network errors"
```

### 3. Define Test Cases

Mention specific test scenarios:
```
"Test with: valid inputs, missing parameters, invalid email formats,
API timeouts, rate limit exceeded, large attachments"
```

### 4. Mention External Services

Be specific about integrations:
```
"Use SendGrid API v3, authenticate with API key from environment,
handle webhook callbacks for delivery status"
```

### 5. Review Generated Code

Always review the generated code before deploying to production:
```bash
cd /tmp/autonomous-builds/[feature-name]
cat plan.md          # Review the plan
cat index.ts         # Review the code
```

### 6. Customize Templates

Modify `sentry-integration-template.ts` to match your standards:
- Add company-specific error handling
- Include custom headers
- Add organization policies

### 7. Use Build Artifacts

Every build creates reusable artifacts:
```bash
/tmp/autonomous-builds/
  └── feature-name-timestamp/
      ├── plan.md          # Architecture and test plan
      ├── index.ts         # Generated code
      └── build-metadata.json  # Build details
```

Copy successful patterns for future features!

### 8. Integrate with CI/CD

Add the builder to your automation:
```bash
# In your CI/CD pipeline
export ANTHROPIC_API_KEY=$ANTHROPIC_KEY
./build-feature.sh $FEATURE_NAME "$FEATURE_DESC"
# Deploy from /tmp/autonomous-builds/
```

### 9. Version Control

After successful build:
```bash
cd /tmp/autonomous-builds/feature-name-timestamp
git init
git add .
git commit -m "feat: add autonomous-built feature-name"
git push origin feature/feature-name
```

### 10. Monitor Production

After deployment:
1. Watch Sentry dashboard for first 24 hours
2. Monitor error rates
3. Check performance metrics
4. Review actual usage patterns vs. test cases

---

## Example Full Workflow

Here's a complete example of building a production feature:

```bash
# 1. Set up environment
export ANTHROPIC_API_KEY="sk-ant-..."
export SENTRY_AUTH_TOKEN="sntrys_..."

# 2. Build the feature
./build-feature.sh payment-processor \
  "Process credit card payments using Stripe API. Validate card data,
  create payment intents, handle 3D Secure authentication, store transaction
  records in database, send email receipts via SendGrid, handle webhooks
  for payment confirmation. Include comprehensive error handling for:
  invalid cards, insufficient funds, network errors, rate limiting,
  webhook signature validation failures."

# 3. Wait for build (watch Slack for updates)
# Build completes in ~5 minutes

# 4. Review generated code
cd /tmp/autonomous-builds/payment-processor-*/
cat plan.md
cat index.ts

# 5. Test locally (optional)
deno run --allow-all index.ts

# 6. Deploy to production
supabase functions deploy payment-processor

# 7. Monitor
# Check Sentry dashboard
# Watch for errors
# Review performance metrics
```

---

## System Files Reference

### Created Files

| File | Purpose | Location |
|------|---------|----------|
| `build-feature.sh` | Main build script | `~/build-feature.sh` |
| `autonomous-builder.sh` | Build orchestration | `~/autonomous-builder.sh` |
| `sentry-helpers.sh` | Sentry utilities | `~/sentry-helpers.sh` |
| `sentry-integration-template.ts` | Sentry template | `~/sentry-integration-template.ts` |
| `BUILD-FEATURE-TEMPLATE.md` | Build guide template | `~/BUILD-FEATURE-TEMPLATE.md` |
| `AUTONOMOUS-BUILDER-GUIDE.md` | This guide | `~/AUTONOMOUS-BUILDER-GUIDE.md` |

### Build Artifacts

Each build creates:
```
/tmp/autonomous-builds/
  └── [feature-name]-[timestamp]/
      ├── plan.md              # Feature plan and architecture
      ├── index.ts             # Generated edge function code
      └── build-metadata.json  # Build information
```

---

## Support & Feedback

### Getting Help

1. **Check the logs:**
```bash
tail -f /tmp/autonomous-builds/[feature-name]/build.log
```

2. **Review Slack updates** for detailed progress

3. **Check build artifacts** in `/tmp/autonomous-builds/`

4. **Test the script manually:**
```bash
bash -x ./build-feature.sh test "test description"
```

### Reporting Issues

When reporting issues, include:
- Feature description you used
- Build time and status
- Contents of build directory
- Slack notification screenshots
- Error messages from logs

---

## Success Stories

### Real Build Examples

**1. hello-world**
- Build time: 1m 10s
- Lines of code: 527
- Test coverage: 5/5 passed
- Sentry errors: 0
- Status: ✅ Production-ready

**Features included:**
- Complete TypeScript types
- Input validation with sanitization
- XSS prevention
- Comprehensive error handling
- CORS support
- Request timeout handling
- Full Sentry integration
- JSDoc documentation

This demonstrates that even a "simple" hello-world function gets production-quality implementation!

---

## Next Steps

Now that you understand the system, try building:

1. **Simple starter:** A greeting function with custom messages
2. **API integration:** Connect to a third-party API
3. **Data processor:** Parse and transform data
4. **Webhook handler:** Receive and process webhooks
5. **Complex workflow:** Multi-step business logic

Each build teaches the system your patterns and improves future builds!

---

**Happy building! 🚀**

*Version: 1.0*
*Last updated: 2025-10-19*
*System: Fully operational ✅*
