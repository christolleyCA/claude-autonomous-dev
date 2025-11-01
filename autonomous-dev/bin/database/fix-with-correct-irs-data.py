#!/usr/bin/env python3
"""
FIX THE MESS: Use authoritative IRS bulk CSV files to get correct names
The irs_bmf_ein_to_name.json file had WRONG/OUTDATED data!
"""

import csv
import sys
from pathlib import Path
from collections import defaultdict

# IRS CSV files (authoritative source)
IRS_CSV_FILES = [
    Path.home() / "Downloads" / "eo1.csv",
    Path.home() / "Downloads" / "eo2.csv",
    Path.home() / "Downloads" / "eo3.csv",
    Path.home() / "Downloads" / "eo4.csv",
]

OUTPUT_DIR = Path.home() / "nonprofit_name_fixes"
OUTPUT_FILE = OUTPUT_DIR / "correct_irs_fixes.sql"

def load_irs_csv_data():
    """Load EIN-to-name mappings from authoritative IRS CSV files"""
    print("📂 Loading IRS bulk CSV files (authoritative source)...")

    ein_to_name = {}
    total_records = 0

    for csv_file in IRS_CSV_FILES:
        if not csv_file.exists():
            print(f"⚠️  File not found: {csv_file}")
            continue

        print(f"   Reading {csv_file.name}...")

        with open(csv_file, 'r', encoding='utf-8', errors='replace') as f:
            reader = csv.DictReader(f)
            count = 0

            for row in reader:
                ein = row['EIN'].strip()
                name = row['NAME'].strip()

                if ein and name:
                    ein_to_name[ein] = name
                    count += 1

            print(f"      Loaded {count:,} records")
            total_records += count

    print(f"✅ Total IRS records loaded: {total_records:,}")
    return ein_to_name

def get_all_nonprofit_eins():
    """Get all EINs from database"""
    import subprocess

    print("\n🔍 Fetching all nonprofit EINs from database...")

    sql = """
    SELECT ein_charity_number, name
    FROM nonprofits
    WHERE DATE(created_at) = '2025-10-22'
    ORDER BY ein_charity_number;
    """

    # Database connection
    DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
    DB_PORT = "6543"
    DB_USER = "postgres.hjtvtkffpziopozmtsnb"
    DB_NAME = "postgres"
    DB_PASSWORD = "Dharini1221su!"
    PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-t', '-A', '-F', '|', '-c', sql],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=120
        )

        if result.returncode == 0:
            records = []
            for line in result.stdout.strip().split('\n'):
                if '|' in line:
                    parts = line.strip().split('|', 1)
                    if len(parts) == 2:
                        records.append({'ein': parts[0], 'current_name': parts[1]})

            print(f"✅ Fetched {len(records):,} nonprofit records")
            return records
        else:
            print(f"❌ Database query failed: {result.stderr}")
            return []

    except Exception as e:
        print(f"❌ Error fetching data: {e}")
        return []

def generate_correct_updates(db_records, irs_data):
    """Generate UPDATE statements using correct IRS names"""
    print("\n🔨 Comparing database names with IRS data...")

    updates = []
    already_correct = 0
    will_fix = 0
    not_in_irs = 0

    for record in db_records:
        ein = record['ein']
        current_name = record['current_name']

        if ein in irs_data:
            correct_name = irs_data[ein]

            # Check if names differ
            if current_name != correct_name:
                # Escape single quotes
                escaped_name = correct_name.replace("'", "''")

                update_sql = f"UPDATE nonprofits SET name = '{escaped_name}', updated_at = NOW() WHERE ein_charity_number = '{ein}';"
                updates.append(update_sql)
                will_fix += 1

                # Show first few examples
                if will_fix <= 5:
                    print(f"   Example fix:")
                    print(f"      EIN: {ein}")
                    print(f"      Current: {current_name[:60]}")
                    print(f"      Correct: {correct_name[:60]}")
                    print()
            else:
                already_correct += 1
        else:
            not_in_irs += 1

    print(f"✅ Already correct: {already_correct:,}")
    print(f"🔧 Will fix: {will_fix:,}")
    print(f"⚠️  Not in IRS data: {not_in_irs:,}")

    return updates

def save_updates(updates):
    """Save UPDATE statements to SQL file"""
    print(f"\n💾 Saving to {OUTPUT_FILE}...")

    OUTPUT_DIR.mkdir(exist_ok=True)

    with open(OUTPUT_FILE, 'w') as f:
        f.write("-- CORRECT nonprofit names using authoritative IRS bulk CSV data\n")
        f.write("-- This FIXES the bad updates made with outdated JSON file\n")
        f.write(f"-- Total updates: {len(updates):,}\n\n")

        for update in updates:
            f.write(update + "\n")

    size_mb = OUTPUT_FILE.stat().st_size / 1024 / 1024
    print(f"✅ Saved {len(updates):,} UPDATE statements")
    print(f"📁 File: {OUTPUT_FILE}")
    print(f"📊 Size: {size_mb:.1f}MB")

def main():
    print("🚨 FIX INCORRECT UPDATES - Using Authoritative IRS CSV Data")
    print("=" * 80)

    # Load authoritative IRS data
    irs_data = load_irs_csv_data()

    if not irs_data:
        print("\n❌ No IRS data loaded!")
        return 1

    # Get all nonprofit records from database
    db_records = get_all_nonprofit_eins()

    if not db_records:
        print("\n❌ No database records retrieved!")
        return 1

    # Generate correct updates
    updates = generate_correct_updates(db_records, irs_data)

    if not updates:
        print("\n✅ All names are already correct!")
        return 0

    # Save updates
    save_updates(updates)

    print("\n" + "=" * 80)
    print("✅ Ready to apply CORRECT fixes!")
    print("\nApply with:")
    print('  PGPASSWORD="Dharini1221su!" /opt/homebrew/opt/postgresql@14/bin/psql \\')
    print('    -h "aws-0-ca-central-1.pooler.supabase.com" -p "6543" \\')
    print('    -U "postgres.hjtvtkffpziopozmtsnb" -d "postgres" \\')
    print(f'    -f "{OUTPUT_FILE}"')
    print("=" * 80)

    return 0

if __name__ == "__main__":
    sys.exit(main())
