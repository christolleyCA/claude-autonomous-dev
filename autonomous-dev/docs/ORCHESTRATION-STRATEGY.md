# Orchestration Strategy - When to Use What

*Last Updated: 2025-11-09*

## Quick Decision Guide

```
Need to orchestrate workflows? Choose based on:

├─ Is it data processing/batch work?
│  └─ ✅ Use Supabase Edge Functions
│
├─ Need complex UI-driven workflows with many steps?
│  └─ ⚠️  Consider N8N (but try Edge Functions first)
│
├─ Need scheduled cron jobs?
│  └─ ✅ Use Supabase Edge Functions (native cron support)
│
└─ Need real-time webhooks?
   └─ ✅ Use Supabase Edge Functions
```

---

## Primary Recommendation: Supabase Edge Functions

### Why Edge Functions First?

1. **Native Integration**: Direct database access, no API overhead
2. **Parallel Processing**: Built-in support with `FOR UPDATE SKIP LOCKED`
3. **Cost Effective**: Only pay for execution time
4. **Type Safety**: TypeScript with full IDE support
5. **Easy Deployment**: `supabase functions deploy`
6. **Better Logging**: Centralized in Supabase dashboard

### Proven Use Cases

| Function | Records Processed | Success Rate | Cost |
|----------|-------------------|--------------|------|
| `process-nonprofits-tavily` | 126,759 | 99.77% | $261 |
| `extract-location-data` | 150,000 | 100% | $0 |
| Classification (proposed) | 751,000 | 99%+ | ~$63 |

---

## When to Use Supabase Edge Functions

### ✅ Perfect For:

**1. Batch Data Processing**
- Processing large datasets (thousands to millions of records)
- API integrations (Tavily, Anthropic, Stripe, etc.)
- Data transformations and migrations
- Automated cleanup and maintenance

**Example:**
```typescript
// process-nonprofits-tavily
// Processes 100 nonprofits per batch using Tavily API
// Designed for parallel processing with 15 workers
```

**2. Scheduled Automation**
- Monthly data processing (1st of each month)
- Daily cleanups and maintenance
- Weekly report generation
- Periodic API syncs

**Example:**
```bash
# Cron schedule in Supabase
"0 0 1 * *"  # Run on 1st of month at midnight
```

**3. Webhook Handlers**
- Stripe payment confirmations
- GitHub webhook processing
- External API callbacks
- Real-time event handling

**4. Database Operations**
- Complex queries spanning multiple tables
- Row-level processing with locks
- Transaction management
- Data validation and cleanup

---

## When to Use N8N

### ⚠️ Consider Only When:

**1. Rapid Prototyping**
- Need visual workflow editor for quick testing
- Non-technical team members need to modify workflows
- Exploring API integrations before coding them

**2. Complex Multi-Step UI Workflows**
- Workflows with 20+ distinct steps
- Heavy branching logic (if/else paths)
- Need to switch between many different services

**3. No-Code Requirements**
- Business users need to manage workflows
- Frequent workflow changes by non-developers
- Integration with services that don't have good APIs

### ❌ Avoid N8N For:

