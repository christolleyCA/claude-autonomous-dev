# 🚀 Import 210,598 New Nonprofits - Quick Guide

## Step 1: Get Your Database Password

1. Go to: https://supabase.com/dashboard/project/hjtvtkffpziopozmtsnb/settings/database
2. Scroll to **"Database password"** section
3. Copy your password (or reset it if you don't have it)

## Step 2: Run the Import Script

Open Terminal and run:

```bash
# Set your password (replace with actual password)
export PGPASSWORD='your-password-here'

# Run the import script
~/apply-nonprofit-batches.sh
```

**That's it!** The script will:
- Apply all 22 batch files automatically
- Show progress for each batch
- Handle duplicates automatically (ON CONFLICT DO NOTHING)
- Take approximately 3-5 minutes total
- Verify the final count

## What You'll See

```
🚀 Starting nonprofit batch import...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Found 22 batch files to process

📦 Batch 1/22 (3.1M)...
   ✅ SUCCESS
📦 Batch 2/22 (3.1M)...
   ✅ SUCCESS
...
```

## After Import - Verify Results

Run this query in Supabase SQL Editor:

```sql
SELECT
  COUNT(*) as total_nonprofits,
  COUNT(*) FILTER (WHERE DATE(created_at) >= '2025-10-22') as recent_imports,
  COUNT(website) as nonprofits_with_websites,
  ROUND(COUNT(website)::numeric / COUNT(*)::numeric * 100, 1) as website_coverage_pct
FROM nonprofits;
```

**Expected Results:**
- Total nonprofits: ~937,650 (was 727K, adding 210K)
- Website coverage: ~54% (improved from 51%)

## Troubleshooting

### "psql: command not found"
Install PostgreSQL client:
```bash
brew install postgresql
```

### "password authentication failed"
- Your password is incorrect
- Reset it in Supabase dashboard (Step 1 above)

### Script stops or hangs
- Press `Ctrl+C` to stop
- Check which batch failed from the output
- You can restart the script - duplicates will be skipped automatically

## Files Being Applied

- `~/nonprofit_sql_inserts/batch_1.sql` through `batch_22.sql`
- Total: 210,598 nonprofit records
- All include: name, website, contact info, revenue, tax status
- **All have correct names** (no tax preparer corruption)

## Next Steps After Import

Once the import completes, we'll move on to:
1. ✅ Verify import was successful
2. 🔍 Identify sources for the remaining 514K corrupted names
3. 🔨 Fix the remaining corrupted names
4. ✅ Final data quality verification

---

**Questions?** Let me know if you hit any issues!
