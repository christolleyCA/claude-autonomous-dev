#!/usr/bin/env python3
"""
Spot check 200 random nonprofit records against IRS CSV data
Compare: Name, Address, City, State, ZIP, and other fields
"""

import csv
import json
import sys
import subprocess
from pathlib import Path
from collections import defaultdict

# IRS CSV files
IRS_CSV_FILES = [
    Path.home() / "Downloads" / "eo1.csv",
    Path.home() / "Downloads" / "eo2.csv",
    Path.home() / "Downloads" / "eo3.csv",
    Path.home() / "Downloads" / "eo4.csv",
]

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"

def load_irs_data():
    """Load IRS CSV data into memory"""
    print("📂 Loading IRS CSV files...")

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
                    'name': row['NAME'].strip(),
                    'ico': row.get('ICO', '').strip(),  # In Care Of
                    'street': row.get('STREET', '').strip(),
                    'city': row.get('CITY', '').strip(),
                    'state': row.get('STATE', '').strip(),
                    'zip': row.get('ZIP', '').strip(),
                    'subsection': row.get('SUBSECTION', '').strip(),
                    'classification': row.get('CLASSIFICATION', '').strip(),
                    'deductibility': row.get('DEDUCTIBILITY', '').strip(),
                    'foundation': row.get('FOUNDATION', '').strip(),
                    'status': row.get('STATUS', '').strip(),
                    'income_amt': row.get('INCOME_AMT', '').strip(),
                }
                count += 1

            total += count

    print(f"✅ Loaded {total:,} IRS records\n")
    return irs_data

def get_random_sample():
    """Get 200 random nonprofit records from database"""
    print("🎲 Fetching 200 random records from database...")

    sql = """
    SELECT
        ein_charity_number,
        name,
        contact_info,
        annual_revenue,
        tax_status,
        organization_type
    FROM nonprofits
    WHERE DATE(created_at) = '2025-10-22'
    ORDER BY RANDOM()
    LIMIT 200;
    """

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-t', '-A', '-c', sql],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=30
        )

        if result.returncode == 0:
            records = []
            for line in result.stdout.strip().split('\n'):
                if '|' in line:
                    parts = line.split('|')
                    if len(parts) >= 6:
                        contact_info = {}
                        try:
                            contact_info = json.loads(parts[2]) if parts[2] else {}
                        except:
                            pass

                        records.append({
                            'ein': parts[0],
                            'name': parts[1],
                            'contact_info': contact_info,
                            'annual_revenue': parts[3],
                            'tax_status': parts[4],
                            'organization_type': parts[5],
                        })

            print(f"✅ Fetched {len(records)} records\n")
            return records
        else:
            print(f"❌ Query failed: {result.stderr}")
            return []

    except Exception as e:
        print(f"❌ Error: {e}")
        return []

def normalize_text(text):
    """Normalize text for comparison"""
    if not text:
        return ""
    return text.upper().strip()

def compare_address(db_addr, irs_addr):
    """Compare addresses (allowing for minor differences)"""
    db_norm = normalize_text(db_addr)
    irs_norm = normalize_text(irs_addr)

    if db_norm == irs_norm:
        return True, "exact"

    # Check if one contains the other (common with abbreviations)
    if db_norm in irs_norm or irs_norm in db_norm:
        return True, "similar"

    return False, "different"

def spot_check_records(db_records, irs_data):
    """Compare database records against IRS data"""
    print("🔍 Spot Checking Records...")
    print("=" * 100)

    results = {
        'total': len(db_records),
        'in_irs': 0,
        'not_in_irs': 0,
        'name_match': 0,
        'name_mismatch': 0,
        'address_match': 0,
        'address_similar': 0,
        'address_different': 0,
        'city_match': 0,
        'city_mismatch': 0,
        'state_match': 0,
        'state_mismatch': 0,
        'zip_match': 0,
        'zip_mismatch': 0,
        'issues': []
    }

    for i, record in enumerate(db_records, 1):
        ein = record['ein']

        if ein not in irs_data:
            results['not_in_irs'] += 1
            continue

        results['in_irs'] += 1
        irs = irs_data[ein]

        # Compare Name
        if normalize_text(record['name']) == normalize_text(irs['name']):
            results['name_match'] += 1
        else:
            results['name_mismatch'] += 1
            results['issues'].append({
                'ein': ein,
                'field': 'NAME',
                'db_value': record['name'],
                'irs_value': irs['name']
            })

        # Compare Address
        db_addr = record['contact_info'].get('address', '')
        irs_addr = irs['street']

        if db_addr and irs_addr:
            match, match_type = compare_address(db_addr, irs_addr)
            if match_type == "exact":
                results['address_match'] += 1
            elif match_type == "similar":
                results['address_similar'] += 1
            else:
                results['address_different'] += 1
                if i <= 10:  # Show first 10 address issues
                    results['issues'].append({
                        'ein': ein,
                        'field': 'ADDRESS',
                        'db_value': db_addr,
                        'irs_value': irs_addr
                    })

        # Compare City
        db_city = record['contact_info'].get('city', '')
        irs_city = irs['city']

        if db_city and irs_city:
            if normalize_text(db_city) == normalize_text(irs_city):
                results['city_match'] += 1
            else:
                results['city_mismatch'] += 1
                if i <= 10:
                    results['issues'].append({
                        'ein': ein,
                        'field': 'CITY',
                        'db_value': db_city,
                        'irs_value': irs_city
                    })

        # Compare State
        db_state = record['contact_info'].get('state', '')
        irs_state = irs['state']

        if db_state and irs_state:
            if normalize_text(db_state) == normalize_text(irs_state):
                results['state_match'] += 1
            else:
                results['state_mismatch'] += 1
                if i <= 10:
                    results['issues'].append({
                        'ein': ein,
                        'field': 'STATE',
                        'db_value': db_state,
                        'irs_value': irs_state
                    })

        # Compare ZIP
        db_zip = record['contact_info'].get('zip', '')
        irs_zip = irs['zip']

        if db_zip and irs_zip:
            # Normalize ZIP (remove extensions, etc.)
            db_zip_norm = db_zip.split('-')[0].strip()
            irs_zip_norm = irs_zip.split('-')[0].strip()

            if db_zip_norm == irs_zip_norm:
                results['zip_match'] += 1
            else:
                results['zip_mismatch'] += 1
                if i <= 10:
                    results['issues'].append({
                        'ein': ein,
                        'field': 'ZIP',
                        'db_value': db_zip,
                        'irs_value': irs_zip
                    })

    return results

