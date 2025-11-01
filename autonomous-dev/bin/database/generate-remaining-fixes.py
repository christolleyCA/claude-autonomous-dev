#!/usr/bin/env python3
"""
Generate UPDATE statements for remaining corrupted nonprofit names
Uses IRS BMF data and direct database connection
"""

import json
import sys
import subprocess
from pathlib import Path

# Configuration
IRS_DATA_FILE = Path.home() / "irs_bmf_ein_to_name.json"
OUTPUT_DIR = Path.home() / "nonprofit_name_fixes"
OUTPUT_FILE = OUTPUT_DIR / "remaining_fixes_batch.sql"

# Database connection (using working TablePlus credentials)
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"

def load_irs_data():
    """Load IRS BMF EIN-to-name mappings"""
    print("📂 Loading IRS BMF data...")
    with open(IRS_DATA_FILE, 'r') as f:
        data = json.load(f)
    print(f"✅ Loaded {len(data):,} EIN-to-name mappings")
    return data

def fetch_corrupted_eins():
    """Fetch corrupted EINs from database using psql"""
    print("\n🔍 Fetching corrupted EINs from database...")

    sql = """
    SELECT ein_charity_number
    FROM nonprofits
    WHERE DATE(created_at) = '2025-10-22'
      AND NOT (updated_at > created_at AND DATE(updated_at) = '2025-10-23')
      AND (name LIKE '%LLC%' OR name LIKE '%LLP%' OR name LIKE '%& Co%' OR name LIKE '%CPA%' OR name LIKE '%P.C.%')
    ORDER BY ein_charity_number;
    """

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-t', '-A', '-c', sql],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=120
        )

        if result.returncode == 0:
            eins = [line.strip() for line in result.stdout.strip().split('\n') if line.strip()]
            print(f"✅ Fetched {len(eins):,} corrupted EINs")
            return eins
        else:
            print(f"❌ Database query failed: {result.stderr}")
            return []

    except Exception as e:
        print(f"❌ Error fetching EINs: {e}")
        return []

def generate_update_statements(corrupted_eins, irs_data):
    """Generate SQL UPDATE statements for corrupted names"""
    print("\n🔨 Generating UPDATE statements...")

    updates = []
    found_count = 0
    not_found_count = 0

    for ein in corrupted_eins:
        if ein in irs_data:
            correct_name = irs_data[ein]
            # Escape single quotes in name
            escaped_name = correct_name.replace("'", "''")

            update_sql = f"UPDATE nonprofits SET name = '{escaped_name}', updated_at = NOW() WHERE ein_charity_number = '{ein}';"
            updates.append(update_sql)
            found_count += 1
        else:
            not_found_count += 1

    print(f"✅ Generated {found_count:,} UPDATE statements")
    print(f"⚠️  {not_found_count:,} EINs not found in IRS data")

    return updates

def save_update_statements(updates):
    """Save UPDATE statements to SQL file"""
    print(f"\n💾 Saving to {OUTPUT_FILE}...")

    # Create output directory if needed
    OUTPUT_DIR.mkdir(exist_ok=True)

    with open(OUTPUT_FILE, 'w') as f:
        f.write("-- Fix remaining corrupted nonprofit names\n")
        f.write("-- Generated from IRS Business Master File data\n")
        f.write(f"-- Total updates: {len(updates):,}\n\n")

        for update in updates:
            f.write(update + "\n")

    print(f"✅ Saved {len(updates):,} UPDATE statements")
    print(f"📁 File: {OUTPUT_FILE}")

    size_mb = OUTPUT_FILE.stat().st_size / 1024 / 1024
    print(f"📊 File size: {size_mb:.1f}MB")

    return size_mb

def main():
    print("🚀 Generate Fixes for Remaining Corrupted Nonprofit Names")
    print("=" * 80)

    # Load IRS data
    irs_data = load_irs_data()

    # Fetch corrupted EINs from database
    corrupted_eins = fetch_corrupted_eins()

    if not corrupted_eins:
        print("\n⚠️  No corrupted EINs found or database query failed")
        return 1

    # Generate UPDATE statements
    updates = generate_update_statements(corrupted_eins, irs_data)

    if not updates:
        print("\n⚠️  No updates generated")
        return 1

    # Save to file
    size_mb = save_update_statements(updates)

    print("\n" + "=" * 80)
    print("✅ Ready to apply fixes!")
    print("\nThe generated SQL file can be applied using the same method that worked")
    print("for the nonprofit imports:")
    print()
    print("Option 1: Apply directly with psql:")
    print(f'  PGPASSWORD="{DB_PASSWORD}" {PSQL} \\')
    print(f'    -h "{DB_HOST}" -p "{DB_PORT}" \\')
    print(f'    -U "{DB_USER}" -d "{DB_NAME}" \\')
    print(f'    -f "{OUTPUT_FILE}"')
    print()
    print("Option 2: Open in TablePlus and execute")
    print(f"  File: {OUTPUT_FILE}")

    # Estimate time
    if size_mb < 50:
        print(f"\n⏱️  Estimated execution time: 1-2 minutes")
    else:
        print(f"\n⏱️  Estimated execution time: 3-5 minutes")

    print("=" * 80)

    return 0

if __name__ == "__main__":
    sys.exit(main())
