# 🔧 FIX CORRUPTED NONPROFIT NAMES

## The Problem
On Oct 22, 2025, **727,027 nonprofit records** were imported with the **WRONG NAMES**. Instead of organization names, they have tax preparer names (accountants/CPAs).

### Examples of Corruption:
- EIN 260418421: Shows "Wilkinson Hadley King & Co LLP" → Should be "Innovations Academy"
- EIN 352030346: Shows "CBIZ ADVISORS LLC" → Should be "Insight Development Corporation"

## The Solution
I've generated **255,433 UPDATE statements** to fix the names we have correct data for.

---

## ✅ EASIEST METHOD: Use Supabase SQL Editor

### Steps:
1. Go to: https://supabase.com/dashboard/project/hjtvtkffpziopozmtsnb/sql
2. Click "New Query"
3. Since the master file is 44MB, you'll need to apply in batches:

**Option A: Apply batch files (recommended)**
- Use the 11 batch files in `~/nonprofit_name_fixes/batch_fix_1.sql` through `batch_fix_11.sql`
- Each batch is 4.3MB (except last one is 960KB)
- Copy/paste each batch into SQL Editor and click "Run"
- Takes about 15-20 minutes total

**Option B: Apply individual chunks**
- Use the 52 chunk files in `~/nonprofit_name_fixes/fix_chunk_001.sql` through `fix_chunk_052.sql`
- Each chunk is ~180KB
- Copy/paste each chunk and click "Run"
- Takes about 45-60 minutes total

---

## ⚡ FASTEST METHOD: Use psql Command Line

```bash
# Get your database password from:
# https://supabase.com/dashboard/project/hjtvtkffpziopozmtsnb/settings/database

PGPASSWORD='your-password-here' psql \\
  -h aws-0-ca-central-1.pooler.supabase.com \\
  -p 6543 \\
  -U postgres.hjtvtkffpziopozmtsnb \\
  -d postgres \\
  -f ~/MASTER_name_fixes.sql
```

This will apply all 255,433 fixes in one command (takes 2-3 minutes).

---

## 🔍 What Will Be Fixed

- **Total records to fix:** 255,433 out of 727,027 (35%)
- **Why only 35%?** The CSV file only has names for these EINs. The remaining 471,594 records need a different data source.

### Examples of Fixes:
```sql
-- BEFORE:
name = "THE OPTIMAL FINANCIAL GROUP LLC"
website = "journeyofajoyfullife.com"  ❌ Doesn't match!

-- AFTER:
name = "Journey of a Joyful Life"
website = "journeyofajoyfullife.com"  ✅ Matches!
```

---

## ✅ Verification After Fix

Run this query to verify:

```sql
-- Check a few fixed records
SELECT ein_charity_number, name, website
FROM nonprofits
WHERE ein_charity_number IN ('260418421', '352030346', '460682168')
ORDER BY ein_charity_number;
```

Expected results:
- 260418421: "Innovations Academy" (not Wilkinson Hadley)
- 352030346: "Insight Development Corporation" (not CBIZ)
- 460682168: Should show correct org name (not Optimal Financial)

---

## 📊 Progress Tracking

### Batch Method (11 files):
- [ ] batch_fix_1.sql (chunks 1-5, ~25,000 updates)
- [ ] batch_fix_2.sql (chunks 6-10, ~25,000 updates)
- [ ] batch_fix_3.sql (chunks 11-15, ~25,000 updates)
- [ ] batch_fix_4.sql (chunks 16-20, ~25,000 updates)
- [ ] batch_fix_5.sql (chunks 21-25, ~25,000 updates)
- [ ] batch_fix_6.sql (chunks 26-30, ~25,000 updates)
- [ ] batch_fix_7.sql (chunks 31-35, ~25,000 updates)
- [ ] batch_fix_8.sql (chunks 36-40, ~25,000 updates)
- [ ] batch_fix_9.sql (chunks 41-45, ~25,000 updates)
- [ ] batch_fix_10.sql (chunks 46-50, ~25,000 updates)
- [ ] batch_fix_11.sql (chunks 51-52, ~2,000 updates)

---

## 🚨 What About the Other 471K Records?

The remaining 471,594 records aren't in our CSV file. Options:
1. Find them in a different IRS dataset
2. Use the IRS Business Master File (BMF)
3. Scrape them from the IRS Tax Exempt Organization Search
4. Leave them as-is (they'll still have preparer names)

**I recommend:** Run the fix for the 255K records we CAN fix, then we'll tackle the remaining 471K separately.

---

## Files Ready:
- ✅ `~/MASTER_name_fixes.sql` (44MB, all 255K fixes)
- ✅ `~/nonprofit_name_fixes/batch_fix_*.sql` (11 batch files)
- ✅ `~/nonprofit_name_fixes/fix_chunk_*.sql` (52 individual chunks)
