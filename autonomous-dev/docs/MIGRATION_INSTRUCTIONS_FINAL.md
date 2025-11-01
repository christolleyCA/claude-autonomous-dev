# 🚀 FINAL Migration Instructions - Apply 210,598 Nonprofits

## ✅ RECOMMENDED: Use TablePlus (Easiest & Fastest)

### Step 1: Download TablePlus
- Download free from: https://tableplus.com/
- Install and open it

### Step 2: Connect to Your Supabase Database

Click "Create a new connection" → PostgreSQL

Enter these details:
- **Host:** `db.hjtvtkffpziopozmtsnb.supabase.co`
- **Port:** `5432`
- **User:** `postgres`
- **Password:** Get from https://supabase.com/dashboard/project/hjtvtkffpziopozmtsnb/settings/database
- **Database:** `postgres`

Click "Test" then "Connect"

### Step 3: Apply SQL Files

In TablePlus:
1. Click "SQL" button (or press ⌘+E)
2. Open file: `~/MASTER_nonprofit_migration.sql`
3. Click "Run Current"
4. Wait 2-3 minutes for completion
5. Done! ✅

**OR** if that's too large, apply the 22 batch files one at a time:
- `~/nonprofit_sql_inserts/batch_1.sql` through `batch_22.sql`

---

## Alternative: Use Supabase Dashboard (Slower but No Install)

1. Go to: https://supabase.com/dashboard/project/hjtvtkffpziopozmtsnb/sql
2. Click "New Query"
3. Copy contents of `~/nonprofit_sql_inserts/chunk_001.sql`
4. Paste and click "Run"
5. Repeat for chunks 002 through 211

---

## Alternative: Use psql Command Line

```bash
# Get your database password from Supabase dashboard first

PGPASSWORD='your-password-here' psql \\
  -h db.hjtvtkffpziopozmtsnb.supabase.co \\
  -p 5432 \\
  -U postgres \\
  -d postgres \\
  -f ~/MASTER_nonprofit_migration.sql
```

---

## Files Ready for You

📁 **Master file (all 211 chunks combined):**
- `~/MASTER_nonprofit_migration.sql` (66MB)

📁 **Batch files (10 chunks each):**
- `~/nonprofit_sql_inserts/batch_1.sql` through `batch_22.sql` (3.1MB each)

📁 **Individual chunks (1,000 nonprofits each):**
- `~/nonprofit_sql_inserts/chunk_001.sql` through `chunk_211.sql` (320KB each)

---

## What Will Happen

✅ **210,598 nonprofits** will be inserted into your database
✅ **Duplicates automatically skipped** (ON CONFLICT DO NOTHING)
✅ **Database will grow** from 727K → 772K nonprofits
✅ **Website coverage improves** from 51.2% → 54%

---

## After Migration

Run this query to verify:

```sql
SELECT COUNT(*) as total_nonprofits,
       COUNT(website) as nonprofits_with_websites,
       ROUND(COUNT(website)::numeric / COUNT(*)::numeric * 100, 1) as website_coverage_pct
FROM nonprofits;
```

Expected result: ~772,000 total nonprofits with ~54% website coverage.

---

**I recommend TablePlus** - it's the fastest and handles large SQL files perfectly!
