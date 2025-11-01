#!/usr/bin/env python3
"""
Process charity CSV file and update/insert into database (OPTIMIZED)

Processes in batches, checking EINs against database on-the-fly
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
PROCESS_BATCH_SIZE = 100  # Process 100 rows at a time

class CharityCSVProcessor:
    def __init__(self):
        self.total_rows = 0
        self.total_with_websites = 0
        self.total_skipped = 0
        self.total_updated = 0
        self.total_inserted = 0

    def normalize_website(self, url):
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

    def normalize_ein(self, ein):
        """Normalize EIN to 9-digit format"""
        if not ein:
            return None

        ein_str = str(ein).replace('-', '').strip()

        if ein_str.isdigit() and len(ein_str) <= 9:
            return ein_str.zfill(9)

        return None

    def check_eins_exist(self, eins):
        """Check which EINs exist in database and whether they have websites"""
        if not eins:
            return {}

        # Build query for multiple EINs
        ein_list = ','.join([f'"{ein}"' for ein in eins])

        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/nonprofits",
            headers={
                'apikey': SUPABASE_KEY,
                'Authorization': f'Bearer {SUPABASE_KEY}',
            },
            params={
                'select': 'ein_charity_number,website',
                'ein_charity_number': f'in.({ein_list})'
            },
            timeout=30
        )

        if response.status_code != 200:
            print(f"   ⚠️  Error checking EINs: {response.status_code}")
            return {}

        results = {}
        for row in response.json():
            ein = row.get('ein_charity_number')
            website = row.get('website', '').strip()
            results[ein] = bool(website)

        return results

    def update_nonprofit(self, ein, website):
        """Update a single nonprofit's website"""
        response = requests.patch(
            f"{SUPABASE_URL}/rest/v1/nonprofits",
            headers={
                'apikey': SUPABASE_KEY,
                'Authorization': f'Bearer {SUPABASE_KEY}',
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal'
            },
            params={'ein_charity_number': f'eq.{ein}'},
            json={
                'website': website,
                'updated_at': datetime.utcnow().isoformat()
            },
            timeout=30
        )

        return response.status_code in [200, 204]

    def insert_nonprofits(self, batch):
        """Insert new nonprofits"""
        if not batch:
            return True

        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/nonprofits",
            headers={
                'apikey': SUPABASE_KEY,
                'Authorization': f'Bearer {SUPABASE_KEY}',
                'Content-Type': 'application/json',
                'Prefer': 'resolution=ignore-duplicates,return=minimal'
            },
            json=batch,
            timeout=60
        )

        return response.status_code in [200, 201]

    def process_batch(self, batch):
        """Process a batch of CSV rows"""
        if not batch:
            return

        # Extract EINs from batch
        eins = [row['ein'] for row in batch if row.get('ein')]

        # Check which EINs exist
        existing = self.check_eins_exist(eins)

        # Separate into updates and inserts
        to_update = []
        to_insert = []

        for row in batch:
            ein = row['ein']
            nonprofit_data = row['data']

            if ein in existing:
                # EIN exists
                has_website = existing[ein]
                if not has_website:
                    # Update with website
                    to_update.append((ein, nonprofit_data['website']))
            else:
                # New EIN - insert
                to_insert.append(nonprofit_data)

        # Apply updates
        for ein, website in to_update:
            if self.update_nonprofit(ein, website):
                self.total_updated += 1

        # Apply inserts
        if to_insert:
            if self.insert_nonprofits(to_insert):
                self.total_inserted += len(to_insert)

    def run(self):
        """Main execution"""
        print("=" * 80)
        print("  CHARITY CSV PROCESSOR (OPTIMIZED)")
        print("=" * 80)
        print(f"\n📂 Reading CSV: {CSV_FILE}\n")

        try:
            batch = []

            with open(CSV_FILE, 'r', encoding='utf-8', errors='ignore') as f:
                reader = csv.DictReader(f)

                for row_num, row in enumerate(reader, 1):
                    try:
                        # Extract fields
                        ein = self.normalize_ein(row.get('FILEREIN', ''))
                        name = row.get('FILERNAME1', '').strip()
                        website = self.normalize_website(row.get('WEBSITSITEIT', ''))

                        # Skip if no EIN, name, or website
                        if not ein or not name or not website:
                            self.total_skipped += 1
                            continue

                        self.total_rows += 1
                        self.total_with_websites += 1

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

                        # Add to batch
                        batch.append({
                            'ein': ein,
                            'data': nonprofit_data
                        })

                        # Process batch when it reaches size
                        if len(batch) >= PROCESS_BATCH_SIZE:
                            self.process_batch(batch)
                            batch = []

                            # Progress update
                            if row_num % 1000 == 0:
                                print(f"   {row_num:,} rows processed... ({self.total_updated:,} updated, {self.total_inserted:,} inserted)")

                    except Exception as e:
                        self.total_skipped += 1
                        continue

                # Process remaining batch
                if batch:
                    self.process_batch(batch)

            print("\n" + "=" * 80)
            print("  ✅ PROCESSING COMPLETE!")
            print("=" * 80)
            print(f"\n📊 Summary:")
            print(f"   Total CSV rows: {self.total_rows:,}")
            print(f"   With valid websites: {self.total_with_websites:,}")
            print(f"   Skipped (invalid/no website): {self.total_skipped:,}")
            print(f"   Existing nonprofits updated: {self.total_updated:,}")
            print(f"   New nonprofits inserted: {self.total_inserted:,}")
            print(f"\n✅ Database updated successfully!\n")

        except Exception as e:
            print(f"\n\n❌ Error: {e}")
            import traceback
            traceback.print_exc()
            sys.exit(1)

if __name__ == "__main__":
    try:
        processor = CharityCSVProcessor()
        processor.run()
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user.\n")
        sys.exit(0)
