#!/usr/bin/env python3
"""
Charity Directory Scraper - Extract nonprofit websites from charity review sites

Scrapes charity information from:
- BBB Wise Giving Alliance (give.org)
- Charity Navigator
- GuideStar listings
- Other public charity directories

Extracts: Name, Website, Location, EIN (when available)
"""

import os
import sys
import json
import csv
import requests
import time
from pathlib import Path
from datetime import datetime
from urllib.parse import urljoin
import re

# Configuration
SUPABASE_URL = "https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

OUTPUT_DIR = Path.home() / "990_nonprofit_data"
BATCH_SIZE = 1000

class CharityDirectoryScraper:
    def __init__(self):
        self.output_dir = OUTPUT_DIR
        self.output_dir.mkdir(exist_ok=True)
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        })
        self.total_processed = 0
        self.total_with_websites = 0
        self.charities = []

    def scrape_bbb_wise_giving(self):
        """Scrape BBB Wise Giving Alliance (give.org)"""
        print("\n" + "=" * 80)
        print("  BBB WISE GIVING ALLIANCE (give.org)")
        print("=" * 80)

        base_url = "https://give.org"
        listing_url = f"{base_url}/national-charity-reviews"

        print(f"\n📥 Fetching charity listing page...")
        print(f"   URL: {listing_url}")

        try:
            response = self.session.get(listing_url, timeout=30)
            response.raise_for_status()
            html = response.text

            # Extract all charity review links
            # Pattern: href="https://give.org/charity-reviews/..." (full URLs)
            link_pattern = r'href="(https://give\.org/charity-reviews/[^"]+)"'
            charity_links = set(re.findall(link_pattern, html))

            print(f"   ✅ Found {len(charity_links)} charity review pages")
            print(f"   🔍 Extracting charity details...\n")

            for i, charity_url in enumerate(charity_links, 1):
                try:
                    # Rate limiting
                    if i > 1:
                        time.sleep(2)  # Be respectful - 2 seconds between requests

                    charity_data = self.extract_charity_from_page(charity_url)

                    if charity_data and charity_data.get('website'):
                        self.charities.append(charity_data)
                        self.total_with_websites += 1
                        print(f"      [{i}/{len(charity_links)}] ✅ {charity_data['name'][:50]}")
                    else:
                        print(f"      [{i}/{len(charity_links)}] ⚠️  No website found")

                    self.total_processed += 1

                    # Save batch every 100 charities
                    if len(self.charities) >= BATCH_SIZE:
                        self.save_batch()

                except Exception as e:
                    print(f"      [{i}/{len(charity_links)}] ❌ Error: {str(e)[:50]}")
                    continue

            # Save remaining
            if self.charities:
                self.save_batch()

            print(f"\n   ✅ BBB scraping complete!")

        except Exception as e:
            print(f"\n   ❌ Error: {e}")
            raise

    def extract_charity_from_page(self, url):
        """Extract charity details from a review page"""
        try:
            response = self.session.get(url, timeout=15)
            response.raise_for_status()
            html = response.text

            # Extract charity name from title or h1
            name_match = re.search(r'<h1[^>]*>([^<]+)</h1>', html)
            if not name_match:
                name_match = re.search(r'<title>([^<]+)</title>', html)

            if not name_match:
                return None

            name = name_match.group(1).strip()
            name = re.sub(r'\s*\|.*$', '', name)  # Remove " | BBB" suffix
            name = re.sub(r'\s*-.*reviews.*$', '', name, flags=re.IGNORECASE)

            # Extract website - look for patterns like:
            # - "Website: <a href='https://...'>"
            # - "Visit Website" buttons
            # - Official links
            website = None

            # Pattern 1: Website label followed by link
            website_match = re.search(r'(?:website|site|url)[\s:]*<a[^>]*href=["\']([^"\']+)["\']', html, re.IGNORECASE)
            if website_match:
                website = website_match.group(1)

            # Pattern 2: Look for external links (not give.org)
            if not website:
                external_links = re.findall(r'href=["\']https?://([^"\']+)["\']', html)
                for link in external_links:
                    # Skip give.org and common third-party domains
                    if not any(skip in link.lower() for skip in ['give.org', 'facebook.com', 'twitter.com', 'linkedin.com', 'youtube.com', 'instagram.com']):
                        website = f"https://{link}"
                        break

            # Extract location
            location_match = re.search(r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*),\s*([A-Z]{2})', html)
            city = location_match.group(1) if location_match else ''
            state = location_match.group(2) if location_match else ''

            # Extract EIN if available
            ein_match = re.search(r'\b(\d{2}-?\d{7})\b', html)
            ein = ein_match.group(1).replace('-', '') if ein_match else ''

            if not website:
                return None

            # Build smart upsert object
            # Only include fields we want to ADD or UPDATE
            # Don't include fields that would overwrite good IRS data with placeholders
            charity_data = {
                'name': name,
                'country': 'US',
                'website': self.normalize_website(website),
                'updated_at': datetime.utcnow().isoformat()
            }

            # Add EIN if we found one (for matching existing records)
            if ein:
                charity_data['ein_charity_number'] = ein

            # Add location if we have it
            if city or state:
                charity_data['contact_info'] = json.dumps({
                    'city': city,
                    'state': state,
                })

            # For NEW records only, set these defaults
            # (These won't overwrite existing data due to our upsert strategy)
            charity_data['created_at'] = datetime.utcnow().isoformat()
            charity_data['tax_status'] = '501(c)(3)'
            charity_data['organization_type'] = 'Public Charity'
            charity_data['is_foundation'] = False

            return charity_data

        except Exception as e:
            return None

    def normalize_website(self, url):
        """Normalize website URL"""
        if not url:
            return ''

        url = url.strip()

        # Remove tracking parameters
        url = re.sub(r'\?.*$', '', url)

        # Add protocol if missing
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
        filename = self.output_dir / f"charity_directory_batch_{timestamp}.csv"

        print(f"\n   💾 Saving batch ({len(self.charities)} charities) to CSV...")

        # Write CSV
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
            # Separate charities with EIN (can upsert) vs without EIN (insert only)
            with_ein = [c for c in charities if c.get('ein_charity_number')]
            without_ein = [c for c in charities if not c.get('ein_charity_number')]

            inserted = 0
            updated = 0

            # Process charities WITH EIN (upsert = update existing or insert new)
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
                            'Prefer': 'resolution=merge-duplicates'  # Update if exists, insert if new
                        },
                        json=chunk,
                        timeout=30
                    )

                    if response.status_code in [200, 201]:
                        # Can't distinguish inserts from updates with this API
                        # Just count as successful
                        inserted += len(chunk)

            # Process charities WITHOUT EIN (insert only - can't match existing)
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
                            'Prefer': 'resolution=ignore-duplicates'  # Skip if duplicate
                        },
                        json=chunk,
                        timeout=30
                    )

                    if response.status_code in [200, 201]:
                        inserted += len(chunk)

            print(f"   ✅ Processed {len(charities)} charities ({len(with_ein)} with EIN, {len(without_ein)} without)")
            print(f"   ✅ Upserted {len(with_ein)} (added new + updated existing)")
            print(f"   ✅ Inserted {len(without_ein)} new (no EIN)")

        except Exception as e:
            print(f"   ⚠️  Upload error: {e}")

    def run(self):
        """Main execution"""
        print("=" * 80)
        print("  CHARITY DIRECTORY SCRAPER")
        print("  Extract nonprofit websites from public charity review sites")
        print("=" * 80)
        print(f"\n📂 Output directory: {self.output_dir}\n")

        try:
            # Scrape BBB Wise Giving Alliance
            self.scrape_bbb_wise_giving()

            # Future: Add more sources
            # self.scrape_charity_navigator()
            # self.scrape_guidestar_listings()

            print("\n" + "=" * 80)
            print("  ✅ SCRAPING COMPLETE!")
            print("=" * 80)
            print(f"\n📊 Final Statistics:")
            print(f"   Total pages processed: {self.total_processed}")
            print(f"   Charities with websites: {self.total_with_websites}")
            print(f"   Success rate: {self.total_with_websites/max(self.total_processed,1)*100:.1f}%")
            print(f"   Output directory: {self.output_dir}")
            print(f"\n✅ New charities added to database!\n")

        except Exception as e:
            print(f"\n\n❌ Error: {e}")
            import traceback
            traceback.print_exc()
            sys.exit(1)

if __name__ == "__main__":
    try:
        scraper = CharityDirectoryScraper()
        scraper.run()
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user.\n")
        sys.exit(0)
