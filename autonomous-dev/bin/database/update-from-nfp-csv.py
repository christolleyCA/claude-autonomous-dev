#!/usr/bin/env python3
"""
Update nonprofit websites from the user's CSV file
Matches by organization name and updates website + public_facing fields
"""

import csv
import sys
import subprocess
from pathlib import Path

# Files
CSV_FILE = Path.home() / "Downloads" / "nfp with websites.csv"

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"

def normalize_name(name):
    """Normalize name for matching"""
    return name.upper().strip()

def load_csv_data():
    """Load CSV file"""
    print("📂 Loading CSV file...")

    orgs = []
    with open(CSV_FILE, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            name = row['Name'].strip()
            classification = row['Classification'].strip()
            website = row['Website'].strip() if row['Website'] else ''

            # Determine public_facing
            public_facing = (classification == 'public-facing')

            orgs.append({
                'name': name,
                'normalized_name': normalize_name(name),
                'website': website,
                'public_facing': public_facing,
                'classification': classification
            })

    print(f"✅ Loaded {len(orgs)} organizations from CSV")
    print(f"   Public-facing: {sum(1 for o in orgs if o['public_facing'])}")
    print(f"   Internal/Corporate: {sum(1 for o in orgs if not o['public_facing'])}")
    print(f"   With websites: {sum(1 for o in orgs if o['website'])}\n")

    return orgs

def get_all_nonprofits():
    """Get all nonprofit names and EINs from database"""
    print("🔍 Fetching nonprofits from database...")

    sql = """
    SELECT ein_charity_number, name
    FROM nonprofits
    WHERE DATE(created_at) = '2025-10-22'
    ORDER BY name;
    """

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-t', '-A', '-F', '|', '-c', sql],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=60
        )

        if result.returncode == 0:
            nonprofits = {}
            for line in result.stdout.strip().split('\n'):
                if '|' in line:
                    parts = line.split('|', 1)
                    if len(parts) == 2:
                        ein = parts[0].strip()
                        name = parts[1].strip()
                        normalized = normalize_name(name)
                        nonprofits[normalized] = {'ein': ein, 'name': name}

            print(f"✅ Found {len(nonprofits):,} nonprofits in database\n")
            return nonprofits
        else:
            print(f"❌ Query failed: {result.stderr}")
            return {}

    except Exception as e:
        print(f"❌ Error: {e}")
        return {}

def match_and_generate_updates(csv_orgs, db_nonprofits):
    """Match CSV orgs to database and generate UPDATE statements"""
    print("🔨 Matching organizations and generating UPDATEs...")

    updates = []
    stats = {
        'matched': 0,
        'not_found': 0,
        'with_website': 0,
        'without_website': 0,
        'public_facing': 0,
        'internal': 0
    }

    not_found = []

    for org in csv_orgs:
        normalized = org['normalized_name']

        # Try exact match
        if normalized in db_nonprofits:
            ein = db_nonprofits[normalized]['ein']
            stats['matched'] += 1

            website = org['website']
            public_facing = org['public_facing']

            if website:
                stats['with_website'] += 1
            else:
                stats['without_website'] += 1

            if public_facing:
                stats['public_facing'] += 1
            else:
                stats['internal'] += 1

            # Escape website for SQL
            if website:
                website_sql = f"'{website.replace(chr(39), chr(39)+chr(39))}'::text"
            else:
                website_sql = "NULL"

            # Generate UPDATE
            update_sql = f"UPDATE nonprofits SET website = {website_sql}, public_facing = {public_facing}, updated_at = NOW() WHERE ein_charity_number = '{ein}';"
            updates.append(update_sql)
        else:
            stats['not_found'] += 1
            not_found.append(org['name'])

    print(f"\n📊 Match Statistics:")
    print(f"   Total in CSV: {len(csv_orgs)}")
    print(f"   Matched: {stats['matched']}")
    print(f"   Not found: {stats['not_found']}")
    print(f"\n   With website: {stats['with_website']}")
    print(f"   Without website (classification only): {stats['without_website']}")
    print(f"\n   Public-facing: {stats['public_facing']}")
    print(f"   Internal/Corporate: {stats['internal']}")

    if not_found:
        print(f"\n⚠️  Organizations not found in database:")
        for name in not_found[:10]:  # Show first 10
            print(f"   - {name}")
        if len(not_found) > 10:
            print(f"   ... and {len(not_found) - 10} more")

    return updates

def apply_updates(updates):
    """Apply updates directly to database"""
    if not updates:
        print("\n✅ No updates to apply!")
        return True

    print(f"\n🚀 Applying {len(updates)} updates to database...")

    # Combine all updates into one transaction
    sql_script = "BEGIN;\n" + "\n".join(updates) + "\nCOMMIT;"

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-c', sql_script],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=60
        )

        if result.returncode == 0:
            print(f"✅ Successfully applied all updates!")
            return True
        else:
            print(f"❌ Failed to apply updates: {result.stderr}")
            return False

    except Exception as e:
        print(f"❌ Error applying updates: {e}")
        return False

def main():
    print("🌐 Update Nonprofits from CSV")
    print("=" * 80)
    print()

    # Load CSV
    csv_orgs = load_csv_data()

    if not csv_orgs:
        print("❌ No data in CSV!")
        return 1

    # Get database nonprofits
    db_nonprofits = get_all_nonprofits()

    if not db_nonprofits:
        print("❌ No database records!")
        return 1

    # Match and generate updates
    updates = match_and_generate_updates(csv_orgs, db_nonprofits)

    if not updates:
        print("\n✅ No matches found to update!")
        return 0

    # Apply updates
    success = apply_updates(updates)

    print("\n" + "=" * 80)
    if success:
        print("✅ All updates completed successfully!")
    else:
        print("❌ Some updates failed!")
    print("=" * 80)

    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
