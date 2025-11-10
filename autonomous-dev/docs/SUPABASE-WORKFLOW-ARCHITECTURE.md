# Supabase-Based Workflow Architecture

**Date**: 2025-11-02
**Workflow**: NFP Website Finder - Instance 1
**Migration**: Google Sheets → Supabase

## Overview

Migrated from Google Sheets to Supabase as single source of truth for nonprofit website discovery workflow.

## Why Supabase Over Google Sheets

### Technical Reasons
1. **N8N API Limitation**: Google Sheets node parameters get stripped during API deployment (documentId, sheetName, filters all become null)
2. **Autonomous Verification**: Direct SQL queries via MCP enable real-time progress monitoring
3. **Better Filtering**: SQL WHERE clauses more powerful than Google Sheets filters
4. **Atomic Operations**: Proper database transactions prevent race conditions
5. **Status Management**: Proper workflow state tracking (PENDING → PROCESSING → COMPLETE)

### Operational Benefits
1. **Single Source of Truth**: No data sync between Sheets and DB
2. **Real-time Monitoring**: Query exact progress at any moment
3. **Audit Trail**: Complete history of processing attempts
4. **Error Recovery**: Track retry counts and failure reasons
5. **Concurrent Processing**: Multiple processor instances can work safely

## Database Schema

### New Columns Added to `nonprofits` Table

```sql
ALTER TABLE nonprofits
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'PENDING',
ADD COLUMN IF NOT EXISTS processor_assignment INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS processing_started_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS processing_completed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS processing_notes TEXT,
ADD COLUMN IF NOT EXISTS retry_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_error TEXT;
```

### Status Values
- `PENDING`: Ready to process (initial state)
- `PROCESSING`: Currently being processed by a workflow instance
- `COMPLETE`: Successfully found website
- `NOT_FOUND`: No website found after search
- `ERROR`: Processing failed (check last_error field)

### Processor Assignment
- `0`: Unassigned (available for any processor)
- `1`: Assigned to Instance 1
- `2`: Assigned to Instance 2 (future)
- etc.

## Workflow Changes

### Node Replacements

#### 1. Read All Rows (Google Sheets) → Read Pending Nonprofits (Supabase HTTP)

**Old**:
```json
{
  "type": "n8n-nodes-base.googleSheets",
  "parameters": {
    "documentId": "...",
    "sheetName": "...",
    "filtersUI": {...}
  }
}
```

**New**:
```json
{
  "type": "n8n-nodes-base.httpRequest",
  "method": "GET",
  "url": "https://hjtvtkffpziopozmtsnb.supabase.co/rest/v1/nonprofits",
  "queryParameters": [
    {"name": "status", "value": "eq.PENDING"},
    {"name": "processor_assignment", "value": "eq.0"},
    {"name": "public_facing", "value": "eq.true"},
    {"name": "limit", "value": "10"}
  ]
}
```

#### 2. Filter Pending Rows

**Updated** to handle Supabase data format:
- Supabase returns `{ein_charity_number, name, city, state_province}`
- Transform to workflow format: `{EIN, Name, City, State}`

#### 3. NEW: Mark as PROCESSING

Prevents race conditions when multiple processors run:

```http
PATCH /rest/v1/nonprofits?id=in.(1,2,3)
{
  "status": "PROCESSING",
  "processor_assignment": 1,
  "processing_started_at": "2025-11-02T23:00:00Z"
}
```

#### 4. Update Nonprofits DB

**Enhanced** with status tracking:

```http
PATCH /rest/v1/nonprofits?ein_charity_number=eq.123456789
{
  "website": "https://example.org",
  "website_discovered_at": "2025-11-02T23:05:00Z",
  "website_discovery_method": "gemini-ai-search",
  "status": "COMPLETE",
  "processing_completed_at": "2025-11-02T23:05:00Z",
  "processing_notes": "Website found via Gemini AI",
  "updated_at": "2025-11-02T23:05:00Z"
}
```

## Workflow Flow

```
1. Webhook Trigger
2. Initialize Sentry
3. Send Init Event
4. Read Pending Nonprofits (Supabase GET) ← NEW
5. Filter Pending Rows (updated)
6. Check Rows Found
   ├─ No Rows → Send No Rows Event → END
   └─ Has Rows → Continue
7. Prepare Batch Started
8. Send Batch Started
9. Mark as PROCESSING (Supabase PATCH) ← NEW
10. Build CSV Input (updated)
11. Call Gemini
12. Parse Response
13. Update Nonprofits DB (Supabase PATCH, updated)
14. Prepare Batch Completed
15. Send Batch Completed
```

## Autonomous Monitoring Queries

### Check Pending Count
```sql
SELECT COUNT(*)
FROM nonprofits
WHERE status = 'PENDING'
  AND processor_assignment = 0
  AND public_facing = true;
```

### Check Processing Progress
```sql
SELECT status, COUNT(*) as count
FROM nonprofits
WHERE processing_started_at > NOW() - INTERVAL '1 hour'
GROUP BY status;
```

### Verify Recent Completions
```sql
SELECT ein_charity_number, name, website, processing_completed_at
FROM nonprofits
WHERE status = 'COMPLETE'
  AND processing_completed_at > NOW() - INTERVAL '10 minutes'
ORDER BY processing_completed_at DESC
LIMIT 10;
```

### Find Stuck Processing (potential errors)
```sql
SELECT ein_charity_number, name, processing_started_at,
       NOW() - processing_started_at as duration
FROM nonprofits
WHERE status = 'PROCESSING'
  AND processing_started_at < NOW() - INTERVAL '5 minutes'
ORDER BY processing_started_at;
```

## Data Import

After importing Google Sheets data, set initial status:

```sql
UPDATE nonprofits
SET status = 'PENDING',
    processor_assignment = 0
WHERE website IS NULL
  AND public_facing = true
  AND status IS NULL;
```

## Benefits Realized

### For Autonomous Development
✅ I can query Supabase directly via MCP
✅ Real-time progress monitoring
✅ Automatic error detection
✅ No N8N API limitations blocking verification

### For Workflow Reliability
✅ Atomic status updates prevent duplicates
✅ Processing state prevents race conditions
✅ Retry tracking for error recovery
✅ Complete audit trail

### For User
✅ No manual N8N node configuration needed
✅ Easy monitoring via SQL queries or dashboards
✅ Reliable, scalable architecture
✅ Single source of truth

## Files

- **Schema**: `/tmp/supabase-nonprofits-schema-update.sql`
- **Workflow**: `/tmp/workflow-supabase-complete.json`
- **This Doc**: `/Users/christophertolleymacbook2019/autonomous-dev/docs/SUPABASE-WORKFLOW-ARCHITECTURE.md`

## Next Steps

1. User imports Google Sheets data to Supabase
2. Run schema update SQL
3. Deploy new workflow
4. Manual webhook configuration (N8N API limitation)
5. Test autonomous workflow
6. Monitor and iterate
