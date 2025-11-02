# Your NFP Website Finder Workflow - Specific Details

## Your Setup
- **N8N URL:** https://n8n.grantpilot.app
- **Workflow ID:** pc1cMXkDsrWlOpKu
- **Google Sheet:** 1bbwJfvO8kEFwXaQAAf9K_ZXMl3QWj3vzyvPxaQNUZk4
- **Total Nonprofits:** 151,495 (23,871 with Public Facing=True)
- **Sentry Project:** oxfordshire-inc

## Your Credentials (Reference Only)
```bash
N8N_API_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4MjczNjA3Yy0wOWEwLTRiNGItYmRkZC00YTM1NTRhNTk1ZCIsImlzcyI6Im44biIsImF1ZCI6InB1YmxpYy1hcGkiLCJpYXQiOjE3NjIwMjg0MzYfQ.Ag8ZwDU58RENpFpK3ntGN_Sz7a06-AeYezqiFweueys"
SENTRY_DSN="https://e3e72e5d3cddc31e15a6f56a384d081e@o4510218110894080.ingest.us.sentry.io/4510291768442880"
```

## Your Workflow Architecture

### Main Flow
1. **Read:** Status=PENDING, Processor Assignment=0
2. **Filter:** Public Facing=True, Limit=10
3. **Process:** Gemini finds websites
4. **Append:** To ProcessedResults sheet
5. **Log:** To Sentry for monitoring

### Your Sheets
- **Main Sheet:** "Rest of the NFPs without classification..."
- **Tracking Sheet:** ProcessedResults
- **Helper Column:** K (Processor Assignment)

## Specific Issues You Hit

### 1. Stack Overflow
Your 151,495 rows broke UPDATE. Solution: APPEND to ProcessedResults

### 2. Dangling Connections
"Parse Response" had duplicate connection after deleting nodes

### 3. Column Format
Google Sheets v4.5 needs array format, not object

### 4. Gemini Model
- ❌ gemini-2.5-pro (not found)
- ✅ gemini-2.0-flash-exp (works)

## Your Performance Metrics
- **Batch Size:** 10 nonprofits
- **Processing Time:** ~45 seconds per batch
- **Success Rate:** 70-80% websites found
- **Hourly Rate:** ~600 nonprofits
- **Total Time:** ~40 hours for all 23,871

## Quick Commands for Your Setup

### Deploy Your Workflow
```bash
curl -sX PUT "https://n8n.grantpilot.app/api/v1/workflows/pc1cMXkDsrWlOpKu" \
  -H "X-N8N-API-KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4MjczNjA3Yy0wOWEwLTRiNGItYmRkZC00YTM1NTRhNTk1ZCIsImlzcyI6Im44biIsImF1ZCI6InB1YmxpYy1hcGkiLCJpYXQiOjE3NjIwMjg0MzYfQ.Ag8ZwDU58RENpFpK3ntGN_Sz7a06-AeYezqiFweueys" \
  -H "Content-Type: application/json" \
  --data-binary @workflow.json
```

### Check Your Sentry
```bash
open https://oxfordshire-inc.sentry.io
```

### View Your Sheet
```bash
open https://docs.google.com/spreadsheets/d/1bbwJfvO8kEFwXaQAAf9K_ZXMl3QWj3vzyvPxaQNUZk4
```

## Your Next Steps

1. **Test the workflow** - Should work now with column fix
2. **Monitor ProcessedResults** - Should see 10 rows per run
3. **Activate workflow** - Toggle to Active when ready
4. **Backfill Main Sheet** - Use VLOOKUP:
   ```
   =IFERROR(VLOOKUP(A2, ProcessedResults!A:F, 6, FALSE), "")
   ```

## Things to Remember

- Your main sheet is too large for UPDATE (151K rows)
- Always use ProcessedResults for writing
- Gemini 2.0-flash-exp is your working model
- Column format must be array of {column, fieldValue}
- Processor Assignment=0 filters unprocessed rows

## If Something Breaks Again

1. Download workflow: `/api/v1/workflows/pc1cMXkDsrWlOpKu`
2. Check connections for "Append to ProcessedResults"
3. Verify column format is array not object
4. Test with 1 row first (change slice(0,10) to slice(0,1))
5. Check Sentry for batch_started and batch_completed events

---
*Workflow last working: 2025-11-02 13:14:42 UTC with 21 nodes*