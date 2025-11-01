# How to Apply All 211 Nonprofit Migrations

## Summary
- **Total nonprofits to add:** 210,598
- **Number of chunks:** 211
- **Each chunk contains:** ~1,000 nonprofits
- **Total estimated time:** 15-20 minutes

## Files Ready
All SQL files are in: `~/nonprofit_sql_inserts/chunk_001.sql` through `chunk_211.sql`

## Option 1: Use the Supabase Dashboard (EASIEST)

1. Go to https://supabase.com/dashboard/project/hjtvtkffpziopozmtsnb
2. Click "SQL Editor" in the left sidebar
3. For each chunk file (001 through 211):
   - Click "New Query"
   - Copy the contents of `~/nonprofit_sql_inserts/chunk_001.sql`
   - Paste into the SQL editor
   - Click "Run"
   - Wait for completion
   - Repeat for next chunk

## Option 2: Use Python Script with Direct API (RECOMMENDED)

I can create a Python script that uses the Supabase REST API directly. This would apply all chunks automatically.

## Option 3: Import via CSV

Since we still have the original CSV file at `~/Downloads/charities_domains_cleaned.csv`, we could:
1. Use Supabase's "Table Editor"
2. Click "Import Data from CSV"
3. Upload the CSV file
4. Map columns to the database schema
5. Let Supabase handle duplicates

## Current Database Status
- Before migration: 727,052 nonprofits
- After migration (estimated): ~771,976 nonprofits
- New website coverage: ~54% (up from 51.2%)

## What I've Done So Far
✅ Generated all 211 SQL chunk files with proper syntax
✅ Verified SQL syntax with ON CONFLICT clause
✅ Tested execution with mcp__supabase__execute_sql (works!)
✅ Files total 66MB of SQL

## Next Steps
Choose one of the options above to complete the migration!
