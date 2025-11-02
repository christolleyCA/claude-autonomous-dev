# Sentry N8N Workflow Integration Map

**Visual guide showing exactly where to place Sentry tracking nodes**

---

## 📍 Workflow Structure with Sentry Nodes

```
┌─────────────────────────────────────────────────────────────┐
│                    NFP WEBSITE FINDER WORKFLOW                │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  START                                                        │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  🔧 Sentry Helper              │  ◄─── SNIPPET 1: Initialize Sentry
│  (Code Node)                   │       Place FIRST in workflow
│  - Initialize Sentry tracker   │
│  - Set DSN, environment        │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  Get Rows from Google Sheets   │
│  (Google Sheets Node)          │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  Prepare Batch Data            │
│  (Code Node)                   │
│  - processor_id = "processor-1"│
│  - total_rows = 1000           │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  📊 Track Workflow Started     │  ◄─── SNIPPET 2: Workflow Started
│  (Code Node)                   │       Track workflow initialization
│  - Send workflow_started event │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  Split Into Batches            │
│  (SplitInBatches Node)         │
│  - Batch size: 50              │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  📊 Track Batch Started        │  ◄─── SNIPPET 3: Batch Started
│  (Code Node)                   │       Track each batch start
│  - Send batch_started event    │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  Process Each Row              │
│  (Item Lists Node)             │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  🔍 Gemini API with Sentry     │  ◄─── SNIPPET 4: Gemini API Call
│  (Code Node - REPLACE EXISTING)│       Track API performance
│  - Call Gemini API             │       Record tokens, duration
│  - Track performance           │
│  - Handle errors               │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  Extract Website URL           │
│  (Code Node)                   │
│  - Parse Gemini response       │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  Update Google Sheets          │
│  (Google Sheets Node)          │
│  - Write website URL           │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  Calculate Batch Metrics       │
│  (Code Node)                   │
│  - rows_processed              │
│  - success_count               │
│  - duration_seconds            │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  📊 Track Batch Completed      │  ◄─── SNIPPET 5: Batch Completed
│  (Code Node)                   │       Track batch metrics
│  - Send batch_completed event  │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  Check Milestone               │
│  (IF Node)                     │
│  - If total % 100 === 0        │
└────────┬───────────┬───────────┘
         │           │
         │ YES       │ NO
         ▼           ▼
    ┌────────┐   ┌──────┐
    │Milestone│   │Skip  │
    └────┬───┘   └──┬───┘
         │          │
         ▼          │
    ┌────────────┐ │
    │ 📊 Track   │ │  ◄─── SNIPPET 6: Milestone
    │ Milestone  │ │       Track progress markers
    └────┬───────┘ │
         │         │
         └────┬────┘
              │
              ▼
     ┌────────────────┐
     │  Loop Back     │
     │  (If more      │
     │   batches)     │
     └────────┬───────┘
              │
              ▼
┌────────────────────────────────┐
│  Calculate Final Metrics       │
│  (Code Node)                   │
│  - total_processed             │
│  - success_rate                │
│  - duration_minutes            │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  📊 Track Workflow Completed   │  ◄─── SNIPPET 8: Workflow Completed
│  (Code Node)                   │       Track final stats
│  - Send workflow_completed     │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│  Send Summary Email (Optional) │
│  (Email Node)                  │
└────────────┬───────────────────┘
             │
             ▼
          ┌──────┐
          │ END  │
          └──────┘


════════════════════════════════════════════════════════════════

                      ERROR HANDLING PATH

════════════════════════════════════════════════════════════════

           ┌─────────────────────┐
           │  Any Node Fails     │
           └──────────┬──────────┘
                      │
                      ▼
           ┌─────────────────────┐
           │  Error Trigger      │
           │  (Error Workflow)   │
           └──────────┬──────────┘
                      │
                      ▼
           ┌─────────────────────┐
           │  Capture Error      │  ◄─── SNIPPET 7: Error Tracking
           │  Details            │       Track all failures
           │  (Code Node)        │
           └──────────┬──────────┘
                      │
                      ▼
           ┌─────────────────────┐
           │  📊 Track Error     │
           │  (Code Node)        │
           │  - Send to Sentry   │
           └──────────┬──────────┘
                      │
                      ▼
           ┌─────────────────────┐
           │  Log to Sheets      │
           │  (Optional)         │
           └──────────┬──────────┘
                      │
                      ▼
           ┌─────────────────────┐
           │  Send Alert Email   │
           │  (Optional)         │
           └─────────────────────┘
```

