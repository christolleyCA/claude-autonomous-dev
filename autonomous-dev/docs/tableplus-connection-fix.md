# TablePlus Connection Fix for Supabase

## Get Your FULL Connection String

1. Go to: https://supabase.com/dashboard/project/hjtvtkffpziopozmtsnb/settings/database
2. Scroll to "Connection string" section
3. Copy the **"Connection pooling"** string (NOT the direct connection)

It will look like:
```
postgresql://postgres.hjtvtkffpziopozmtsnb:[YOUR-PASSWORD]@aws-0-ca-central-1.pooler.supabase.com:6543/postgres
```

## In TablePlus

**IMPORTANT: Use these settings:**

1. **Host:** `aws-0-ca-central-1.pooler.supabase.com` (NOT db.hjtvtkffpziopozmtsnb.supabase.co)
2. **Port:** `6543` (NOT 5432)
3. **User:** `postgres.hjtvtkffpziopozmtsnb` (NOT just postgres)
4. **Password:** Your database password
5. **Database:** `postgres`
6. **Enable SSL:** YES ✅

Then click "Test" and it should connect!

---

## Alternative: If TablePlus Still Doesn't Work

Just use the Supabase SQL Editor (guaranteed to work):

1. Go to: https://supabase.com/dashboard/project/hjtvtkffpziopozmtsnb/sql
2. Click "New Query"
3. Open any of the batch files (they're small enough):
   - Start with `batch_1.sql`
4. Copy the entire contents
5. Paste into the SQL editor
6. Click "Run"
7. Repeat for batch_2 through batch_22

This will take about 20 minutes total but is 100% reliable.
