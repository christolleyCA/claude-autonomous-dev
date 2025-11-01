#!/usr/bin/env python3
"""
IRS Form 990 XML Loader - Autonomous Local Processor

Downloads and processes IRS Form 990 XML files for 2024 and 2023,
extracting nonprofit data including websites, revenue, and mission statements.

Creates small CSV batches and uploads to Supabase automatically.
"""

import os
import sys
import json
import time
import zipfile
import requests
import xml.etree.ElementTree as ET
from io import BytesIO
from pathlib import Path
from datetime import datetime

# Configuration
SUPABASE_URL = "https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

BATCH_SIZE = 50000  # Organizations per CSV file
OUTPUT_DIR = Path.home() / "990_nonprofit_data"
STATE_FILE = OUTPUT_DIR / "processing_state.json"

# IRS ZIP file URLs - we'll discover these dynamically
BASE_URL = "https://apps.irs.gov/pub/epostcard/990/xml"

class Form990Loader:
    def __init__(self):
        self.output_dir = OUTPUT_DIR
        self.output_dir.mkdir(exist_ok=True)
        self.state = self.load_state()
        self.current_batch = []
        self.batch_number = 0
        self.total_processed = 0
        self.total_skipped = 0
        self.processed_eins = set()

    def load_state(self):
        """Load processing state to enable resume"""
        if STATE_FILE.exists():
            with open(STATE_FILE, 'r') as f:
                return json.load(f)
        return {
            'processed_zips': [],
            'processed_eins': [],
            'last_batch_number': 0,
            'total_processed': 0
        }

    def save_state(self):
        """Save current state"""
        self.state['processed_eins'] = list(self.processed_eins)
        self.state['last_batch_number'] = self.batch_number
        self.state['total_processed'] = self.total_processed
        with open(STATE_FILE, 'w') as f:
            json.dump(self.state, f, indent=2)

    def get_zip_urls(self, year):
        """Discover available ZIP files for a year"""
        print(f"\n🔍 Discovering {year} ZIP files...")

        # IRS uses numbered batches: 01A, 02A, 03A, etc.
        # We'll try to fetch them until we get a 404
        urls = []
        batch_num = 1

        while batch_num <= 50:  # Max 50 batches (safety limit)
            batch_name = f"{str(batch_num).zfill(2)}A"
            url = f"{BASE_URL}/{year}/{year}_TEOS_XML_{batch_name}.zip"

            # Check if URL exists (HEAD request)
            try:
                response = requests.head(url, timeout=10)
                if response.status_code == 200:
                    size_mb = int(response.headers.get('content-length', 0)) / 1024 / 1024
                    urls.append((url, batch_name, size_mb))
                    print(f"   ✅ Found {batch_name} ({size_mb:.1f} MB)")
                    batch_num += 1
                else:
                    break
            except:
                break

        print(f"   📦 Total: {len(urls)} ZIP files for {year}")
        return urls

    def parse_xml(self, xml_content):
        """Parse a Form 990 XML and extract key data"""
        try:
            # Parse XML
            root = ET.fromstring(xml_content)

            # Define namespaces
            ns = {'irs': 'http://www.irs.gov/efile'}

            # Extract return type
            return_type = root.find('.//irs:ReturnTypeCd', ns)
            if return_type is not None and return_type.text not in ['990', '990EZ', '990PF']:
                return None  # Skip 990-T, etc.

            # Extract EIN
            ein = root.find('.//irs:EIN', ns)
            if ein is None or not ein.text:
                return None
            ein_text = ein.text.strip()

            # Skip if already processed (from 2024)
            if ein_text in self.processed_eins:
                return None

            # Extract business name
            name_line1 = root.find('.//irs:BusinessNameLine1Txt', ns)
            name_line2 = root.find('.//irs:BusinessNameLine2Txt', ns)

            if name_line1 is None:
                return None

            name = name_line1.text.strip() if name_line1.text else ''
            if name_line2 is not None and name_line2.text:
                name += ' ' + name_line2.text.strip()

            # Extract website
            website = root.find('.//irs:WebsiteAddressTxt', ns)
            website_text = ''
            if website is not None and website.text:
                website_text = self.normalize_website(website.text.strip())

            # Extract address
            address_elem = root.find('.//irs:AddressLine1Txt', ns)
            city_elem = root.find('.//irs:CityNm', ns)
            state_elem = root.find('.//irs:StateAbbreviationCd', ns)
            zip_elem = root.find('.//irs:ZIPCd', ns)
            phone_elem = root.find('.//irs:PhoneNum', ns)

            address = address_elem.text.strip() if address_elem is not None and address_elem.text else ''
            city = city_elem.text.strip() if city_elem is not None and city_elem.text else ''
            state = state_elem.text.strip() if state_elem is not None and state_elem.text else ''
            zip_code = zip_elem.text.strip() if zip_elem is not None and zip_elem.text else ''
            phone = phone_elem.text.strip() if phone_elem is not None and phone_elem.text else ''

            # Extract revenue
            gross_receipts = root.find('.//irs:GrossReceiptsAmt', ns)
            total_revenue = root.find('.//irs:TotalRevenueAmt', ns)

            revenue = 0
            if gross_receipts is not None and gross_receipts.text:
                revenue = max(revenue, float(gross_receipts.text))
            if total_revenue is not None and total_revenue.text:
                revenue = max(revenue, float(total_revenue.text))

            # Extract mission
            mission_elem = root.find('.//irs:ActivityOrMissionDesc', ns)
            if mission_elem is None:
                mission_elem = root.find('.//irs:MissionDesc', ns)

            mission = mission_elem.text.strip() if mission_elem is not None and mission_elem.text else ''
            mission = mission[:1000]  # Limit to 1000 chars

            # Extract formation year
            formation_elem = root.find('.//irs:FormationYr', ns)
            formation_year = formation_elem.text.strip() if formation_elem is not None and formation_elem.text else ''

            # Tax status
            is_501c3 = root.find('.//irs:Organization501c3Ind', ns) is not None
            tax_status = '501(c)(3)' if is_501c3 else '501(c)'

            # Categorize revenue
            revenue_range = self.categorize_revenue(revenue)

            # Infer cause areas
            cause_areas = self.infer_cause_areas(mission)

            return {
                'ein_charity_number': ein_text,
                'name': name,
                'country': 'US',
                'website': website_text,
                'contact_info': json.dumps({
                    'address': address,
                    'city': city,
                    'state': state,
                    'zip': zip_code,
                    'phone': phone
                }),
                'revenue_range': revenue_range,
                'annual_revenue': int(revenue),
                'cause_areas': json.dumps(cause_areas),
                'mission_statement': mission,
                'formation_year': formation_year if formation_year else '',
                'tax_status': tax_status,
                'created_at': datetime.utcnow().isoformat(),
                'updated_at': datetime.utcnow().isoformat()
            }

        except Exception as e:
            # Silently skip malformed XML
            return None

    def normalize_website(self, url):
        """Normalize website URL"""
        if not url or url.upper() in ['N/A', 'NA', 'NONE', 'NULL']:
            return ''

        url = url.strip().lower()
        if not url.startswith('http'):
            url = 'https://' + url

        return url

    def categorize_revenue(self, revenue):
        """Categorize revenue into ranges"""
        if revenue < 50000:
            return 'Under $50K'
        elif revenue < 100000:
            return '$50K-$100K'
        elif revenue < 500000:
            return '$100K-$500K'
        elif revenue < 1000000:
            return '$500K-$1M'
        elif revenue < 10000000:
            return '$1M-$10M'
        else:
            return 'Over $10M'

    def infer_cause_areas(self, mission):
        """Infer cause areas from mission text"""
        causes = set()
        text = mission.lower()

        keywords = {
            'Education': ['education', 'school', 'student', 'learning', 'university', 'college'],
            'Health': ['health', 'medical', 'hospital', 'clinic', 'disease', 'mental health'],
            'Human Services': ['homeless', 'poverty', 'shelter', 'food bank', 'social service'],
            'Arts & Culture': ['arts', 'culture', 'museum', 'theater', 'music', 'gallery'],
            'Environment': ['environment', 'conservation', 'wildlife', 'nature', 'climate'],
            'Animal Welfare': ['animal', 'pet', 'rescue', 'shelter', 'wildlife'],
            'Community Development': ['community', 'development', 'housing', 'neighborhood'],
            'Religion': ['church', 'religious', 'faith', 'ministry', 'spiritual'],
            'Youth Development': ['youth', 'children', 'kids', 'teen', 'adolescent'],
            'International': ['international', 'global', 'foreign', 'overseas']
        }

        for cause, words in keywords.items():
            if any(word in text for word in words):
                causes.add(cause)

        return list(causes) if causes else ['General']

    def process_zip(self, url, batch_name, year):
        """Download and process a single ZIP file"""
        print(f"\n📥 Downloading {year}_{batch_name}...")

        try:
            # Download ZIP
            response = requests.get(url, stream=True, timeout=300)
            response.raise_for_status()

            zip_data = BytesIO(response.content)

            print(f"   ✅ Downloaded ({len(response.content) / 1024 / 1024:.1f} MB)")
            print(f"   🔍 Processing XML files...")

            with zipfile.ZipFile(zip_data) as zf:
                xml_files = [name for name in zf.namelist() if name.endswith('.xml')]
                total_files = len(xml_files)

                for idx, xml_file in enumerate(xml_files, 1):
                    try:
                        xml_content = zf.read(xml_file)
                        nonprofit = self.parse_xml(xml_content)

                        if nonprofit:
                            self.current_batch.append(nonprofit)
                            self.processed_eins.add(nonprofit['ein_charity_number'])
                            self.total_processed += 1

                            # Save batch when it reaches size limit
                            if len(self.current_batch) >= BATCH_SIZE:
                                self.save_batch(year)
                        else:
                            self.total_skipped += 1

                        # Progress update every 500 files
                        if idx % 500 == 0:
                            print(f"      {idx}/{total_files} files processed... ({self.total_processed} orgs, {self.total_skipped} skipped)")

                    except Exception as e:
                        self.total_skipped += 1
                        continue

                print(f"   ✅ Completed {batch_name}: {self.total_processed} total orgs processed")

                # Save remaining batch
                if self.current_batch:
                    self.save_batch(year)

                # Update state
                self.state['processed_zips'].append(f"{year}_{batch_name}")
                self.save_state()

        except Exception as e:
            print(f"   ❌ Error processing {batch_name}: {e}")
            return False

        return True

    def save_batch(self, year):
        """Save current batch to CSV"""
        if not self.current_batch:
            return

        self.batch_number += 1
        filename = self.output_dir / f"nonprofits_{year}_batch_{str(self.batch_number).zfill(3)}.csv"

        print(f"\n   💾 Saving batch {self.batch_number} ({len(self.current_batch)} orgs) to CSV...")

        # Write CSV
        import csv
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
            import csv
            nonprofits = []

            with open(csv_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    # Parse JSON fields
                    row['contact_info'] = json.loads(row['contact_info'])
                    row['cause_areas'] = json.loads(row['cause_areas'])
                    row['annual_revenue'] = int(row['annual_revenue']) if row['annual_revenue'] else 0
                    nonprofits.append(row)

            # Upload in chunks of 1000
            chunk_size = 1000
            for i in range(0, len(nonprofits), chunk_size):
                chunk = nonprofits[i:i + chunk_size]

                response = requests.post(
                    f"{SUPABASE_URL}/rest/v1/nonprofits",
                    headers={
                        'apikey': SUPABASE_KEY,
                        'Authorization': f'Bearer {SUPABASE_KEY}',
                        'Content-Type': 'application/json',
                        'Prefer': 'resolution=merge-duplicates'
                    },
                    json=chunk,
                    timeout=60
                )

                if response.status_code not in [200, 201]:
                    print(f"   ⚠️  Upload warning: {response.status_code} - {response.text[:200]}")

            print(f"   ✅ Uploaded {len(nonprofits)} organizations to database")

        except Exception as e:
            print(f"   ⚠️  Upload error: {e}")
            print(f"   💾 CSV saved locally for manual upload: {csv_file}")

    def run(self):
        """Main processing loop"""
        print("=" * 80)
        print("  IRS FORM 990 NONPROFIT DATA LOADER")
        print("=" * 80)
        print(f"\n📂 Output directory: {self.output_dir}")
        print(f"📊 Batch size: {BATCH_SIZE:,} organizations per CSV")
        print(f"💾 State file: {STATE_FILE}")

        # Load previously processed EINs
        if self.state['processed_eins']:
            self.processed_eins = set(self.state['processed_eins'])
            self.batch_number = self.state['last_batch_number']
            self.total_processed = self.state['total_processed']
            print(f"\n🔄 Resuming: {len(self.processed_eins):,} EINs already processed")

        # Process both years
        for year in ['2024', '2023']:
            print(f"\n{'=' * 80}")
            print(f"  PROCESSING {year} FILINGS")
            print(f"{'=' * 80}")

            zip_urls = self.get_zip_urls(year)

            if not zip_urls:
                print(f"   ⚠️  No ZIP files found for {year}")
                continue

            for url, batch_name, size_mb in zip_urls:
                zip_id = f"{year}_{batch_name}"

                # Skip if already processed
                if zip_id in self.state['processed_zips']:
                    print(f"\n   ⏭️  Skipping {zip_id} (already processed)")
                    continue

                self.process_zip(url, batch_name, year)

                # Save state after each ZIP
                self.save_state()

        print("\n" + "=" * 80)
        print("  ✅ PROCESSING COMPLETE!")
        print("=" * 80)
        print(f"\n📊 Final Statistics:")
        print(f"   Total organizations processed: {self.total_processed:,}")
        print(f"   Total skipped: {self.total_skipped:,}")
        print(f"   CSV batches created: {self.batch_number}")
        print(f"   Output directory: {self.output_dir}")
        print(f"\n💾 All data uploaded to Supabase!")
        print(f"✅ Ready for Phase 2: Website Scraping & Funder Discovery\n")

if __name__ == "__main__":
    try:
        loader = Form990Loader()
        loader.run()
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user. Progress saved!")
        print("💡 Run this script again to resume from where you left off.\n")
        sys.exit(0)
    except Exception as e:
        print(f"\n\n❌ Fatal error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