def print_results(results):
    """Print spot check results"""
    print("\n" + "=" * 100)
    print("📊 SPOT CHECK RESULTS (200 Random Records)")
    print("=" * 100)

    print(f"\n🔍 Coverage:")
    print(f"   Total records checked: {results['total']}")
    print(f"   Found in IRS data: {results['in_irs']} ({results['in_irs']/results['total']*100:.1f}%)")
    print(f"   Not in IRS data: {results['not_in_irs']} ({results['not_in_irs']/results['total']*100:.1f}%)")

    if results['in_irs'] > 0:
        print(f"\n✅ Name Accuracy:")
        print(f"   Matches: {results['name_match']}/{results['in_irs']} ({results['name_match']/results['in_irs']*100:.1f}%)")
        print(f"   Mismatches: {results['name_mismatch']}/{results['in_irs']} ({results['name_mismatch']/results['in_irs']*100:.1f}%)")

        addr_total = results['address_match'] + results['address_similar'] + results['address_different']
        if addr_total > 0:
            print(f"\n🏠 Address Accuracy:")
            print(f"   Exact matches: {results['address_match']}/{addr_total} ({results['address_match']/addr_total*100:.1f}%)")
            print(f"   Similar (abbreviations): {results['address_similar']}/{addr_total} ({results['address_similar']/addr_total*100:.1f}%)")
            print(f"   Different: {results['address_different']}/{addr_total} ({results['address_different']/addr_total*100:.1f}%)")

        city_total = results['city_match'] + results['city_mismatch']
        if city_total > 0:
            print(f"\n🏙️  City Accuracy:")
            print(f"   Matches: {results['city_match']}/{city_total} ({results['city_match']/city_total*100:.1f}%)")
            print(f"   Mismatches: {results['city_mismatch']}/{city_total} ({results['city_mismatch']/city_total*100:.1f}%)")

        state_total = results['state_match'] + results['state_mismatch']
        if state_total > 0:
            print(f"\n🗺️  State Accuracy:")
            print(f"   Matches: {results['state_match']}/{state_total} ({results['state_match']/state_total*100:.1f}%)")
            print(f"   Mismatches: {results['state_mismatch']}/{state_total} ({results['state_mismatch']/state_total*100:.1f}%)")

        zip_total = results['zip_match'] + results['zip_mismatch']
        if zip_total > 0:
            print(f"\n📮 ZIP Code Accuracy:")
            print(f"   Matches: {results['zip_match']}/{zip_total} ({results['zip_match']/zip_total*100:.1f}%)")
            print(f"   Mismatches: {results['zip_mismatch']}/{zip_total} ({results['zip_mismatch']/zip_total*100:.1f}%)")

    if results['issues']:
        print(f"\n⚠️  Sample Issues Found (first 10):")
        print("-" * 100)
        for i, issue in enumerate(results['issues'][:20], 1):
            print(f"\n{i}. EIN: {issue['ein']} | Field: {issue['field']}")
            print(f"   Database: {issue['db_value']}")
            print(f"   IRS:      {issue['irs_value']}")

    print("\n" + "=" * 100)

def main():
    print("🔍 SPOT CHECK: 200 Random Records vs IRS Data")
    print("=" * 100)
    print()

    # Load IRS data
    irs_data = load_irs_data()

    if not irs_data:
        print("❌ No IRS data loaded!")
        return 1

    # Get random sample from database
    db_records = get_random_sample()

    if not db_records:
        print("❌ No database records retrieved!")
        return 1

    # Compare
    results = spot_check_records(db_records, irs_data)

    # Print results
    print_results(results)

    return 0

if __name__ == "__main__":
    sys.exit(main())
