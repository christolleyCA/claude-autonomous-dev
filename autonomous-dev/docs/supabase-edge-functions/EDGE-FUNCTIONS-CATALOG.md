# Supabase Edge Functions - Production Catalog

*Last Updated: 2025-11-09*

This catalog documents production-ready Edge Functions that have proven successful and are recommended for reuse. Only battle-tested functions are included here.

---

## Table of Contents

1. [Nonprofit Data Processing](#nonprofit-data-processing)
2. [Payment & Stripe Integration](#payment--stripe-integration)
3. [Grants Management](#grants-management)
4. [Future Opportunities](#future-opportunities)

---

## Nonprofit Data Processing

### 1. Website Finder - Tavily API

**Function:** `process-nonprofits-tavily`
**Created:** 2025-11-08
**Status:** ✅ Production
**Last Updated:** 2025-11-09

#### Purpose
Automatically discovers and validates websites for nonprofit organizations using the Tavily Search API. Designed for parallel processing with row-level database locking.

#### Success Metrics
- **Records Processed:** 126,759 nonprofits
- **Success Rate:** 99.77%
- **Websites Found:** 126,467
- **Failed:** 292 (0.23%)
- **Cost:** ~$261 total ($0.0075 per search)
- **Processing Time:** ~3 hours with 15 parallel workers

#### Key Features
- PostgreSQL `FOR UPDATE SKIP LOCKED` for parallel processing
- Tavily API integration for intelligent search
- Automatic retry and error handling
- Status tracking (PENDING → PROCESSING → COMPLETE)
- Rate limiting (100ms between searches)
- Domain blacklist (guidestar, charitynavigator, etc.)

#### When to Reuse
**Perfect for:**
- Monthly processing of new nonprofits added to database
- Finding websites for organizations lacking online presence
- Validating/updating existing website URLs
- Any scenario requiring intelligent web search for entities

**Example Monthly Schedule:**
```typescript
// Cron job: Run first day of each month
// Finds websites for any new nonprofits added in past 30 days
{
  "schedule": "0 0 1 * *",  // 12am on 1st of month
  "processorId": 1,
  "batchSize": 50
}
```

#### How to Invoke
```bash
# Single batch (10 records)
curl -X POST "https://hjtvtkffpziopozmtsnb.supabase.co/functions/v1/process-nonprofits-tavily" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"processorId": 1, "batchSize": 10}'

# Parallel processing (15 workers recommended)
for i in {1..15}; do
  curl -X POST "URL" -d "{\"processorId\": $i, \"batchSize\": 50}" &
done
```

#### Required Database Function
```sql
CREATE OR REPLACE FUNCTION get_pending_nonprofits(batch_size INTEGER DEFAULT 10)
RETURNS TABLE (
  id UUID,
  ein_charity_number TEXT,
  name TEXT,
  city TEXT,
  state_province TEXT,
  public_facing BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  UPDATE nonprofits n
  SET status = 'PROCESSING',
      processing_started_at = NOW()
  WHERE n.id IN (
    SELECT np.id
    FROM nonprofits np
    WHERE np.status = 'PENDING'
      AND np.public_facing = true
      AND np.website IS NULL
    LIMIT batch_size
    FOR UPDATE SKIP LOCKED
  )
  RETURNING
    n.id,
    n.ein_charity_number,
    n.name,
    n.city,
    n.state_province,
    n.public_facing;
END;
$$ LANGUAGE plpgsql;
```

#### Environment Variables Required
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
TAVILY_API_KEY=tvly-your-api-key
```

#### Code Location
**Edge Function:** `/supabase/functions/process-nonprofits-tavily/index.ts`

---

### 2. Location Data Extractor

**Function:** `extract-location-data`
**Created:** 2025-11-09
**Status:** ✅ Production
**Last Updated:** 2025-11-09

#### Purpose
Extracts city and state/province from the `contact_info` JSONB field and populates dedicated columns for faster queries and filtering.

#### Success Metrics
- **Processing Speed:** 5,000 records per batch
- **Efficiency:** Zero API costs (pure database operation)
- **Reliability:** 100% success rate on valid JSON

#### Key Features
- Batch processing (5,000 records at a time)
- Handles NULL and malformed JSON gracefully
- Only processes records where `city` or `state_province` is NULL
- Status-aware (only processes PENDING records)
- Automatic completion when no more records found

#### When to Reuse
**Perfect for:**
- Initial data import when JSON contains structured location data
- Migrating data from JSON to normalized columns
- Periodic cleanup to ensure location columns are populated
- After bulk imports where contact_info contains addresses

**Example Use Case:**
```typescript
// After importing 100K new records with contact_info JSON
// Run this to extract location to dedicated columns
// Makes city/state filtering 100x faster than JSON queries
```

#### How to Invoke
```bash
# Process all pending records (auto-batches)
curl -X POST "https://hjtvtkffpziopozmtsnb.supabase.co/functions/v1/extract-location-data" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json"
```

#### Expected Response
```json
{
  "success": true,
  "totalUpdated": 150000,
  "message": "Extracted location data for 150,000 records"
}
```

#### Code Location
**Edge Function:** `/supabase/functions/extract-location-data/index.ts`

---

## Payment & Stripe Integration

### 3. Stripe Checkout Session Creator

**Function:** `create-checkout-session`
**Created:** 2025-01-24
**Status:** ✅ Production
**Version:** 20

#### Purpose
Creates Stripe checkout sessions for subscription payments with proper metadata tracking.

#### When to Reuse
- Accepting payments for subscription services
- Creating payment flows for tiered pricing
- Processing one-time or recurring payments

---

### 4. Stripe Webhook Handler

**Function:** `stripe-webhook`
**Created:** 2025-01-26
**Status:** ✅ Production
**Version:** 16

#### Purpose
Handles Stripe webhook events for payment confirmations, subscription updates, and cancellations.

#### When to Reuse
- Processing payment confirmations
- Handling subscription lifecycle events
- Updating database based on Stripe events

---

## Grants Management

### 5. Grants.gov Data Extractor

**Function:** `grants-gov-api-extractor`
**Created:** 2025-01-31
**Status:** ✅ Production
**Version:** 10

#### Purpose
Extracts grant opportunity data from Grants.gov API and stores in database.

#### When to Reuse
- Periodic grant opportunity discovery
- Building grant databases
- Monitoring new funding opportunities

---

## Future Opportunities

### Nonprofit Classification Edge Function (RECOMMENDED)

**Status:** 🔨 Not Yet Built (Currently Python Script)
**Priority:** HIGH
**Estimated Effort:** 2-3 hours

#### Why Build This
The current classification system (public-facing vs not public-facing) is a Python script that processes 583K records with:
- 99% keyword-based classification (free)
- 1% LLM validation (Claude Haiku)
- $63 total cost for full dataset
- 2.7 hours with 10 parallel workers

**This should be an Edge Function for:**
1. **Monthly automation** - Classify new nonprofits added to database
2. **On-demand classification** - Trigger from UI when user adds records
3. **Scheduled cron jobs** - Run automatically without manual intervention
4. **Better logging** - Centralized logs in Supabase dashboard

#### Proposed Architecture
```typescript
// Edge Function: classify-nonprofits
// Input: { batchSize: 100, useKeywordsOnly: false }
//
// 1. Fetch NULL public_facing records (FOR UPDATE SKIP LOCKED)
// 2. Run enhanced keyword classifier (90+ keywords)
// 3. For uncertain cases (confidence < 0.7), call Claude Haiku
// 4. Update database with classification + confidence + method
// 5. Track cost and statistics
```

#### Estimated Cost
- Per record: $0.00011 (only for LLM-validated cases)
- Monthly (assuming 1,000 new records): ~$0.11
- Yearly: ~$1.32

#### Code to Adapt
**Source:** `/tmp/classify_nonprofits_enhanced.py` (keyword classifier)
**Source:** `/tmp/classify-parallel.py` (parallel processing logic)

#### When to Build
**Trigger:** When you want to automate classification monthly or need on-demand classification from the UI.

---

## Deployment Checklist

When deploying a new Edge Function:

- [ ] Set required environment variables in Supabase dashboard
- [ ] Test with single record/batch first
- [ ] Verify database functions exist (e.g., `get_pending_nonprofits`)
- [ ] Check logs for errors: `supabase functions logs FUNCTION_NAME`
- [ ] Monitor cost for API-based functions
- [ ] Set up cron schedule if needed
- [ ] Document in this catalog with success metrics

---

## Quick Reference

### Most Used Functions

| Function | Purpose | Cost | Success Rate |
|----------|---------|------|--------------|
| `process-nonprofits-tavily` | Website discovery | $0.0075/search | 99.77% |
| `extract-location-data` | Location extraction | Free | 100% |
| `create-checkout-session` | Payment processing | Stripe fees | N/A |

### Function Naming Convention

- **Verb-noun format:** `process-`, `extract-`, `create-`, `discover-`
- **Descriptive:** Function name should explain what it does
- **No version numbers:** Update same function, don't create v2/v3

### Environment Variables

All production functions require:
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-key-here
```

Additional keys as needed:
```bash
TAVILY_API_KEY=tvly-key          # For website search
ANTHROPIC_API_KEY=sk-ant-key     # For LLM classification
STRIPE_SECRET_KEY=sk_live_key    # For payments
```

---

## Getting Help

**View Function Logs:**
```bash
supabase functions logs process-nonprofits-tavily --project-ref hjtvtkffpziopozmtsnb
```

**Test Locally:**
```bash
supabase functions serve process-nonprofits-tavily --env-file .env.local
```

**Deploy Updates:**
```bash
supabase functions deploy process-nonprofits-tavily --project-ref hjtvtkffpziopozmtsnb
```

---

**Related Documentation:**
- [N8N Workflow Knowledge Base](../n8n-workflow/N8N-WORKFLOW-KNOWLEDGE-BASE.md)
- [Supabase Workflow Architecture](../SUPABASE-WORKFLOW-ARCHITECTURE.md)
