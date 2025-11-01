#!/usr/bin/env python3
"""
Fix nonprofit addresses using authoritative IRS CSV data
Updates: address, city, state, ZIP in contact_info JSONB field
"""

import csv
import json
import sys
import subprocess
from pathlib import Path

# IRS CSV files
IRS_CSV_FILES = [
    Path.home() / "Downloads" / "eo1.csv",
    Path.home() / "Downloads" / "eo2.csv",
    Path.home() / "Downloads" / "eo3.csv",
    Path.home() / "Downloads" / "eo4.csv",
]

OUTPUT_DIR = Path.home() / "nonprofit_address_fixes"
OUTPUT_FILE = OUTPUT_DIR / "address_fixes.sql"

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"

def load_irs_addresses():
    """Load address data from IRS CSV files"""
    print("📂 Loading IRS address data...")

    irs_data = {}
    total = 0

    for csv_file in IRS_CSV_FILES:
        if not csv_file.exists():
            continue

        print(f"   Reading {csv_file.name}...")

        with open(csv_file, 'r', encoding='utf-8', errors='replace') as f:
            reader = csv.DictReader(f)
            count = 0

            for row in reader:
                ein = row['EIN'].strip()
                irs_data[ein] = {
                    'street': row.get('STREET', '').strip(),
                    'city': row.get('CITY', '').strip(),
                    'state': row.get('STATE', '').strip(),
                    'zip': row.get('ZIP', '').strip(),
                }
                count += 1

            total += count

    print(f"✅ Loaded {total:,} IRS address records\n")
    return irs_data

def get_all_nonprofits():
    """Get all nonprofit records with contact info"""
    print("🔍 Fetching all nonprofits from database...")

    sql = """
    SELECT
        ein_charity_number,
        contact_info
    FROM nonprofits
    WHERE DATE(created_at) = '2025-10-22'
    ORDER BY ein_charity_number;
    """

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
                    parts = line.split('|', 1)
                    if len(parts) == 2:
                        ein = parts[0]
                        contact_info = {}
                        try:
                            if parts[1] and parts[1] != '':
                                contact_info = json.loads(parts[1])
                        except Exception as e:
                            # If parsing fails, contact_info stays as empty dict
                            pass

                        records.append({
                            'ein': ein,
                            'contact_info': contact_info if isinstance(contact_info, dict) else {}
                        })

            print(f"✅ Fetched {len(records):,} records\n")
            return records
        else:
            print(f"❌ Query failed: {result.stderr}")
            return []

    except Exception as e:
        print(f"❌ Error: {e}")
        return []

def normalize_text(text):
    """Normalize for comparison"""
    return text.upper().strip() if text else ""

def needs_update(db_contact, irs_address):
    """Check if address needs updating"""
    db_addr = normalize_text(db_contact.get('address', ''))
    db_city = normalize_text(db_contact.get('city', ''))
    db_state = normalize_text(db_contact.get('state', ''))
    db_zip = db_contact.get('zip', '').strip().split('-')[0]  # Base ZIP only

    irs_addr = normalize_text(irs_address['street'])
    irs_city = normalize_text(irs_address['city'])
    irs_state = normalize_text(irs_address['state'])
    irs_zip = irs_address['zip'].strip().split('-')[0]  # Base ZIP only

    # Check if any field is different
    if (db_addr != irs_addr or
        db_city != irs_city or
        db_state != irs_state or
        db_zip != irs_zip):
        return True

    return False

def escape_sql_string(text):
    """Escape string for SQL"""
    if not text:
        return ""
    # Escape single quotes and backslashes
    return text.replace("\\", "\\\\").replace("'", "''")