- Data processing at scale (use Edge Functions instead)
- Production-critical workflows (Edge Functions more reliable)
- Parallel processing (N8N doesn't handle well)
- Cost-sensitive operations (Edge Functions cheaper)

---

## When to Use Other Options

### Python Scripts (Temporary/Ad-Hoc)

**Use When:**
- One-time data migration
- Quick analysis or reporting
- Prototyping classification logic
- Testing API integrations

**Convert to Edge Function When:**
- Need to run monthly/regularly
- Workflow proves valuable
- Want better logging/monitoring
- Need to share with team

**Example Migration Path:**
```
1. Start: /tmp/classify-parallel.py (prototype)
2. Prove it works: Process 751K records successfully
3. Convert to Edge Function: classify-nonprofits (future)
4. Schedule: Cron job runs automatically monthly
```

### Bash Scripts (Automation Wrappers)

**Use When:**
- Need to invoke Edge Functions in parallel
- Orchestrating multiple CLI commands
- Local development automation

**Example:**
```bash
# process-all-tavily-parallel.sh
# Invokes Edge Function with 15 parallel workers
for i in {1..15}; do
  curl -X POST "edge-function-url" -d "{\"processorId\": $i}" &
done
```

---

## Migration Strategy

### From N8N to Edge Functions

**Step 1: Identify Workflow**
- Document what the N8N workflow does
- List all API calls and database operations
- Note success/failure rates

**Step 2: Create Edge Function**
```typescript
// Edge Function mirrors N8N logic
// But with better error handling and logging
```

**Step 3: Test in Parallel**
- Run both N8N and Edge Function simultaneously
- Compare results
- Monitor success rates

**Step 4: Switch Over**
- Disable N8N workflow
- Point production to Edge Function
- Monitor for issues

**Step 5: Document**
- Update Edge Functions catalog
- Add to automation scripts
- Share with team

### From Python to Edge Functions

**Step 1: Extract Core Logic**
- Pull out classification/processing logic
- Identify API dependencies
- Note required environment variables

**Step 2: Port to TypeScript**
```typescript
// Convert Python logic to TypeScript
// Add proper type definitions
```

**Step 3: Add Database Integration**
- Use `FOR UPDATE SKIP LOCKED` for parallelism
- Add proper error handling
- Implement retry logic

**Step 4: Deploy and Test**
- Test with small batch first
- Verify results match Python version
- Scale up gradually

---

## Current Architecture

### Production Workflows (Supabase Edge Functions)

1. **Website Discovery**
   - Function: `process-nonprofits-tavily`
   - Trigger: Manual or scheduled
   - Parallelism: 15 workers
   - Status: ✅ Production

2. **Location Extraction**
   - Function: `extract-location-data`
   - Trigger: After data imports
   - Parallelism: Single execution (batches internally)
   - Status: ✅ Production

3. **Payment Processing**
   - Functions: `create-checkout-session`, `stripe-webhook`
   - Trigger: Real-time webhooks
   - Status: ✅ Production

### Transitioning to Edge Functions

1. **Classification** (Currently Python)
   - Current: `/tmp/classify-parallel.py`
   - Future: `classify-nonprofits` Edge Function
   - Priority: HIGH
   - Effort: 2-3 hours

### Legacy (N8N)

1. **Website Finder (OLD)**
   - Status: ⚠️ Deprecated (use Edge Function instead)
   - Issues: Webhook 404 errors, harder to maintain
   - Migration: Complete ✅

---

## Best Practices

### For Edge Functions

**1. Use Database Functions for Batch Selection**
```sql
CREATE FUNCTION get_pending_records(batch_size INT)
-- Use FOR UPDATE SKIP LOCKED for parallelism
```

**2. Implement Proper Status Tracking**
```
PENDING → PROCESSING → COMPLETE
         ↓
        FAILED (with retry logic)
```

**3. Add Comprehensive Logging**
```typescript
console.log(JSON.stringify({
  event: 'batch_processed',
  recordsProcessed: 100,
  cost: 0.75,
  processorId: 1
}));
```

**4. Handle Errors Gracefully**
```typescript
try {
  // Process batch
} catch (error) {
  // Mark as failed, enable retry
  // Log error details
}
```

### For N8N (When Necessary)

**1. Keep Workflows Simple**
- Maximum 10-15 nodes
- Avoid deep nesting
- Use descriptive names

**2. Add Error Handling**
- Set error workflows
- Enable retry logic
- Log failures

**3. Monitor Actively**
- Check execution history
- Set up alerts
- Review costs

---

## Decision Matrix

| Requirement | Edge Functions | N8N | Python Script |
|------------|----------------|-----|---------------|
| Parallel Processing | ✅ Excellent | ❌ Limited | ✅ Good |
| Cost Efficiency | ✅ Best | ⚠️ Moderate | ✅ Good |
| Type Safety | ✅ TypeScript | ❌ None | ⚠️ Optional |
| Deployment Speed | ✅ Instant | ⚠️ Manual | ⚠️ Manual |
| Logging | ✅ Centralized | ⚠️ Dashboard | ❌ Ad-hoc |
| Database Access | ✅ Native | ⚠️ API | ⚠️ API |
| Learning Curve | ⚠️ Moderate | ✅ Low | ✅ Low |
| Production Ready | ✅ Yes | ⚠️ Depends | ❌ No |
| Scheduling | ✅ Native cron | ✅ Built-in | ❌ External |

---

## Summary

**Default Choice:** Supabase Edge Functions

**When in doubt:** Start with Edge Functions. They're more reliable, cost-effective, and maintainable than alternatives.

**N8N:** Only for rapid prototyping or non-technical team management.

**Python Scripts:** Only for one-time operations or prototyping.

**Migration Path:** Always Python → Edge Functions (not Python → N8N)
