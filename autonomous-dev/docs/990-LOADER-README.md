# 🚀 IRS Form 990 Nonprofit Data Loader

**Autonomous script to download and process 900K+ nonprofits with websites from IRS data.**

---

## ⚡ Quick Start (3 Steps)

### **1. Run the Script**
```bash
cd ~
python3 load-990-nonprofits.py
```

That's it! The script does everything automatically.

---

## 📊 What It Does

### **Automatically:**
1. ✅ Downloads all IRS Form 990 ZIP files (2024 + 2023)
2. ✅ Extracts ~900,000 nonprofits with websites
3. ✅ Creates small CSV files (50,000 orgs each = ~18 files)
4. ✅ Uploads each batch to your Supabase database
5. ✅ Tracks progress (can stop and resume anytime)

### **What You Get:**
```
✅ 900,000+ nonprofits in your database
✅ Each with: Name, EIN, Website, Revenue, Mission, Address
✅ Ready for Phase 2 (funder scraping)
```

---

## ⏱️ How Long Does It Take?

- **Download speed:** ~5-10 minutes per ZIP file (30 ZIPs total)
- **Processing speed:** ~2-5 minutes per ZIP file
- **Total time:** 4-8 hours (runs unattended)

**Recommendation:** Start it before bed, wake up to 900K nonprofits! 🌙

---

## 📂 Where Files Go

All data saved to:
```
~/990_nonprofit_data/
  ├── nonprofits_2024_batch_001.csv (50,000 orgs)
  ├── nonprofits_2024_batch_002.csv (50,000 orgs)
  ├── ...
  ├── nonprofits_2023_batch_001.csv
  ├── ...
  └── processing_state.json (tracks progress)
```

---

## 🔄 Can I Stop and Resume?

**YES!** Press `Ctrl+C` anytime.

The script saves progress automatically. Just run it again:
```bash
python3 load-990-nonprofits.py
```

It will pick up exactly where it left off!

---

## 📺 What You'll See

```
================================================================================
  IRS FORM 990 NONPROFIT DATA LOADER
================================================================================

📂 Output directory: ~/990_nonprofit_data
📊 Batch size: 50,000 organizations per CSV
💾 State file: ~/990_nonprofit_data/processing_state.json

================================================================================
  PROCESSING 2024 FILINGS
================================================================================

🔍 Discovering 2024 ZIP files...
   ✅ Found 01A (117.3 MB)
   ✅ Found 02A (119.1 MB)
   ...
   📦 Total: 30 ZIP files for 2024

📥 Downloading 2024_01A...
   ✅ Downloaded (117.3 MB)
   🔍 Processing XML files...
      500/24532 files processed... (498 orgs, 2 skipped)
      1000/24532 files processed... (995 orgs, 5 skipped)
      ...
   ✅ Completed 01A: 24,430 total orgs processed

   💾 Saving batch 1 (24,430 orgs) to CSV...
   ✅ Saved: nonprofits_2024_batch_001.csv
   📤 Uploading to Supabase...
   ✅ Uploaded 24,430 organizations to database

... (repeats for all ZIP files)
```

---

## ⚠️ Important Notes

### **Deduplication (No Duplicates!)**
- Processes 2024 first
- When processing 2023, skips any EIN already in 2024
- Result: Latest data for each nonprofit (no duplicates)

### **CSV Files**
- Each file: 50,000 organizations max
- Easy to open in Excel/Numbers (won't crash!)
- Auto-uploaded to database (keep as backup)

### **Internet Required**
- Downloads ~4 GB total
- Uploads data to Supabase
- Can pause if internet drops (just resume)

---

## 🆘 Troubleshooting

### **Problem: Script crashes**
**Solution:** Just run it again! It resumes automatically.

### **Problem: Upload fails**
**Solution:** CSV files are saved locally. You can manually upload them later.

### **Problem: Takes too long**
**Solution:** Let it run overnight. It's processing 900K organizations!

### **Problem: Need Python libraries**
If you get import errors, install required libraries:
```bash
pip3 install requests
```

---

## 📊 After It Finishes

### **Check Your Database:**
```sql
SELECT COUNT(*) FROM nonprofits;
-- Should show: ~900,000

SELECT COUNT(*) FROM nonprofits WHERE website IS NOT NULL AND website != '';
-- Should show: ~600,000-700,000 (most have websites!)
```

### **Next Step:**
Run Phase 2 to scrape websites for funder data!

---

## 🎯 Summary

1. **Run:** `python3 load-990-nonprofits.py`
2. **Wait:** 4-8 hours (automatic)
3. **Done:** 900K nonprofits in database with websites!

**That's it!** The script is fully autonomous. Just start it and let it work.

---

## 💡 Pro Tips

- **Run overnight:** Start before bed
- **Check progress:** Just look at terminal output
- **Pause anytime:** Ctrl+C to stop, script saves progress
- **CSV backups:** Keep the CSV files as backup (in ~/990_nonprofit_data/)

---

**Ready to start?**

```bash
cd ~
python3 load-990-nonprofits.py
```

**Then go to sleep! Wake up to 900K nonprofits. 😴 ➡️ ☕️ ➡️ 🎉**
