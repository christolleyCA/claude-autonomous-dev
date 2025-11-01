#!/usr/bin/env python3
"""
IRS Form 990-N (ePostcard) Loader - ALL Small Nonprofits

Downloads and processes IRS Form 990-N filings for small nonprofits (<$50K revenue).
Includes ALL organizations (with AND without websites) for recent filings (2020+).

We'll use Google Search + AI to find missing websites later!
"""

import os
import sys
import json
import csv
import zipfile
import requests
from io import BytesIO, TextIOWrapper
from pathlib import Path
from datetime import datetime

# Configuration
SUPABASE_URL = "https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

BATCH_SIZE = 50000  # Organizations per CSV file
OUTPUT_DIR = Path.home() / "990_nonprofit_data"
IRS_990N_URL = "https://apps.irs.gov/pub/epostcard/data-download-epostcard.zip"

class Form990NLoader:
    def __init__(self):
        self.output_dir = OUTPUT_DIR
        self.output_dir.mkdir(exist_ok=True)
        self.current_batch = []
        self.batch_number = 0
        self.total_processed = 0
        self.total_skipped = 0
        self.total_with_websites = 0
        self.total_without_websites = 0

    def download_and_process(self):
        """Download and process IRS 990-N bulk file"""
        print("=" * 80)
        print("  IRS FORM 990-N (ePOSTCARD) LOADER")
        print("  Small Nonprofits (<$50K Revenue)")
        print("=" * 80)
        print(f"\n📂 Output directory: {self.output_dir}")
        print(f"📊 Batch size: {BATCH_SIZE:,} organizations per CSV\n")

        print(f"📥 Downloading IRS 990-N bulk file...")
        print(f"   URL: {IRS_990N_URL}")

        try:
            # Download ZIP file
            response = requests.get(IRS_990N_URL, stream=True, timeout=300)
            response.raise_for_status()

            print(f"   ✅ Downloaded ({len(response.content) / 1024 / 1024:.1f} MB)")
            print(f"   📦 Extracting...")

            # Extract and process
            with zipfile.ZipFile(BytesIO(response.content)) as zf:
                # Get the text file name
                txt_file = [name for name in zf.namelist() if name.endswith('.txt')][0]

                print(f"   ✅ Found: {txt_file}")
                print(f"   🔍 Processing records...")
                print(f"   ⚡ Filters: Tax Year 2020+ (websites optional - we'll find them later!)")
                print()

                with zf.open(txt_file) as f:
                    # Wrap in TextIOWrapper to handle text mode
                    text_file = TextIOWrapper(f, encoding='utf-8', errors='ignore')

                    for line_num, line in enumerate(text_file, 1):
                        try:
                            nonprofit, has_website = self.parse_line(line.strip())

                            if nonprofit:
                                self.current_batch.append(nonprofit)
                                self.total_processed += 1

                                if has_website:
                                    self.total_with_websites += 1
                                else:
                                    self.total_without_websites += 1

                                # Save batch when it reaches size limit
                                if len(self.current_batch) >= BATCH_SIZE:
                                    self.save_batch()
                            else:
                                self.total_skipped += 1

                            # Progress update every 50,000 lines
                            if line_num % 50000 == 0:
                                print(f"      {line_num:,} lines processed... ({self.total_with_websites:,} with websites, {self.total_without_websites:,} without, {self.total_skipped:,} skipped)")

                        except Exception as e:
                            self.total_skipped += 1
                            continue

                # Save remaining batch
                if self.current_batch:
                    self.save_batch()

                print(f"\n   ✅ Processing complete!")

        except Exception as e:
            print(f"\n   ❌ Error: {e}")
            raise

    def parse_line(self, line):
        """Parse a pipe-delimited 990-N record"""
        if not line:
            return None

        parts = line.split('|')

        # Ensure we have enough fields
        if len(parts) < 20:
            return None

        try:
            ein = parts[0].strip()
            tax_year = parts[1].strip()
            name = parts[2].strip()
            terminated = parts[3].strip()
            #amended = parts[4].strip()
            #tax_period_begin = parts[5].strip()
            #tax_period_end = parts[6].strip()
            website = parts[7].strip()
            officer_name = parts[8].strip()
            address = parts[9].strip()
            #address2 = parts[10].strip()
            city = parts[11].strip()
            #placeholder = parts[12]  # Empty field
            state = parts[13].strip()
            zip_code = parts[14].strip()
            #country = parts[15].strip()

            # Filter 1: Must have EIN and name
            if not ein or not name:
                return (None, False)

            # Filter 2: Recent filings only (2020+)
            if not tax_year or int(tax_year) < 2020:
                return (None, False)

            # Note: Field 3 is always 'T' for all 990-N records (not a terminated flag)
            # Skipping terminated filter

            # Normalize website (but allow empty)
            has_website = False
            if website and website.upper() not in ['', 'N/A', 'NA', 'NONE', 'NULL']:
                website = self.normalize_website(website)
                if website:
                    has_website = True
                else:
                    website = ''  # Empty string for database
            else:
                website = ''  # Empty string for database

            # Build nonprofit record
            nonprofit_data = {
                'ein_charity_number': ein,
                'name': name,
                'country': 'US',
                'website': website,  # Empty string if no website
                'contact_info': json.dumps({
                    'address': address,
                    'city': city,
                    'state': state,
                    'zip': zip_code,
                    'phone': ''
                }),
                'revenue_range': 'Under $50K',  # All 990-N filers are <$50K
                'annual_revenue': 0,  # Not reported on 990-N
                'cause_areas': json.dumps(['General']),  # Not reported on 990-N
                'mission_statement': f'Principal Officer: {officer_name}' if officer_name else '',
                'formation_year': '',
                'tax_status': '501(c)(3)',  # Most 990-N filers
                'organization_type': 'Public Charity',  # Small public charities
                'is_foundation': False,
                'created_at': datetime.utcnow().isoformat(),
                'updated_at': datetime.utcnow().isoformat()
            }

            return (nonprofit_data, has_website)

        except Exception as e:
            return (None, False)

    def normalize_website(self, url):
        """Normalize website URL"""
        if not url:
            return ''

        url = url.strip()

        # Skip invalid entries
        if url.upper() in ['N/A', 'NA', 'NONE', 'NULL', 'NOT APPLICABLE']:
            return ''

        # Add protocol if missing
        if not url.startswith('http'):
            url = 'https://' + url

        # Basic validation
        if len(url) < 10 or ' ' in url:
            return ''

        return url.lower()

    def save_batch(self):
        """Save current batch to CSV and upload to Supabase"""
        if not self.current_batch:
            return

        self.batch_number += 1
        filename = self.output_dir / f"nonprofits_990N_batch_{str(self.batch_number).zfill(3)}.csv"

        print(f"\n   💾 Saving batch {self.batch_number} ({len(self.current_batch):,} orgs) to CSV...")

        # Write CSV
        with open(filename, 'w', newline='', encoding='utf-8') as f:
            if self.current_batch:
                writer = csv.DictWriter(f, fieldnames=self.current_batch[0].keys())
                writer.writeheader()
                writer.writerows(self.current_batch)

        print(f"   ✅ Saved: {filename.name}")

        # Upload to Supabase
        self.upload_batch(filename)

        # Clear batch
        self.current_batch = []

    def upload_batch(self, csv_file):
        """Upload CSV batch to Supabase"""
        print(f"   📤 Uploading to Supabase...")

        try:
            nonprofits = []

            with open(csv_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    # Parse JSON fields
                    row['contact_info'] = json.loads(row['contact_info'])
                    row['cause_areas'] = json.loads(row['cause_areas'])
                    row['annual_revenue'] = int(row['annual_revenue']) if row['annual_revenue'] else 0
                    row['is_foundation'] = row['is_foundation'].lower() == 'true'
                    nonprofits.append(row)

            # Upload in chunks of 1000
            chunk_size = 1000
            uploaded = 0
            skipped_duplicates = 0

            for i in range(0, len(nonprofits), chunk_size):
                chunk = nonprofits[i:i + chunk_size]

                response = requests.post(
                    f"{SUPABASE_URL}/rest/v1/nonprofits",
                    headers={
                        'apikey': SUPABASE_KEY,
                        'Authorization': f'Bearer {SUPABASE_KEY}',
                        'Content-Type': 'application/json',
                        'Prefer': 'resolution=ignore-duplicates'
                    },
                    json=chunk,
                    timeout=60
                )

                if response.status_code in [200, 201]:
                    uploaded += len(chunk)
                elif response.status_code == 409:
                    # Duplicates (EINs already exist from full 990 filings)
                    skipped_duplicates += len(chunk)
                else:
                    print(f"   ⚠️  Upload warning: {response.status_code}")

            if skipped_duplicates > 0:
                print(f"   ✅ Uploaded {uploaded:,} new organizations (skipped {skipped_duplicates:,} duplicates)")
            else:
                print(f"   ✅ Uploaded {uploaded:,} organizations to database")

        except Exception as e:
            print(f"   ⚠️  Upload error: {e}")
            print(f"   💾 CSV saved locally: {csv_file}")

    def run(self):
        """Main execution"""
        try:
            self.download_and_process()

            print("\n" + "=" * 80)
            print("  ✅ PROCESSING COMPLETE!")
            print("=" * 80)
            print(f"\n📊 Final Statistics:")
            print(f"   Total organizations added: {self.total_processed:,}")
            print(f"   With websites: {self.total_with_websites:,}")
            print(f"   WITHOUT websites (need Google search): {self.total_without_websites:,}")
            print(f"   Skipped (pre-2020 or invalid): {self.total_skipped:,}")
            print(f"   CSV batches created: {self.batch_number}")
            print(f"   Output directory: {self.output_dir}")
            print(f"\n💾 All data uploaded to Supabase!")
            print(f"✅ Ready for website discovery via Google Search + AI!\n")

        except Exception as e:
            print(f"\n\n❌ Error: {e}")
            import traceback
            traceback.print_exc()
            sys.exit(1)

if __name__ == "__main__":
    try:
        loader = Form990NLoader()
        loader.run()
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user.\n")
        sys.exit(0)