---

## 🎯 Implementation Checklist

### Phase 1: Core Setup (Essential)
- [ ] Add **Sentry Helper** node (Snippet 1) - FIRST node
- [ ] Add **Track Workflow Started** (Snippet 2) - After data prep
- [ ] Add **Track Workflow Completed** (Snippet 8) - Last node
- [ ] Add **Track Error** (Snippet 7) - In error workflow
- [ ] Test with 10 rows
- [ ] Verify events in Sentry

### Phase 2: Performance Tracking (Recommended)
- [ ] Replace Gemini API call with **Gemini API with Sentry** (Snippet 4)
- [ ] Add **Track Batch Started** (Snippet 3) - Before each batch
- [ ] Add **Track Batch Completed** (Snippet 5) - After each batch
- [ ] Test with 50 rows
- [ ] Check performance metrics in Sentry

### Phase 3: Progress Tracking (Optional)
- [ ] Add milestone checker (IF node)
- [ ] Add **Track Milestone** (Snippet 6) - Every 100/500/1000 rows
- [ ] Test with full dataset
- [ ] Review milestone events in Sentry

---

## 📊 Expected Event Flow

For a workflow processing 1000 rows in batches of 50:

```
Event Timeline (20 batches × 50 rows):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. workflow_started         (1 event)
2. batch_started           (20 events - one per batch)
3. gemini_api_call        (1000 events - one per row)
4. batch_completed         (20 events)
5. milestone_reached       (10 events - at 100, 200, ..., 1000)
6. workflow_completed      (1 event)

Total Expected Events: ~1,051 events
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Note:** If this seems like too many events, you can:
- Sample API calls (track 10% instead of 100%)
- Remove batch tracking for small workflows
- Focus on errors and milestones only

---

## 🔍 Debugging Your Integration

### Test Each Phase Separately

#### Test 1: Sentry Helper Initialization
```javascript
// After Sentry Helper node, add a simple test:
const sentry = $('Sentry Helper').item.json.sentry;
console.log('Sentry initialized:', sentry ? 'YES' : 'NO');
return $input.all();
```

#### Test 2: Simple Event Tracking
```javascript
// Send a test event:
const sentry = $('Sentry Helper').item.json.sentry;
await sentry.trackEvent('test_event', {
  tags: { test: 'true' },
  extra: { message: 'Testing Sentry integration' }
});
return $input.all();
```

#### Test 3: Error Tracking
```javascript
// Send a test error:
const sentry = $('Sentry Helper').item.json.sentry;
await sentry.trackError(new Error('Test error'), {
  error_type: 'test',
  tags: { test: 'true' }
});
return $input.all();
```

---

## 💡 Best Practices

### DO ✅
- Place Sentry Helper as the FIRST node
- Use consistent processor_id across all events
- Track errors in error workflows
- Test with small batches first
- Review Sentry data after first run

### DON'T ❌
- Don't block workflow on Sentry failures (use try/catch)
- Don't track every single event (use sampling for high-volume)
- Don't forget to update DSN in production
- Don't skip error tracking (it's the most valuable!)

---

## 🎓 Understanding Node Connections

Each tracking node should:
1. **Accept input** from previous node
2. **Call Sentry** asynchronously
3. **Return input** unchanged (pass-through)

```javascript
// Template for all tracking nodes:
const sentry = $('Sentry Helper').item.json.sentry;

// Do Sentry tracking
await sentry.trackEvent('event_name', { /* data */ });

// ALWAYS return input unchanged
return $input.all();
```

This ensures tracking doesn't interrupt your workflow!

---

## 📞 Need Help?

**Files to reference:**
- Complete guide: `docs/NFP-WEBSITE-FINDER-SENTRY-SETUP.md`
- Code snippets: `config/sentry-n8n-snippets.js`
- Quick start: `docs/SENTRY-QUICK-START.md`

**Sentry Dashboard:**
https://oxfordshire-inc.sentry.io/projects/nfp-website-finder/

---

**Happy Tracking!** 📊
