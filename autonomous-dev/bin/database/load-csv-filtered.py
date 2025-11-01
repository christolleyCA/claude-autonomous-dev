#!/usr/bin/env python3
"""
Load new nonprofits by pre-filtering against existing EINs
"""

import os
import sys
import csv
import json
import requests
import re
from datetime import datetime

# Configuration
SUPABASE_URL = "https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

CSV_FILE = os.path.expanduser("~/Downloads/charities_domains_cleaned.csv")
BATCH_SIZE = 1000

def normalize_website(url):
    """Normalize website URL"""
    if not url:
        return ''

    url = url.strip()

    if url.upper() in ['N/A', 'NA', 'NONE', 'NULL', 'NOT APPLICABLE', 'S3.AMAZONAWS.COM']:
        return ''

    url = re.sub(r'^WWW\.', '', url, flags=re.IGNORECASE)
    url = re.sub(r'^HTTPS?://', '', url, flags=re.IGNORECASE)
    url = url.split('/')[0]

    if url and not url.startswith('http'):
        url = 'https://' + url

    if len(url) < 10 or ' ' in url:
        return ''

    return url.lower()

def normalize_ein(ein):
    """Normalize EIN to 9-digit format"""
    if not ein:
        return None

    ein_str = str(ein).replace('-', '').strip()

    if ein_str.isdigit() and len(ein_str) <= 9:
        return ein_str.zfill(9)

    return None

def fetch_all_existing_eins():
    """Fetch all EINs from database"""
    print("📊 Fetching existing EINs from database...")
    existing_eins = set()
    offset = 0
    limit = 1000

    while True:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/nonprofits",
            headers={
                'apikey': SUPABASE_KEY,
                'Authorization': f'Bearer {SUPABASE_KEY}',
            },
            params={
                'select': 'ein_charity_number',
                'limit': limit,
                'offset': offset
            },
            timeout=30
        )

        if response.status_code != 200:
            print(f"   ⚠️  Error: {response.status_code}")
            break

        data = response.json()
        if not data:
            break

        for row in data:
            ein = row.get('ein_charity_number')
            if ein:
                existing_eins.add(ein)

        if len(data) < limit:
            break

        offset += limit

        if offset % 10000 == 0:
            print(f"   Fetched {len(existing_eins):,} EINs...")

    print(f"   ✅ Total existing EINs: {len(existing_eins):,}\n")
    return existing_eins

def upload_batch(batch):
    """Upload batch"""
    try:
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/nonprofits",
            headers={
                'apikey': SUPABASE_KEY,
                'Authorization': f'Bearer {SUPABASE_KEY}',
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal'
            },
            json=batch,
            timeout=60
        )

        if response.status_code in [200, 201]:
            return True
        else:
            print(f"      ⚠️  Upload error: {response.status_code}")
            return False

    except Exception as e:
        print(f"      ❌  Upload exception: {e}")
        return False

def main():
    print("=" * 80)
    print("  CHARITY CSV LOADER (PRE-FILTERED)")
    print("=" * 80)
    print(f"\n📂 CSV File: {CSV_FILE}\n")

    # Step 1: Fetch existing EINs
    existing_eins = fetch_all_existing_eins()

    # Step 2: Process CSV and filter
    print("📂 Processing CSV and filtering new nonprofits...")

    total_rows = 0
    total_skipped_no_data = 0
    total_skipped_duplicate = 0
    total_new = 0
    total_uploaded = 0
    batch = []
    batch_num = 0

    try:
        with open(CSV_FILE, 'r', encoding='utf-8', errors='ignore') as f:
            reader = csv.DictReader(f)

            for row_num, row in enumerate(reader, 1):
                try:
                    ein = normalize_ein(row.get('FILEREIN', ''))
                    name = row.get('FILERNAME1', '').strip()
                    website = normalize_website(row.get('WEBSITSITEIT', ''))

                    if not ein or not name or not website:
                        total_skipped_no_data += 1
                        continue

                    total_rows += 1

                    # Skip if EIN already exists
                    if ein in existing_eins:
                        total_skipped_duplicate += 1
                        continue

                    total_new += 1

                    # Build nonprofit record
                    nonprofit_data = {
                        'ein_charity_number': ein,
                        'name': name,
                        'country': 'US',
                        'website': website,
                        'contact_info': json.dumps({
                            'address': row.get('FILERUS1', ''),
                            'address2': row.get('FILERUS2', ''),
                            'city': row.get('FILERUSCITY', ''),
                            'state': row.get('FILERUSSTATE', ''),
                            'zip': str(row.get('FILERUSZIP', '')).split('.')[0],
                            'phone': ''
                        }),
                        'annual_revenue': int(float(row.get('TOTREVCURYEA', 0) or 0)),
                        'tax_status': '501(c)(3)',
                        'organization_type': 'Public Charity',
                        'is_foundation': False,
                        'created_at': datetime.utcnow().isoformat(),
                        'updated_at': datetime.utcnow().isoformat()
                    }

                    batch.append(nonprofit_data)

                    # Upload batch
                    if len(batch) >= BATCH_SIZE:
                        batch_num += 1
                        if upload_batch(batch):
                            total_uploaded += len(batch)
                        batch = []

                        if batch_num % 10 == 0:
                            print(f"   {total_new:,} new nonprofits found, {total_uploaded:,} uploaded ({batch_num} batches)")
                            sys.stdout.flush()

                except Exception as e:
                    total_skipped_no_data += 1
                    continue

            # Upload remaining
            if batch:
                batch_num += 1
                if upload_batch(batch):
                    total_uploaded += len(batch)

        print("\n" + "=" * 80)
        print("  ✅ PROCESSING COMPLETE!")
        print("=" * 80)
        print(f"\n📊 Summary:")
        print(f"   Total CSV rows with valid data: {total_rows:,}")
        print(f"   Skipped (no data): {total_skipped_no_data:,}")
        print(f"   Skipped (duplicates): {total_skipped_duplicate:,}")
        print(f"   NEW nonprofits found: {total_new:,}")
        print(f"   Successfully uploaded: {total_uploaded:,}")
        print(f"   Total batches: {batch_num}")
        print(f"\n✅ New nonprofits added to database!\n")

    except Exception as e:
        print(f"\n\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user.\n")
        sys.exit(0)
