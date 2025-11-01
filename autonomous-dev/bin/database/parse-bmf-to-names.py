#!/usr/bin/env python3
"""
Parse IRS BMF files to extract EIN → Organization Name mappings
Fixed-width format: First 9 chars = EIN, Next 70 chars = Name
"""

from pathlib import Path
import json
from datetime import datetime

# Configuration
BMF_DIR = Path.home() / "irs_bmf_data" / "extracted"
OUTPUT_FILE = Path.home() / "irs_bmf_ein_to_name.json"

BMF_FILES = ['EO1.LST', 'EO2.LST', 'EO3.LST', 'EO4.LST']

print("=" * 80)
print("  PARSING IRS BMF FILES")
print("=" * 80)
print(f"Input directory: {BMF_DIR}")
print(f"Output file: {OUTPUT_FILE}\n")

ein_to_name = {}
total_records = 0
skipped = 0

for bmf_file in BMF_FILES:
    file_path = BMF_DIR / bmf_file

    if not file_path.exists():
        print(f"⚠️  File not found: {bmf_file}")
        continue

    print(f"📖 Parsing {bmf_file}...")
    file_records = 0

    with open(file_path, 'r', encoding='latin-1', errors='ignore') as f:
        for line in f:
            # EIN is first 9 characters
            ein = line[0:9].strip()

            # Organization name is characters 10-79 (70 chars)
            org_name = line[9:79].strip()

            # Skip if EIN is invalid (not 9 digits)
            if not ein.isdigit() or len(ein) != 9:
                skipped += 1
                continue

            # Skip if name is empty
            if not org_name:
                skipped += 1
                continue

            # Store the mapping (if duplicate EIN, keep first occurrence)
            if ein not in ein_to_name:
                ein_to_name[ein] = org_name
                file_records += 1

            total_records += 1

            # Progress update every 100K records
            if total_records % 100000 == 0:
                print(f"   Processed: {total_records:,} records...")

    print(f"   ✓ {file_records:,} unique EINs from {bmf_file}")

print(f"\n" + "=" * 80)
print("  PARSING COMPLETE!")
print("=" * 80)
print(f"Total records processed: {total_records:,}")
print(f"Unique EINs extracted: {len(ein_to_name):,}")
print(f"Skipped (invalid): {skipped:,}")

# Save to JSON file for easy lookup
print(f"\n💾 Saving to {OUTPUT_FILE}...")
with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
    json.dump(ein_to_name, f, indent=2)

file_size_mb = OUTPUT_FILE.stat().st_size / (1024 * 1024)
print(f"✓ Saved: {file_size_mb:.1f}MB")

# Sample some entries
print(f"\n📊 Sample entries:")
sample_eins = list(ein_to_name.keys())[:10]
for ein in sample_eins:
    print(f"   {ein}: {ein_to_name[ein]}")

print(f"\n✅ Ready to match against corrupted records!")
