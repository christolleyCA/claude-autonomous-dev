#!/usr/bin/env python3
"""
Process charity CSV file using simple UPSERT strategy

Uses Supabase's built-in conflict resolution to update/insert efficiently
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
BATCH_SIZE = 500

def normalize_website(url):
    """Normalize website URL"""
    if not url:
        return ''

    url = url.strip()

    # Skip invalid entries
    if url.upper() in ['N/A', 'NA', 'NONE', 'NULL', 'NOT APPLICABLE', 'S3.AMAZONAWS.COM']:
        return ''

    # Remove common prefixes
    url = re.sub(r'^WWW\.', '', url, flags=re.IGNORECASE)
    url = re.sub(r'^HTTPS?://', '', url, flags=re.IGNORECASE)

    # Remove trailing slashes and paths
    url = url.split('/')[0]

    # Add protocol
    if url and not url.startswith('http'):
        url = 'https://' + url

    # Basic validation
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

def upload_batch(batch):
    """Upload batch using UPSERT (merge-duplicates)"""
    try:
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/nonprofits",
            headers={
                'apikey': SUPABASE_KEY,
                'Authorization': f'Bearer {SUPABASE_KEY}',
                'Content-Type': 'application/json',
                'Prefer': 'resolution=merge-duplicates'
            },
            json=batch,
            timeout=60
        )

        if response.status_code in [200, 201]:
            return True, len(batch)
        else:
            print(f"      ⚠️ Batch upload warning: {response.status_code} - {response.text[:200]}")
            return False, 0

    except Exception as e:
        print(f"      ❌ Batch upload error: {e}")
        return False, 0

def main():
    print("=" * 80)
    print("  CHARITY CSV PROCESSOR (SIMPLE UPSERT)")
    print("=" * 80)
    print(f"\n📂 Reading CSV: {CSV_FILE}\n")

    total_rows = 0
    total_with_websites = 0
    total_skipped = 0
    total_uploaded = 0
    batch = []

    try:
        with open(CSV_FILE, 'r', encoding='utf-8', errors='ignore') as f:
            reader = csv.DictReader(f)

            for row_num, row in enumerate(reader, 1):
                try:
                    # Extract fields
                    ein = normalize_ein(row.get('FILEREIN', ''))
                    name = row.get('FILERNAME1', '').strip()
                    website = normalize_website(row.get('WEBSITSITEIT', ''))

                    # Skip if no EIN, name, or website
                    if not ein or not name or not website:
                        total_skipped += 1
                        continue

                    total_rows += 1
                    total_with_websites += 1

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

                    # Upload batch when it reaches size
                    if len(batch) >= BATCH_SIZE:
                        success, count = upload_batch(batch)
                        if success:
                            total_uploaded += count
                        batch = []

                        # Progress update every 1000 rows
                        if row_num % 1000 == 0:
                            print(f"   {row_num:,} rows processed... ({total_uploaded:,} uploaded)")
                            sys.stdout.flush()  # Force output

                except Exception as e:
                    total_skipped += 1
                    continue

            # Upload remaining batch
            if batch:
                success, count = upload_batch(batch)
                if success:
                    total_uploaded += count

        print("\n" + "=" * 80)
        print("  ✅ PROCESSING COMPLETE!")
        print("=" * 80)
        print(f"\n📊 Summary:")
        print(f"   Total CSV rows processed: {total_rows:,}")
        print(f"   With valid websites: {total_with_websites:,}")
        print(f"   Skipped (invalid/no website): {total_skipped:,}")
        print(f"   Uploaded to database (upsert): {total_uploaded:,}")
        print(f"\n✅ Database updated successfully!\n")
        print(f"Note: merge-duplicates will update existing EINs or insert new ones\n")

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
