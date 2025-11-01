#!/usr/bin/env python3
"""
Fix remaining corrupted nonprofit names using IRS BMF data
"""

import json
import sys
from pathlib import Path

# File paths
IRS_DATA_FILE = Path.home() / "irs_bmf_ein_to_name.json"
OUTPUT_DIR = Path.home() / "nonprofit_name_fixes"
OUTPUT_FILE = OUTPUT_DIR / "remaining_fixes.sql"

def load_irs_data():
    """Load IRS BMF EIN-to-name mappings"""
    print("📂 Loading IRS BMF data...")
    with open(IRS_DATA_FILE, 'r') as f:
        data = json.load(f)
    print(f"✅ Loaded {len(data):,} EIN-to-name mappings")
    return data

def get_corrupted_eins_from_db():
    """Get list of EINs that still need fixing from Supabase"""
    import subprocess

    print("\n🔍 Fetching corrupted EINs from database...")

    # SQL to get corrupted EINs (those not yet fixed on Oct 23)
    sql = """
    SELECT ein_charity_number
    FROM nonprofits
    WHERE DATE(created_at) = '2025-10-22'
      AND NOT (updated_at > created_at AND DATE(updated_at) = '2025-10-23')
      AND (name LIKE '%LLC%' OR name LIKE '%LLP%' OR name LIKE '%& Co%' OR name LIKE '%CPA%' OR name LIKE '%P.C.%')
    LIMIT 100000;
    """

    # Use Supabase MCP to get the data
    try:
        result = subprocess.run(
            ['claude', 'mcp', 'call', 'supabase', 'execute_sql',
             '--project_id', 'hjtvtkffpziopozmtsnb',
             '--query', sql],
            capture_output=True,
            text=True,
            timeout=60
        )

        if result.returncode == 0:
            # Parse the JSON result
            import re
            match = re.search(r'\[.*\]', result.stdout, re.DOTALL)
            if match:
                records = json.loads(match.group(0))
                eins = [r['ein_charity_number'] for r in records]
                print(f"✅ Found {len(eins):,} corrupted EINs")
                return eins

        print(f"⚠️  Could not fetch from database: {result.stderr}")
        return []

    except Exception as e:
        print(f"❌ Error fetching corrupted EINs: {e}")
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
        f.write("-- Generated from IRS Business Master File data\n\n")

        for update in updates:
            f.write(update + "\n")

    print(f"✅ Saved {len(updates):,} UPDATE statements")
    print(f"📁 File: {OUTPUT_FILE}")
    print(f"📊 File size: {OUTPUT_FILE.stat().st_size / 1024 / 1024:.1f}MB")

def main():
    print("🚀 Fix Remaining Corrupted Nonprofit Names")
    print("=" * 80)

    # Load IRS data
    irs_data = load_irs_data()

    # Get corrupted EINs from database
    corrupted_eins = get_corrupted_eins_from_db()

    if not corrupted_eins:
        print("\n⚠️  No corrupted EINs found or database query failed")
        return 1

    # Generate UPDATE statements
    updates = generate_update_statements(corrupted_eins, irs_data)

    if not updates:
        print("\n⚠️  No updates generated")
        return 1

    # Save to file
    save_update_statements(updates)

    print("\n" + "=" * 80)
    print("✅ Ready to apply fixes!")
    print("\nNext step: Run the same script that worked before:")
    print(f"  ~/run-all-batches-tableplus.sh")
    print("\nOr apply the single file:")
    print(f"  Open {OUTPUT_FILE} in TablePlus and run it")
    print("=" * 80)

    return 0

if __name__ == "__main__":
    sys.exit(main())
