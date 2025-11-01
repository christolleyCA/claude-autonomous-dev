#!/usr/bin/env python3
"""
Process charity CSV file and update/insert into database

Reads CSV with charity data, checks against existing database:
- Updates existing nonprofits that are missing websites
- Inserts new nonprofits with websites
"""

import os
import sys
import csv
import json
import requests
import re
from datetime import datetime
from collections import defaultdict

# Configuration
SUPABASE_URL = "https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

CSV_FILE = os.path.expanduser("~/Downloads/charities_domains_cleaned.csv")
BATCH_SIZE = 1000

class CharityCSVProcessor:
    def __init__(self):
        self.total_rows = 0
        self.total_with_websites = 0
        self.total_without_websites = 0
        self.existing_eins = set()
        self.to_update = []
        self.to_insert = []

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

        # Remove trailing slashes and paths for now (keep just domain)
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

        # Remove dashes and ensure it's a string
        ein_str = str(ein).replace('-', '').strip()

        # Pad with leading zeros if needed
        if ein_str.isdigit() and len(ein_str) <= 9:
            return ein_str.zfill(9)

        return None

    def fetch_existing_eins(self):
        """Fetch all EINs currently in database"""
        print("\n📊 Fetching existing EINs from database...")

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
                    'select': 'ein_charity_number,website',
                    'limit': limit,
                    'offset': offset
                },
                timeout=30
            )

            if response.status_code != 200:
                print(f"   ⚠️  Error fetching EINs: {response.status_code}")
                break

            data = response.json()

            if not data:
                break

            for row in data:
                ein = row.get('ein_charity_number')
                website = row.get('website', '').strip()

                if ein:
                    # Track EIN and whether it has a website
                    self.existing_eins.add((ein, bool(website)))

            print(f"   Fetched {len(self.existing_eins):,} EINs so far...")

            offset += limit

            if len(data) < limit:
                break

        print(f"   ✅ Found {len(self.existing_eins):,} existing nonprofits in database\n")

    def process_csv(self):
        """Read and process CSV file"""
        print("=" * 80)
        print("  CHARITY CSV PROCESSOR")
        print("=" * 80)
        print(f"\n📂 Reading CSV: {CSV_FILE}\n")

        with open(CSV_FILE, 'r', encoding='utf-8', errors='ignore') as f:
            reader = csv.DictReader(f)

            for row_num, row in enumerate(reader, 1):
                try:
                    # Extract fields
                    ein = self.normalize_ein(row.get('FILEREIN', ''))
                    name = row.get('FILERNAME1', '').strip()
                    website_raw = row.get('WEBSITSITEIT', '').strip()
                    website = self.normalize_website(website_raw)

                    # Skip if no EIN or name
                    if not ein or not name:
                        continue

                    self.total_rows += 1

                    # Track stats
                    if website:
                        self.total_with_websites += 1
                    else:
                        self.total_without_websites += 1
                        continue  # Skip records without websites

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
                            'zip': str(row.get('FILERUSZIP', '')).split('.')[0],  # Remove .0
                            'phone': ''
                        }),
                        'annual_revenue': int(float(row.get('TOTREVCURYEA', 0) or 0)),
                        'tax_status': '501(c)(3)',
                        'organization_type': 'Public Charity',
                        'is_foundation': False,
                        'created_at': datetime.utcnow().isoformat(),
                        'updated_at': datetime.utcnow().isoformat()
                    }

                    # Check if EIN exists in database
                    ein_exists_with_website = any(e[0] == ein and e[1] for e in self.existing_eins)
                    ein_exists_without_website = any(e[0] == ein and not e[1] for e in self.existing_eins)

                    if ein_exists_without_website:
                        # Existing nonprofit without website - UPDATE
                        self.to_update.append(nonprofit_data)
                    elif not ein_exists_with_website and not ein_exists_without_website:
                        # New nonprofit - INSERT
                        self.to_insert.append(nonprofit_data)
                    # else: exists with website already - skip

                    # Progress update
                    if row_num % 10000 == 0:
                        print(f"   {row_num:,} rows processed... ({self.total_with_websites:,} with websites, {len(self.to_update):,} to update, {len(self.to_insert):,} to insert)")

                except Exception as e:
                    # Skip problematic rows
                    continue

        print(f"\n   ✅ CSV processing complete!")
        print(f"   Total rows: {self.total_rows:,}")
        print(f"   With websites: {self.total_with_websites:,}")
        print(f"   Without websites: {self.total_without_websites:,}")
        print(f"   To update (existing EINs): {len(self.to_update):,}")
        print(f"   To insert (new EINs): {len(self.to_insert):,}\n")

    def update_batch(self, batch):
        """Update existing nonprofits with websites"""
        for nonprofit in batch:
            ein = nonprofit['ein_charity_number']

            # Update by EIN
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
                    'website': nonprofit['website'],
                    'updated_at': nonprofit['updated_at']
                },
                timeout=30
            )

            if response.status_code not in [200, 204]:
                print(f"      ⚠️  Update failed for EIN {ein}: {response.status_code}")

    def insert_batch(self, batch):
        """Insert new nonprofits"""
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

        if response.status_code not in [200, 201]:
            print(f"      ⚠️  Insert batch failed: {response.status_code}")

    def apply_updates(self):
        """Apply all updates to database"""
        if not self.to_update:
            print("\n   No updates needed.")
            return

        print(f"\n📤 Updating {len(self.to_update):,} existing nonprofits with websites...")

        for i in range(0, len(self.to_update), BATCH_SIZE):
            batch = self.to_update[i:i + BATCH_SIZE]
            self.update_batch(batch)
            print(f"   Updated batch {i//BATCH_SIZE + 1} ({len(batch)} records)")

        print(f"   ✅ Updates complete!")

    def apply_inserts(self):
        """Apply all inserts to database"""
        if not self.to_insert:
            print("\n   No inserts needed.")
            return

        print(f"\n📤 Inserting {len(self.to_insert):,} new nonprofits...")

        for i in range(0, len(self.to_insert), BATCH_SIZE):
            batch = self.to_insert[i:i + BATCH_SIZE]
            self.insert_batch(batch)
            print(f"   Inserted batch {i//BATCH_SIZE + 1} ({len(batch)} records)")

        print(f"   ✅ Inserts complete!")

    def run(self):
        """Main execution"""
        try:
            # Step 1: Fetch existing EINs
            self.fetch_existing_eins()

            # Step 2: Process CSV
            self.process_csv()

            # Step 3: Apply updates
            self.apply_updates()

            # Step 4: Apply inserts
            self.apply_inserts()

            print("\n" + "=" * 80)
            print("  ✅ PROCESSING COMPLETE!")
            print("=" * 80)
            print(f"\n📊 Summary:")
            print(f"   Total CSV rows processed: {self.total_rows:,}")
            print(f"   Existing nonprofits updated: {len(self.to_update):,}")
            print(f"   New nonprofits inserted: {len(self.to_insert):,}")
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
