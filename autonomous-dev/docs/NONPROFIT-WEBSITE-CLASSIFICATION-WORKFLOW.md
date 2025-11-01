# 🌐 Nonprofit Website Classification Workflow

**Goal:** Classify 727,188 nonprofit websites as "public facing" (TRUE) or not (FALSE)

---

## 📊 Current Status

- **Total nonprofits in database:** 748,707
- **Nonprofits needing classification:** 727,188
- **Nonprofits already classified:** 21,519

---

## 🎯 What is "Public Facing"?

The `public_facing` field indicates whether a website is a legitimate public domain:

### ✅ Public Facing (TRUE)
- Proper organizational websites: `example.org`, `www.example.com`
- Real domains with http:// or https://
- Direct links to organization homepages

### ❌ Not Public Facing (FALSE)
- Social media handles: `@username`, `facebook.com/username`
- Internal pages: `/about`, `//subdomain`
- Malformed data: quoted strings, HTML fragments
- Partial URLs without proper domain

---

## 🔄 Complete Workflow

### Step 1: Export Batches for Classification

```bash
cd ~/
python3 export-nonprofits-for-classification.py
```

**What this does:**
- Exports ALL 727,188 records in batches of 500
- Creates CSV files in `~/nonprofit_classification_batches/`
- Each CSV has columns: EIN, Name, Website, Address, etc., and **Public Facing** (empty)
- Files named: `batch_0001.csv`, `batch_0002.csv`, etc.

**Expected output:**
```
📦 Creating 1,455 batches of 500 records each
✅ Export complete!
Location: ~/nonprofit_classification_batches
```

---

### Step 2: Classify Websites (Manual Review)

Open a batch CSV file and review:

1. **Open:** `batch_0001.csv` in Excel/Numbers/Google Sheets
2. **Review** the `Website` column
3. **Mark** the `Public Facing` column:
   - Type `TRUE` for legitimate domains
   - Type `FALSE` for social media, partials, malformed data
4. **Save** the CSV file
5. Repeat for as many batches as you want to process

**Pro Tips:**
- Start with high-revenue nonprofits (already sorted DESC by annual_revenue)
- Process in manageable chunks (10-20 batches at a time)
- Use filters in Excel to group similar patterns
- Create rules for common patterns (e.g., all @handles = FALSE)

---

### Step 3: Import Classifications Back to Database

```bash
cd ~/
python3 update-classifications-from-csv.py
```

**Choose mode:**
- **Option 1:** Generate SQL files only (review before applying)
- **Option 2:** Generate and auto-apply to database ⚡

**What this does:**
- Reads all CSV files in `~/nonprofit_classification_batches/`
- Finds rows where `Public Facing` is filled in (TRUE or FALSE)
- Generates SQL UPDATE statements
- Saves to `~/nonprofit_classification_updates/`
- Optionally applies updates immediately

**Expected output:**
```
Batches processed: 10/10
Total classifications updated: 5,000
✅ Updates applied to database
```

---

## 🚀 Quick Start Commands

### Export first 10 batches (5,000 records)
```bash
# Modify the script to limit batches
python3 export-nonprofits-for-classification.py
# Then manually stop after 10 batches or edit script to add batch limit
```

### Process just one batch manually
```bash
# 1. Export (creates all batches)
python3 export-nonprofits-for-classification.py

# 2. Edit batch_0001.csv
# (classify the websites)

# 3. Import just that one batch
python3 update-classifications-from-csv.py
# (choose option 2 for auto-apply)
```

---

## 📁 File Structure

```
~/
├── export-nonprofits-for-classification.py   # Export script
├── update-classifications-from-csv.py        # Import script
│
├── nonprofit_classification_batches/         # CSV exports (for review)
│   ├── batch_0001.csv
│   ├── batch_0002.csv
│   └── ...
│
└── nonprofit_classification_updates/         # SQL updates (generated)
    ├── batch_0001_updates.sql
    ├── batch_0002_updates.sql
    └── ...
```

---

## 🎨 Classification Examples

### Example 1: Legitimate Website
```
EIN: 123456789
Name: Save the Whales Foundation
Website: https://savethewhales.org
Public Facing: TRUE ✓
```

### Example 2: Social Media Handle
```
EIN: 987654321
Name: Community Arts Center
Website: @communityarts
Public Facing: FALSE ✗
```

### Example 3: Malformed Data
```
EIN: 456789123
Name: Youth Education Network
Website: "/programs/about"
Public Facing: FALSE ✗
```

### Example 4: Partial URL
```
EIN: 789123456
Name: Environmental Action Group
Website: //subdomain.example.org/page
Public Facing: FALSE ✗
```

---

## 📊 Progress Tracking

### Check how many are left
```sql
SELECT COUNT(*)
FROM nonprofits
WHERE website IS NOT NULL
  AND public_facing IS NULL;
```

### Check how many classified as TRUE
```sql
SELECT COUNT(*)
FROM nonprofits
WHERE public_facing = TRUE;
```

### Check how many classified as FALSE
```sql
SELECT COUNT(*)
FROM nonprofits
WHERE public_facing = FALSE;
```

---

## 🤖 Automation Ideas (Future)

1. **Pattern Matching Rules:**
   - Auto-mark `@username` as FALSE
   - Auto-mark `/path` as FALSE
   - Auto-mark proper domains as TRUE

2. **AI Classification:**
   - Use Claude API to classify websites
   - Verify with web scraping (check if URL is accessible)
   - Use the n8n orchestrator to batch process

3. **Web Validation:**
   - Check if domain resolves
   - Verify HTTP response (200 = TRUE, 404 = FALSE)
   - Store validation timestamp

---

## ⚠️ Important Notes

1. **Backup First:** The database has RLS enabled, but always good practice
2. **Test Small Batches:** Start with 1-2 batches to verify workflow
3. **Save Progress:** Commit classified CSVs to git regularly
4. **Manual Review:** Some edge cases require human judgment
5. **Performance:** Each batch of 500 takes ~5 seconds to import

---

## 🎯 Success Metrics

- **Coverage:** % of nonprofits with public_facing classified
- **Accuracy:** % correctly identified as TRUE/FALSE
- **Velocity:** Batches processed per hour
- **Goal:** 100% classification of all 727,188 records

---

## 💡 Pro Tips

### Batch Processing Strategy
1. Start with high-revenue orgs (already sorted by revenue DESC)
2. Process 10 batches (5,000 records) per session
3. Take breaks to avoid classification fatigue
4. Use find/replace in Excel for common patterns

### Common Patterns to Look For
- `@` prefix → FALSE
- `facebook.com/` → FALSE (social media profile)
- `linkedin.com/` → FALSE (social media profile)
- No dots in URL → FALSE (not a domain)
- Starts with `/` → FALSE (internal path)
- Starts with `//` → FALSE (subdomain/internal)
- Has `http://` or `https://` and proper domain → TRUE

### Excel Pro Tip
Create a formula in column L to suggest classification:
```excel
=IF(LEFT(C2,1)="@","FALSE",IF(LEFT(C2,1)="/","FALSE","REVIEW"))
```

This will auto-flag obvious cases and let you focus on edge cases.

---

## 📞 Support

- **Scripts location:** `~/`
- **Batch files:** `~/nonprofit_classification_batches/`
- **Update SQLs:** `~/nonprofit_classification_updates/`
- **Database:** Supabase grantomatic-prod (hjtvtkffpziopozmtsnb)

---

**Happy Classifying! 🚀**