def generate_address_updates(db_records, irs_data):
    """Generate SQL UPDATE statements for addresses"""
    print("🔨 Generating address UPDATE statements...")

    updates = []
    matched = 0
    not_in_irs = 0
    no_change_needed = 0
    will_update = 0

    stats = {
        'address_changes': 0,
        'city_changes': 0,
        'state_changes': 0,
        'zip_changes': 0
    }

    for record in db_records:
        ein = record['ein']
        db_contact = record['contact_info']

        if ein not in irs_data:
            not_in_irs += 1
            continue

        matched += 1
        irs_addr = irs_data[ein]

        if not needs_update(db_contact, irs_addr):
            no_change_needed += 1
            continue

        # Track what's changing
        if normalize_text(db_contact.get('address', '')) != normalize_text(irs_addr['street']):
            stats['address_changes'] += 1
        if normalize_text(db_contact.get('city', '')) != normalize_text(irs_addr['city']):
            stats['city_changes'] += 1
        if normalize_text(db_contact.get('state', '')) != normalize_text(irs_addr['state']):
            stats['state_changes'] += 1
        if db_contact.get('zip', '').split('-')[0] != irs_addr['zip'].split('-')[0]:
            stats['zip_changes'] += 1

        # Preserve phone number if it exists
        phone = db_contact.get('phone', '')

        # Build new contact_info JSONB
        new_contact = {
            'address': irs_addr['street'],
            'city': irs_addr['city'],
            'state': irs_addr['state'],
            'zip': irs_addr['zip']
        }

        if phone:
            new_contact['phone'] = phone

        # Escape for JSON in SQL
        contact_json = json.dumps(new_contact).replace("'", "''")

        # Generate UPDATE statement
        update_sql = f"UPDATE nonprofits SET contact_info = '{contact_json}'::jsonb, updated_at = NOW() WHERE ein_charity_number = '{ein}';"
        updates.append(update_sql)
        will_update += 1

    print(f"\n📊 Analysis:")
    print(f"   Total records: {len(db_records):,}")
    print(f"   Matched with IRS: {matched:,}")
    print(f"   Not in IRS data: {not_in_irs:,}")
    print(f"   Already correct: {no_change_needed:,}")
    print(f"   Need updating: {will_update:,}")

    print(f"\n🔄 Changes breakdown:")
    print(f"   Address changes: {stats['address_changes']:,}")
    print(f"   City changes: {stats['city_changes']:,}")
    print(f"   State changes: {stats['state_changes']:,}")
    print(f"   ZIP changes: {stats['zip_changes']:,}")

    return updates

def save_updates(updates):
    """Save UPDATE statements to file"""
    print(f"\n💾 Saving to {OUTPUT_FILE}...")

    OUTPUT_DIR.mkdir(exist_ok=True)

    with open(OUTPUT_FILE, 'w') as f:
        f.write("-- Fix nonprofit addresses using authoritative IRS CSV data\n")
        f.write("-- Updates: address, city, state, ZIP in contact_info JSONB\n")
        f.write(f"-- Total updates: {len(updates):,}\n\n")

        for update in updates:
            f.write(update + "\n")

    size_mb = OUTPUT_FILE.stat().st_size / 1024 / 1024
    print(f"✅ Saved {len(updates):,} UPDATE statements")
    print(f"📁 File: {OUTPUT_FILE}")
    print(f"📊 Size: {size_mb:.1f}MB")

def main():
    print("🏠 Fix Nonprofit Addresses from IRS Data")
    print("=" * 80)
    print()

    # Load IRS addresses
    irs_data = load_irs_addresses()

    if not irs_data:
        print("❌ No IRS data loaded!")
        return 1

    # Get all nonprofit records
    db_records = get_all_nonprofits()

    if not db_records:
        print("❌ No database records!")
        return 1

    # Generate updates
    updates = generate_address_updates(db_records, irs_data)

    if not updates:
        print("\n✅ All addresses are already correct!")
        return 0

    # Save to file
    save_updates(updates)

    print("\n" + "=" * 80)
    print("✅ Ready to apply address fixes!")
    print("\nThe file will need to be split into batches for application.")
    print("=" * 80)

    return 0

if __name__ == "__main__":
    sys.exit(main())
