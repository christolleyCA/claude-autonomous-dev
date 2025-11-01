#!/usr/bin/env python3
"""
Update nonprofit websites from IRS 990 data CSV
- Adds website field with cleaned URLs
- Adds public_facing boolean categorization
- Matches by EIN and uses most recent tax year data
"""

import csv
import json
import sys
import subprocess
from pathlib import Path
from collections import defaultdict

# Files
CSV_FILE = Path.home() / "Downloads" / "charties with website.csv"
OUTPUT_DIR = Path.home() / "nonprofit_website_updates"
OUTPUT_FILE = OUTPUT_DIR / "website_updates.sql"

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"

def clean_website(raw_website):
    """Clean and normalize website URL"""
    if not raw_website:
        return None, False

    website = raw_website.strip()

    # Determine if public facing based on prefix
    is_public_facing = True

    # Remove quotes
    if website.startswith('"') and website.endswith('"'):
        website = website[1:-1].strip()
        is_public_facing = False  # Quoted = malformed data

    # Check for special prefixes that indicate non-public-facing
    if website.startswith('.'):
        website = website[1:]  # Remove leading dot
        is_public_facing = False
    elif website.startswith('@'):
        website = website[1:]  # Remove @ symbol
        is_public_facing = False  # Social media handle
    elif website.startswith('//'):
        website = website[2:]  # Remove //
        is_public_facing = False  # Internal page/subdomain
    elif website.startswith('/'):
        website = website[1:]  # Remove /
        is_public_facing = False  # Internal page
    elif website.startswith('<'):
        # Remove HTML tags
        website = website.replace('<', '').replace('>', '')
        is_public_facing = False

    # Clean up common issues
    website = website.strip()

    # Ensure http:// or https:// prefix for proper URLs
    if website and not website.lower().startswith(('http://', 'https://')):
        # Check if it looks like a domain
        if '.' in website and ' ' not in website:
            website = 'https://' + website

    return website if website else None, is_public_facing


def load_csv_data():
    """Load website data from CSV, keeping most recent per EIN"""
    print("📂 Loading website data from CSV...")

    # Dictionary to store most recent website per EIN
    ein_websites = {}

    with open(CSV_FILE, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)
        total_rows = 0

        for row in reader:
            total_rows += 1

            ein = row['FILEREIN'].strip()
            raw_website = row['WEBSITSITEIT'].strip()
            tax_year = int(row['TAXYEAR']) if row['TAXYEAR'].strip() else 0

            if not ein or not raw_website:
                continue

            # Keep most recent tax year for each EIN
            if ein not in ein_websites or tax_year > ein_websites[ein]['tax_year']:
                ein_websites[ein] = {
                    'raw_website': raw_website,
                    'tax_year': tax_year
                }

            if total_rows % 100000 == 0:
                print(f"   Processed {total_rows:,} rows...")

    print(f"✅ Loaded {total_rows:,} total rows")
    print(f"✅ Found {len(ein_websites):,} unique EINs with websites\n")

    return ein_websites


def get_all_nonprofits():
    """Get all nonprofit EINs from database"""
    print("🔍 Fetching nonprofit EINs from database...")

    sql = """
    SELECT ein_charity_number
    FROM nonprofits
    WHERE DATE(created_at) = '2025-10-22'
    ORDER BY ein_charity_number;
    """

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-t', '-A', '-c', sql],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=60
        )

        if result.returncode == 0:
            eins = [line.strip() for line in result.stdout.strip().split('\n') if line.strip()]
            print(f"✅ Found {len(eins):,} nonprofits in database\n")
            return set(eins)
        else:
            print(f"❌ Query failed: {result.stderr}")
            return set()

    except Exception as e:
        print(f"❌ Error: {e}")
        return set()


def generate_updates(csv_data, db_eins):
    """Generate SQL UPDATE statements"""
    print("🔨 Generating UPDATE statements...")

    updates = []
    stats = {
        'matched': 0,
        'not_in_db': 0,
        'public_facing': 0,
        'not_public_facing': 0,
        'cleaned': 0
    }

    for ein, data in csv_data.items():
        if ein not in db_eins:
            stats['not_in_db'] += 1
            continue

        stats['matched'] += 1

        # Clean website
        cleaned_website, is_public_facing = clean_website(data['raw_website'])

        if not cleaned_website:
            continue

        if is_public_facing:
            stats['public_facing'] += 1
        else:
            stats['not_public_facing'] += 1
            stats['cleaned'] += 1

        # Escape for SQL
        website_escaped = cleaned_website.replace("'", "''")

        # Generate UPDATE statement
        update_sql = f"""UPDATE nonprofits SET website = '{website_escaped}', public_facing = {is_public_facing}, updated_at = NOW() WHERE ein_charity_number = '{ein}';"""
        updates.append(update_sql)

    print(f"\n📊 Statistics:")
    print(f"   Matched with database: {stats['matched']:,}")
    print(f"   Not in database: {stats['not_in_db']:,}")
    print(f"   Public facing websites: {stats['public_facing']:,}")
    print(f"   Non-public facing (social/internal): {stats['not_public_facing']:,}")
    print(f"   Websites needing cleaning: {stats['cleaned']:,}")

    return updates


def save_updates(updates):
    """Save UPDATE statements to file"""
    print(f"\n💾 Saving to {OUTPUT_FILE}...")

    OUTPUT_DIR.mkdir(exist_ok=True)

    with open(OUTPUT_FILE, 'w') as f:
        f.write("-- Update nonprofit websites from IRS 990 data\n")
        f.write("-- Adds website URLs and public_facing categorization\n")
        f.write(f"-- Total updates: {len(updates):,}\n\n")

        for update in updates:
            f.write(update + "\n")

    size_mb = OUTPUT_FILE.stat().st_size / 1024 / 1024
    print(f"✅ Saved {len(updates):,} UPDATE statements")
    print(f"📁 File: {OUTPUT_FILE}")
    print(f"📊 Size: {size_mb:.1f}MB")


def main():
    print("🌐 Update Nonprofit Websites from IRS 990 Data")
    print("=" * 80)
    print()

    # Load CSV data
    csv_data = load_csv_data()

    if not csv_data:
        print("❌ No website data loaded!")
        return 1

    # Get database EINs
    db_eins = get_all_nonprofits()

    if not db_eins:
        print("❌ No database records!")
        return 1

    # Generate updates
    updates = generate_updates(csv_data, db_eins)

    if not updates:
        print("\n✅ No updates needed!")
        return 0

    # Save to file
    save_updates(updates)

    print("\n" + "=" * 80)
    print("✅ Ready to apply website updates!")
    print("\nNext steps:")
    print("1. Review the SQL file if needed")
    print("2. The file will need to be split into batches")
    print("3. Apply batches sequentially to database")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    sys.exit(main())
