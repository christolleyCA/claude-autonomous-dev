# 🔍 Data Source Options for Fixing 274K Corrupted Records

## The Challenge
We need correct organization names for **~274,000 EINs** that weren't in our CSV file.

---

## 📊 Option 1: ProPublica Nonprofit Explorer API (RECOMMENDED) ⭐

**Pros:**
- Free API
- Has 1.8+ million nonprofits
- Includes organization names from IRS Form 990
- Easy to use (JSON responses)
- No download required

**Cons:**
- Rate limited (need to space out requests)
- May not have all 274K organizations

**How it works:**
```bash
# Example API call for one EIN:
curl "https://projects.propublica.org/nonprofits/api/v2/organizations/042473134.json"
```

**Time estimate:** 274K requests at ~10 per second = ~7.5 hours

**Code:** I can write a Python script to:
1. Get list of corrupted EINs from database
2. Query ProPublica API for each EIN
3. Extract organization name
4. Generate UPDATE statements
5. Apply fixes

---

## 📥 Option 2: IRS Business Master File (BMF)

**Pros:**
- Complete dataset of ALL tax-exempt organizations
- Official IRS data
- Single download (no API calls)

**Cons:**
- Large file (~500MB compressed)
- Fixed-width format (harder to parse)
- Updated monthly (not real-time)

**How it works:**
1. Download from: https://www.irs.gov/charities-non-profits/exempt-organizations-business-master-file-extract-eo-bmf
2. Parse the fixed-width text file
3. Match EINs to get org names

**Time estimate:** ~30 minutes to download and process

---

## 🌐 Option 3: IRS Tax Exempt Organization Search

**Pros:**
- Most current data
- Has all organizations
- Web interface available

**Cons:**
- No bulk API
- Would require scraping (against ToS)
- Very slow for 274K lookups

**Not recommended for bulk operations**

---

## 🔄 Option 4: Use Multiple Years from ProPublica

**Observation:** The CSV we used had data from 2011-2017. The corrupted records might be in different years.

**Pros:**
- ProPublica has historical Form 990 data
- Can download bulk datasets
- May cover more organizations

**Cons:**
- Need to download/process multiple files
- Still might not cover all 274K

---

## 🎯 My Recommendation: **Hybrid Approach**

Combine Option 1 + Option 2:

### Step 1: Download IRS BMF (FASTEST & MOST COMPLETE)
- Single file with ALL nonprofits
- Parse it to get EIN → Name mapping
- Match against our 274K corrupted records
- Generate UPDATE statements

### Step 2: Use ProPublica API for Missing Records
- Some EINs might not be in BMF (very recent orgs)
- Query ProPublica for these stragglers
- Fill in remaining gaps

**Total time:** 1-2 hours (mostly automated)

---

## 📋 What I'll Build

If you approve, I'll create:

1. **Script 1:** Download & parse IRS BMF
   - Downloads the official IRS file
   - Extracts EIN + Name for all nonprofits
   - Creates lookup table

2. **Script 2:** Match & generate fixes
   - Gets list of 274K corrupted EINs from database
   - Looks up correct names in BMF data
   - Generates UPDATE SQL statements

3. **Script 3:** ProPublica fallback (optional)
   - For any EINs not found in BMF
   - Queries ProPublica API
   - Generates additional UPDATEs

**Output:** New SQL files ready to apply (just like before)

---

## ⚡ Quick Start

If you want to proceed with the **Hybrid Approach**, I can start now:

1. Download IRS BMF
2. Parse it
3. Match our 274K corrupted EINs
4. Generate fixes
5. You apply them (same way as before with `~/run-fix.sh`)

**Estimated total time to prepare:** 30-60 minutes
**Estimated time to apply fixes:** 5-10 minutes (via psql)

---

## 🤔 Alternative: Quick Win Option

If you want faster results, I could:

1. **Fix just the most obvious corrupted ones first** (~100K records with clear accounting firm names)
2. Use ProPublica API for a sample (say 10K records)
3. See if that's "good enough" for now

Then fix the rest later if needed.

---

## What do you want to do?

**A)** Hybrid Approach - Fix all 274K (most thorough) ⭐
**B)** ProPublica API only - Fix what we can (simpler but incomplete)
**C)** Quick Win - Fix 10K-50K most obvious ones first (fastest to see results)
**D)** Something else (let me know!)

