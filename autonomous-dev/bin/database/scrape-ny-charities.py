#!/usr/bin/env python3
"""
New York State Charities Registry Scraper

Scrapes charity information from NY State Attorney General's Charities Bureau:
https://www.charitiesnys.com/RegistrySearch/

Extracts: Name, EIN, Website, Address from charity detail pages

Strategy: Search by EIN prefix (00- through 99-) to bypass 100-result limit
Each search returns up to 100 charities across 7 pages (15 per page)
"""

import os
import sys
import json
import csv
import requests
import time
import re
from pathlib import Path
from datetime import datetime
from bs4 import BeautifulSoup

# Configuration
SUPABASE_URL = "https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

OUTPUT_DIR = Path.home() / "990_nonprofit_data"
BATCH_SIZE = 500
BASE_URL = "https://www.charitiesnys.com/RegistrySearch"

class NYCharityRegistryScraper:
    def __init__(self):
        self.output_dir = OUTPUT_DIR
        self.output_dir.mkdir(exist_ok=True)
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        })
        self.charities = []
        self.total_processed = 0
        self.total_with_websites = 0
        self.total_searches = 0

    def search_by_ein_prefix(self, ein_prefix):
        """Search for charities by EIN prefix (e.g., '00-', '15-', '99-')"""
        charity_ids = []

        print(f"\n🔍 Searching EIN prefix: {ein_prefix}")

        # Page 1 to get total count
        search_url = f"{BASE_URL}/search_charities_action.jsp"
        params = {
            'orgName': '',
            'd-49653-p': '1',
            'city': '',
            'searchType': 'begins',
            'reg1': '',
            'project': 'Charities',
            'reg3': '',
            'reg2': '',
            'ein': ein_prefix,
            'orgId': '',
            'num1': '0',
            'state': 'none',
            'regType': 'ALL',
            'num2': ''
        }

        try:
            response = self.session.get(search_url, params=params, timeout=30)
            response.raise_for_status()
            soup = BeautifulSoup(response.text, 'html.parser')

            # Extract total count
            count_text = soup.find(text=re.compile(r'\d+ items? found'))
            if count_text:
                total_items = int(re.search(r'(\d+) items? found', count_text).group(1))
                total_pages = min(7, (total_items + 14) // 15)  # 15 per page, max 7 pages
                print(f"   Found {total_items} charities ({total_pages} pages)")
            else:
                print(f"   No results found")
                return []

            # Extract charity IDs from all pages
            for page_num in range(1, total_pages + 1):
                if page_num > 1:
                    params['d-49653-p'] = str(page_num)
                    response = self.session.get(search_url, params=params, timeout=30)
                    response.raise_for_status()
                    soup = BeautifulSoup(response.text, 'html.parser')

                # Find all charity links: onClick="location.href='show_details.jsp?id={GUID}';"
                onclick_labels = soup.find_all('label', {'onclick': re.compile(r"show_details\.jsp\?id=")})

                for label in onclick_labels:
                    onclick = label.get('onclick', '')
                    id_match = re.search(r"id=\{([^}]+)\}", onclick)
                    if id_match:
                        charity_id = id_match.group(1)
                        charity_ids.append(charity_id)

                # Rate limiting
                if page_num < total_pages:
                    time.sleep(1)

            print(f"   ✅ Extracted {len(charity_ids)} charity IDs")
            return charity_ids

        except Exception as e:
            print(f"   ❌ Error searching {ein_prefix}: {e}")
            return []

    def scrape_charity_detail(self, charity_id):
        """Extract charity details from detail page"""
        try:
            # ID needs curly braces
            detail_url = f"{BASE_URL}/show_details.jsp?id={{{charity_id}}}"
            response = self.session.get(detail_url, timeout=15)
            response.raise_for_status()

            soup = BeautifulSoup(response.text, 'html.parser')

            # Extract organization name (in title or header)
            name = None
            title = soup.find('title')
            if title:
                # Title format: "Organization Name - NY Charities Bureau"
                name = title.text.split(' - ')[0].strip()

            if not name:
                # Try to find in page header
                header = soup.find('h2') or soup.find('h1')
                if header:
                    name = header.text.strip()

            # Extract website
            website = None
            # Look for label containing website or URL
            website_patterns = [
                re.compile(r'WWW\.[A-Z0-9\-\.]+\.[A-Z]{2,}', re.IGNORECASE),
                re.compile(r'HTTPS?://[A-Z0-9\-\.]+\.[A-Z]{2,}', re.IGNORECASE)
            ]

            page_text = soup.get_text()
            for pattern in website_patterns:
                match = pattern.search(page_text)
                if match:
                    website = match.group(0)
                    break

            # Extract EIN (Federal ID)
            ein = None
            ein_match = re.search(r'Federal ID[:\s]+(\d{9})', page_text)
            if ein_match:
                ein = ein_match.group(1)

            # Extract address
            address_match = re.search(r'(\d+[^\n]+?(?:AVENUE|AVE|STREET|ST|ROAD|RD|DRIVE|DR|BOULEVARD|BLVD)[^\n]*?NY\s+\d{5})', page_text, re.IGNORECASE)
            address = address_match.group(1).strip() if address_match else ''

            if not website:
                return None

            # Build charity record
            charity_data = {
                'ein_charity_number': ein if ein else '',
                'name': name if name else 'Unknown',
                'country': 'US',
                'website': self.normalize_website(website),
                'contact_info': json.dumps({
                    'address': address,
                    'state': 'NY'
                }),
                'tax_status': '501(c)(3)',
                'organization_type': 'Public Charity',
                'is_foundation': False,
                'created_at': datetime.utcnow().isoformat(),
                'updated_at': datetime.utcnow().isoformat()
            }

            return charity_data

        except Exception as e:
            return None

    def normalize_website(self, url):
        """Normalize website URL"""
        if not url:
            return ''

        url = url.strip()

        # Remove common prefixes
        url = re.sub(r'^WWW\.', '', url, flags=re.IGNORECASE)
        url = re.sub(r'^HTTP[S]?://', '', url, flags=re.IGNORECASE)

        # Add protocol
        if not url.startswith('http'):
            url = 'https://' + url

        # Basic validation
        if len(url) < 10 or ' ' in url:
            return ''

        return url.lower()

    def save_batch(self):
        """Save and upload batch"""
        if not self.charities:
            return

        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = self.output_dir / f"ny_charities_batch_{timestamp}.csv"

        print(f"\n   💾 Saving batch ({len(self.charities)} charities)...")

        with open(filename, 'w', newline='', encoding='utf-8') as f:
            if self.charities:
                writer = csv.DictWriter(f, fieldnames=self.charities[0].keys())
                writer.writeheader()
                writer.writerows(self.charities)

        print(f"   ✅ Saved: {filename.name}")

        # Upload to Supabase
        self.upload_batch(self.charities)

        # Clear batch
        self.charities = []

    def upload_batch(self, charities):
        """Upload batch to Supabase with smart upserts"""
        print(f"   📤 Uploading to Supabase...")

        try:
            with_ein = [c for c in charities if c.get('ein_charity_number')]
            without_ein = [c for c in charities if not c.get('ein_charity_number')]

            # Upsert charities WITH EIN (update existing or insert new)
            if with_ein:
                chunk_size = 100
                for i in range(0, len(with_ein), chunk_size):
                    chunk = with_ein[i:i + chunk_size]

                    response = requests.post(
                        f"{SUPABASE_URL}/rest/v1/nonprofits",
                        headers={
                            'apikey': SUPABASE_KEY,
                            'Authorization': f'Bearer {SUPABASE_KEY}',
                            'Content-Type': 'application/json',
                            'Prefer': 'resolution=merge-duplicates'
                        },
                        json=chunk,
                        timeout=30
                    )

            # Insert charities WITHOUT EIN
            if without_ein:
                chunk_size = 100
                for i in range(0, len(without_ein), chunk_size):
                    chunk = without_ein[i:i + chunk_size]

                    response = requests.post(
                        f"{SUPABASE_URL}/rest/v1/nonprofits",
                        headers={
                            'apikey': SUPABASE_KEY,
                            'Authorization': f'Bearer {SUPABASE_KEY}',
                            'Content-Type': 'application/json',
                            'Prefer': 'resolution=ignore-duplicates'
                        },
                        json=chunk,
                        timeout=30
                    )

            print(f"   ✅ Uploaded {len(charities)} charities ({len(with_ein)} with EIN, {len(without_ein)} without)")

        except Exception as e:
            print(f"   ⚠️  Upload error: {e}")

    def run(self):
        """Main execution"""
        print("=" * 80)
        print("  NEW YORK STATE CHARITIES REGISTRY SCRAPER")
        print("=" * 80)
        print(f"\n📂 Output directory: {self.output_dir}\n")

        try:
            # Search through EIN prefixes
            # Start with single digits (0-9), then double digits (10-99)
            ein_prefixes = [f"{i}-" for i in range(10)]  # 0- through 9-
            ein_prefixes += [f"{i}-" for i in range(10, 100)]  # 10- through 99-

            # DEBUG: Test with first 2 prefixes only
            TEST_MODE = os.environ.get('TEST_MODE', 'true').lower() == 'true'
            if TEST_MODE:
                ein_prefixes = ein_prefixes[:2]  # Only test with 0- and 1-
                print(f"\n⚠️  TEST MODE: Processing only first 2 EIN prefixes: {ein_prefixes}\n")

            total_charity_ids = []

            # Collect all charity IDs first
            for prefix in ein_prefixes:
                charity_ids = self.search_by_ein_prefix(prefix)
                total_charity_ids.extend(charity_ids)
                self.total_searches += 1

                # Rate limiting between searches
                time.sleep(2)

            print(f"\n{'=' * 80}")
            print(f"  PHASE 1 COMPLETE: Found {len(total_charity_ids)} total charities")
            print(f"{'=' * 80}\n")

            # Now scrape each charity's detail page
            print(f"🔍 Extracting charity details...\n")

            for i, charity_id in enumerate(total_charity_ids, 1):
                try:
                    charity_data = self.scrape_charity_detail(charity_id)

                    if charity_data and charity_data.get('website'):
                        self.charities.append(charity_data)
                        self.total_with_websites += 1
                        print(f"   [{i}/{len(total_charity_ids)}] ✅ {charity_data['name'][:60]}")
                    else:
                        print(f"   [{i}/{len(total_charity_ids)}] ⚠️  No website")

                    self.total_processed += 1

                    # Save batch periodically
                    if len(self.charities) >= BATCH_SIZE:
                        self.save_batch()

                    # Rate limiting
                    if i % 10 == 0:
                        time.sleep(1)
                    else:
                        time.sleep(0.5)

                except Exception as e:
                    print(f"   [{i}/{len(total_charity_ids)}] ❌ Error: {str(e)[:50]}")
                    continue

            # Save remaining
            if self.charities:
                self.save_batch()

            print("\n" + "=" * 80)
            print("  ✅ SCRAPING COMPLETE!")
            print("=" * 80)
            print(f"\n📊 Final Statistics:")
            print(f"   Total searches performed: {self.total_searches}")
            print(f"   Total charities found: {len(total_charity_ids)}")
            print(f"   Detail pages processed: {self.total_processed}")
            print(f"   Charities with websites: {self.total_with_websites}")
            print(f"   Success rate: {self.total_with_websites/max(self.total_processed,1)*100:.1f}%")
            print(f"   Output directory: {self.output_dir}")
            print(f"\n✅ NY charities added to database!\n")

        except Exception as e:
            print(f"\n\n❌ Error: {e}")
            import traceback
            traceback.print_exc()
            sys.exit(1)

if __name__ == "__main__":
    try:
        scraper = NYCharityRegistryScraper()
        scraper.run()
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user.\n")
        sys.exit(0)
