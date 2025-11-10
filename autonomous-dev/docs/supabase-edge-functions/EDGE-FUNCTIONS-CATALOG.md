# Supabase Edge Functions - Production Catalog

*Last Updated: 2025-11-10*

This catalog documents production-ready Edge Functions that have proven successful and are recommended for reuse. Only battle-tested functions are included here.

---

## Table of Contents

1. [Nonprofit Data Processing](#nonprofit-data-processing)
2. [Python Scripts & Utilities](#python-scripts--utilities)
3. [Payment & Stripe Integration](#payment--stripe-integration)
4. [Grants Management](#grants-management)
5. [Future Opportunities](#future-opportunities)

---

## Nonprofit Data Processing

### 1. Website Finder - Tavily API

**Function:** `process-nonprofits-tavily`
**Version:** 6
**Created:** 2025-11-08
**Status:** ✅ Production
**Last Updated:** 2025-11-10

#### Purpose
Automatically discovers and validates websites for nonprofit organizations using the Tavily Search API. Designed for parallel processing with row-level database locking.

#### Success Metrics
- **Session 1 (2025-11-08):**
  - Records Processed: 126,759 nonprofits
  - Success Rate: 99.77%
  - Websites Found: 126,467
  - Cost: ~$950.69 ($0.0075 per search)
  - Processing Time: ~3 hours with 15 parallel workers

- **Session 2 (2025-11-10):**
  - Records Processed: 72,826 nonprofits
  - Success Rate: 99.94%
  - Websites Found: 72,780
  - Cost: ~$546.20 ($0.0075 per search)
  - Processing Time: ~2 hours with 15 parallel workers

- **Total Cumulative:**
  - Records Processed: 199,585 nonprofits
  - Websites Found: 199,247
  - Total Cost: ~$1,496.89
  - Average Success Rate: 99.83%

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

#### Automated Parallel Processing Script
For processing all records with optimal parallelism:

**Script:** `process-all-tavily-parallel.sh`
**Location:** `/tmp/process-all-tavily-parallel.sh` (move to `~/claude-shared/autonomous-tools/`)

```bash
#!/bin/bash
# Process all public-facing nonprofits using 15 parallel processors
# Auto-stops when no more records available

API_URL="https://hjtvtkffpziopozmtsnb.supabase.co/functions/v1/process-nonprofits-tavily"
AUTH_KEY="YOUR_SERVICE_ROLE_KEY"

for i in {1..15}; do
  (
    batch=1
    while true; do
      response=$(curl -sX POST "$API_URL" \
        -H "Authorization: Bearer $AUTH_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"processorId\": $i, \"batchSize\": 100}")

      if echo "$response" | grep -q '"recordsProcessed":0'; then
        echo "[Processor $i] Finished after $batch batches"
        break
      fi

      batch=$((batch + 1))
      sleep 2
    done
  ) > "/tmp/tavily-processor-$i.log" 2>&1 &
  sleep 2
done

echo "✅ All 15 processors started!"
echo "Monitor: tail -f /tmp/tavily-processor-*.log"
```

**When to Use:**
- Monthly processing of newly classified nonprofits
- After bulk imports when many records need websites
- Automated overnight processing (set as cron job)

#### Required Database Function
```sql
CREATE OR REPLACE FUNCTION get_pending_nonprofits(batch_size INTEGER DEFAULT 10)
RETURNS TABLE (
  id UUID,                    -- ⚠️ MUST match table column type (UUID not BIGINT)
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
    WHERE (np.status IS NULL OR np.status = 'PENDING')  -- Handle both NULL and PENDING
      AND np.public_facing = true
      AND (np.website IS NULL OR np.website = '')
    LIMIT batch_size
    FOR UPDATE SKIP LOCKED  -- Critical for parallel processing
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

#### Troubleshooting

**Common Issue: "structure of query does not match function result type"**

**Symptom:** Edge function returns 500 errors, logs show:
```
Database fetch failed: structure of query does not match function result type
```

**Root Cause:** The RPC function `get_pending_nonprofits` has a type mismatch. This typically happens when:
- The function declares `id BIGINT` but the table has `id UUID`
- The function returns a column that doesn't exist or has wrong type

**Fix Applied (2025-11-10):**
```sql
-- Drop the old function (REQUIRED before recreating)
DROP FUNCTION IF EXISTS get_pending_nonprofits(integer);

-- Recreate with correct UUID type (not BIGINT)
CREATE OR REPLACE FUNCTION get_pending_nonprofits(batch_size INT)
RETURNS TABLE (
  id UUID,  -- CRITICAL: Must match nonprofits.id type
  ein_charity_number TEXT,
  name TEXT,
  city TEXT,
  state_province TEXT,
  public_facing BOOLEAN
)
-- ... rest of function
```

**Verification:**
After fixing, test with a small batch:
```bash
curl -X POST "$URL" -d '{"processorId": 1, "batchSize": 5}'
# Should return: "recordsProcessed": 5
```

**Prevention:**
Always verify table column types before creating RPC functions:
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'nonprofits';
```

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

## Python Scripts & Utilities

### 3. Nonprofit Public-Facing Classifier

**Script:** `classify-parallel.py`
**Status:** ✅ Production (Python Script)
**Created:** 2025-11-08
**Last Updated:** 2025-11-10
**Successfully Processed:** 583,668 records

#### Purpose
Classifies nonprofit organizations as "public-facing" or "not public-facing" using an intelligent hybrid approach: 99% keyword-based classification (free), 1% LLM validation for uncertain cases (Claude Haiku).

#### Success Metrics
- **Total Records Classified:** 583,668 nonprofits
- **Keyword Classification:** 99% (577,832 records)
- **LLM Validation:** 1% (5,836 records)
- **Total Cost:** $63.12
- **Processing Time:** 2.7 hours with 10 parallel workers
- **Cost per Record:** $0.000108
- **Accuracy:** ~98%+ based on spot checks

#### Key Features
- **Dual-method classification:**
  - Keyword matching with 90+ keywords and regex patterns
  - Confidence scoring (0.0-1.0)
  - LLM validation only for low-confidence cases (< 0.7)
- **Parallel processing:** 10 workers with automatic chunk distribution
- **Budget controls:** $30 per worker limit, automatic stop
- **Retry logic:** 3 attempts for network errors with exponential backoff
- **Progress tracking:** Real-time updates every 10 batches

#### Classification Logic

**PUBLIC-FACING Organizations:**
- Schools, universities, daycare centers
- Hospitals, clinics, nursing homes
- Museums, libraries, theaters
- Churches, temples, religious organizations
- Food banks, shelters, community centers
- Fire departments, emergency services
- Parks, zoos, botanical gardens
- Youth programs (Scouts, YMCA, Boys & Girls Clubs)

**NOT PUBLIC-FACING Organizations:**
- Employee benefit plans (VEBA, pensions, 401k trusts)
- Union funds (training trusts, welfare funds)
- Private foundations, donor-advised funds
- Title-holding corporations
- HOAs, condo associations
- Investment/endowment funds

#### How to Run

**Single Worker (for testing):**
```bash
export ANTHROPIC_API_KEY='your-key'
export SUPABASE_SERVICE_ROLE_KEY='your-key'

python3 /tmp/classify-parallel.py 0 0 1000
# worker_id=0, start_offset=0, chunk_size=1000
```

**Parallel Processing (10 workers):**
```bash
export ANTHROPIC_API_KEY='your-key'
export SUPABASE_SERVICE_ROLE_KEY='your-key'

for i in 0 1 2 3 4 5 6 7 8 9; do
  python3 -u /tmp/classify-parallel.py $i $((i * 60000)) 60000 \
    2>&1 | tee /tmp/classify-worker-$i.log &
done

echo "✅ Launched 10 parallel workers"
```

**Monitor Progress:**
```bash
# Watch all workers
tail -f /tmp/classify-worker-*.log

# Check specific worker
tail -f /tmp/classify-worker-0.log
```

#### Code Location
**Main Script:** `/tmp/classify-parallel.py`
**Keyword Classifier:** `/tmp/classify_nonprofits_enhanced.py`

#### When to Reuse
**Perfect for:**
- Monthly batch classification of newly imported nonprofits
- Re-classification after importing new datasets
- One-time bulk classification jobs
- Any scenario requiring cost-effective nonprofit categorization

**Example Monthly Schedule:**
```bash
# Classify new nonprofits added in past 30 days
# Run as cron job: 0 2 1 * * (2am on 1st of each month)
python3 classify-new-nonprofits.py
```

#### Dependencies
```bash
pip3 install anthropic supabase
```

#### Environment Variables
```bash
ANTHROPIC_API_KEY=sk-ant-your-key
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-key
```

#### Output Example
```
[Worker 0] 🚀 Starting parallel classification worker
[Worker 0] Range: 0 to 60000
[Worker 0] Budget: $30
[Worker 0] Progress: 50.0% | Processed: 30,000 | Cost: $3.24
[Worker 0] ✅ COMPLETE
[Worker 0] Processed: 58,367
[Worker 0] Keywords: 57,832
[Worker 0] LLM: 535
[Worker 0] Cost: $5.89
[Worker 0] DB updates: 58,367
```

#### Conversion to Edge Function
**Status:** Recommended for automation
**See:** [Future Opportunities](#future-opportunities) section below

---

## Payment & Stripe Integration

### 4. Stripe Checkout Session Creator

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

### 5. Stripe Webhook Handler

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

### 6. Grants.gov Data Extractor

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

## Nonprofit Data Processing (Edge Functions)

### 7. Nonprofit Public-Facing Classifier (Edge Function)

**Function:** `classify-nonprofits`
**Version:** 1
**Created:** 2025-11-10
**Status:** ✅ Production
**Last Updated:** 2025-11-10

#### Purpose
Edge Function version of the nonprofit classifier. Automatically classifies nonprofits as "public-facing" or "not public-facing" using hybrid approach: 99% keyword-based (free), 1% LLM validation (Claude Haiku).

#### Success Metrics (from Python version)
- **Cost per Record:** $0.000108
- **Keyword Classification:** 99%
- **LLM Validation:** 1%
- **Accuracy:** ~98%+

#### Key Features
- **Automated invocation:** Can be triggered via webhook, cron, or API
- **Same logic as Python version:** Uses identical keyword/LLM hybrid approach
- **Centralized logs:** All logs in Supabase dashboard
- **Configurable batch size:** Process 10-1000 records per invocation
- **Confidence threshold:** Configurable (default 0.7)

#### When to Use Edge Function vs Python Script
**Use Edge Function for:**
- Monthly automated classification of new records
- On-demand classification from UI
- Scheduled cron jobs (1st of each month)
- Small to medium batches (< 10K records)

**Use Python Script for:**
- Initial bulk classification (500K+ records)
- Maximum parallel processing (10 workers)
- Cost-sensitive large batches

#### How to Invoke

**Single Batch:**
```bash
curl -X POST "https://hjtvtkffpziopozmtsnb.supabase.co/functions/v1/classify-nonprofits" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"batchSize": 100}'
```

**Expected Response:**
```json
{
  "success": true,
  "recordsProcessed": 100,
  "keywordClassified": 99,
  "llmValidated": 1,
  "databaseUpdates": 100,
  "durationMs": 2500,
  "estimatedCost": 0.000108
}
```

**Scheduled Cron Job (monthly):**
```javascript
// Supabase Dashboard → Database → Cron Jobs
// Schedule: 0 2 1 * * (2am on 1st of each month)
SELECT net.http_post(
  url := 'https://hjtvtkffpziopozmtsnb.supabase.co/functions/v1/classify-nonprofits',
  headers := '{"Authorization": "Bearer YOUR_KEY", "Content-Type": "application/json"}'::jsonb,
  body := '{"batchSize": 1000}'::jsonb
);
```

#### Environment Variables Required
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-key
ANTHROPIC_API_KEY=sk-ant-your-key  # Optional, for LLM validation
```

#### Code Location
**Edge Function:** Deployed to Supabase (v1)
**Source:** `/tmp/classify-nonprofits-edge/index.ts`

#### Advantages Over Python Script
1. **No infrastructure needed:** Runs on Supabase, no server required
2. **Automated scheduling:** Built-in cron support
3. **Centralized logging:** All logs in Supabase dashboard
4. **API accessible:** Can be called from anywhere
5. **Zero maintenance:** Supabase handles scaling and updates

---

## Future Opportunities

### Additional Automation Ideas

**Note:** The nonprofit classifier Edge Function (originally recommended here) has now been built and deployed! See section 7 above.

#### Other Potential Automations
- **Grant matching engine:** Edge Function to match nonprofits with relevant grants
- **Website health checker:** Periodic verification that nonprofit websites are still active
- **Data freshness monitoring:** Alert when key nonprofit data becomes outdated

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
