#!/usr/bin/env python3
"""
Fix corrupted nonprofit names in database
The Oct 22 import used tax preparer names instead of organization names
This script generates UPDATE statements using correct names from the CSV
"""

import csv
from pathlib import Path
from collections import defaultdict
from datetime import datetime

# Configuration
CSV_FILE = Path.home() / "Downloads" / "charities_domains_cleaned.csv"
OUTPUT_DIR = Path.home() / "nonprofit_name_fixes"
CHUNK_SIZE = 5000  # Larger chunks for UPDATE statements

def normalize_ein(ein):
    """Normalize EIN to 9 digits"""
    ein = str(ein).strip().replace('-', '')
    if len(ein) == 9 and ein.isdigit():
        return ein
    return None

def escape_sql(text):
    """Escape single quotes for SQL"""
    if text is None:
        return ''
    return str(text).replace("'", "''")

def main():
    print("=" * 80)
    print("  FIXING CORRUPTED NONPROFIT NAMES")
    print("=" * 80)
    print(f"Reading CSV: {CSV_FILE}\n")

    # Build mapping of EIN -> correct name
    # Prefer entries with websites (more likely to be current)
    ein_to_name = {}
    ein_occurrences = defaultdict(int)

    with open(CSV_FILE, 'r', encoding='utf-8', errors='ignore') as f:
        # Read header and strip spaces
        header_line = f.readline()
        headers = [h.strip() for h in header_line.split(',')]
        reader = csv.DictReader(f, fieldnames=headers)

        for row in reader:
            ein = normalize_ein(row.get('FILEREIN', ''))
            name = row.get('FILERNAME1', '').strip()
            website = row.get('WEBSITSITEIT', '').strip()

            # Skip Excel errors and invalid data
            if name.startswith('#') or name.startswith("'"):
                name = name.lstrip("'#")
            if name.upper() == 'NAME?':
                continue

            if not ein or not name:
                continue

            ein_occurrences[ein] += 1

            # Prefer entries with websites, or just take the first one
            if ein not in ein_to_name or website:
                ein_to_name[ein] = name

    print(f"Found {len(ein_to_name):,} unique EINs with correct names")
    print(f"Total occurrences in CSV: {sum(ein_occurrences.values()):,}")
    print(f"Average occurrences per EIN: {sum(ein_occurrences.values()) / len(ein_to_name):.1f}\n")

    # Create output directory
    OUTPUT_DIR.mkdir(exist_ok=True)

    # Generate UPDATE statements in chunks
    print(f"Generating UPDATE statements (chunks of {CHUNK_SIZE:,})...\n")

    chunk_num = 0
    current_chunk = []
    total_count = 0

    for ein, correct_name in sorted(ein_to_name.items()):
        update_stmt = f"UPDATE nonprofits SET name = '{escape_sql(correct_name)}', updated_at = '{datetime.utcnow().isoformat()}' WHERE ein_charity_number = '{ein}' AND DATE(created_at) = '2025-10-22';"

        current_chunk.append(update_stmt)
        total_count += 1

        if len(current_chunk) >= CHUNK_SIZE:
            chunk_num += 1
            chunk_file = OUTPUT_DIR / f"fix_chunk_{chunk_num:03d}.sql"

            with open(chunk_file, 'w', encoding='utf-8') as f:
                f.write(f"-- Name Fix Chunk {chunk_num}: Updates {len(current_chunk):,} records\n")
                f.write(f"-- Generated: {datetime.now().isoformat()}\n\n")
                f.write('\n'.join(current_chunk))
                f.write('\n')

            print(f"  ✓ Created {chunk_file.name} ({len(current_chunk):,} updates)")
            current_chunk = []

    # Write final partial chunk
    if current_chunk:
        chunk_num += 1
        chunk_file = OUTPUT_DIR / f"fix_chunk_{chunk_num:03d}.sql"

        with open(chunk_file, 'w', encoding='utf-8') as f:
            f.write(f"-- Name Fix Chunk {chunk_num}: Updates {len(current_chunk):,} records\n")
            f.write(f"-- Generated: {datetime.now().isoformat()}\n\n")
            f.write('\n'.join(current_chunk))
            f.write('\n')

        print(f"  ✓ Created {chunk_file.name} ({len(current_chunk):,} updates)")

    print("\n" + "=" * 80)
    print(f"  ✅ GENERATED {chunk_num} UPDATE CHUNKS")
    print("=" * 80)
    print(f"Total UPDATE statements: {total_count:,}")
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"\nEach chunk updates {CHUNK_SIZE:,} records (except last chunk)")
    print("\nNext step: Apply these UPDATE statements to fix the corrupted names")
    print("=" * 80)

if __name__ == "__main__":
    main()
