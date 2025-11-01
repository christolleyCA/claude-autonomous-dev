#!/usr/bin/env python3
"""
California Attorney General Registry of Charitable Trusts Scraper

Scrapes charity information from California AG's public registry:
https://rct.doj.ca.gov/Verification/Web/Search.aspx?facility=Y

Extracts: Name, EIN, Website, Location from Form 990-EZ PDF filings

Requirements:
- selenium (for ASP.NET form navigation)
- pdfplumber (for PDF text extraction)
- Chrome/ChromeDriver (for Selenium)
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
from urllib.parse import urljoin
import tempfile

# Configuration
SUPABASE_URL = "https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

OUTPUT_DIR = Path.home() / "990_nonprofit_data"
BATCH_SIZE = 500
MAX_CHARITIES = 50  # Process first page of results

class CaliforniaRegistryScraper:
    def __init__(self):
        self.output_dir = OUTPUT_DIR
        self.output_dir.mkdir(exist_ok=True)
        self.temp_dir = Path(tempfile.mkdtemp())
        self.charities = []
        self.total_processed = 0
        self.total_with_websites = 0
        self.driver = None

        # Import here to give helpful error messages
        try:
            from selenium import webdriver
            from selenium.webdriver.common.by import By
            from selenium.webdriver.support.ui import Select, WebDriverWait
            from selenium.webdriver.support import expected_conditions as EC
            from selenium.webdriver.chrome.options import Options
            self.webdriver = webdriver
            self.By = By
            self.Select = Select
            self.WebDriverWait = WebDriverWait
            self.EC = EC
            self.Options = Options
        except ImportError:
            print("\n❌ Error: Selenium not installed")
            print("Install with: pip3 install selenium")
            print("Also need ChromeDriver: brew install chromedriver")
            sys.exit(1)

        try:
            import pdfplumber
            self.pdfplumber = pdfplumber
        except ImportError:
            print("\n❌ Error: pdfplumber not installed")
            print("Install with: pip3 install pdfplumber")
            sys.exit(1)

    def setup_driver(self):
        """Initialize Selenium WebDriver"""
        print("🔧 Setting up Chrome WebDriver...")

        options = self.Options()
        options.add_argument('--headless')  # Run without opening browser window
        options.add_argument('--no-sandbox')
        options.add_argument('--disable-dev-shm-usage')

        # Set download directory
        prefs = {
            "download.default_directory": str(self.temp_dir),
            "download.prompt_for_download": False,
            "plugins.always_open_pdf_externally": True
        }
        options.add_experimental_option("prefs", prefs)

        try:
            self.driver = self.webdriver.Chrome(options=options)
            print("   ✅ Chrome WebDriver ready")
        except Exception as e:
            print(f"\n❌ Error starting Chrome: {e}")
            print("\nTry installing ChromeDriver:")
            print("  brew install chromedriver")
            print("  xattr -d com.apple.quarantine /usr/local/bin/chromedriver")
            sys.exit(1)

    def search_charities(self):
        """Submit search form and get all charity links"""
        print("\n" + "=" * 80)
        print("  CALIFORNIA AG REGISTRY OF CHARITABLE TRUSTS")
        print("=" * 80)
        print(f"\n📥 Accessing registry search page...")

        search_url = "https://rct.doj.ca.gov/Verification/Web/Search.aspx?facility=Y"

        try:
            self.driver.get(search_url)

            # Wait for page to fully load
            wait = self.WebDriverWait(self.driver, 20)

            print(f"   ✅ Page loaded")
            print(f"   🔍 Waiting for form elements...")

            # Wait for and find Program Type dropdown (CORRECT ID from HTML)
            program_select_element = wait.until(
                self.EC.presence_of_element_located((self.By.ID, "t_web_lookup__profession_name"))
            )

            print(f"   ✅ Found Program Type dropdown")

            # Set Program Type = "Charity"
            program_select = self.Select(program_select_element)
            program_select.select_by_value("Charity")
            time.sleep(1)

            # Find Registry Status dropdown (CORRECT ID from HTML)
            status_select_element = wait.until(
                self.EC.presence_of_element_located((self.By.ID, "t_web_lookup__license_status_name"))
            )

            print(f"   ✅ Found Registry Status dropdown")

            # Set Registry Status = "Current"
            status_select = self.Select(status_select_element)
            status_select.select_by_value("Current")
            time.sleep(1)

            print(f"   ✅ Search criteria set: Charity + Current")
            print(f"   🔎 Submitting search...")

            # Find and click search button (CORRECT ID from HTML)
            search_button = wait.until(
                self.EC.element_to_be_clickable((self.By.ID, "sch_button"))
            )

            search_button.click()

            # Wait for results grid to load
            time.sleep(8)

            print(f"   ✅ Results loaded")
            print(f"   📊 Extracting charity links...\n")

            # Extract all charity links from results table
            charity_links = []

            # Find all links in the results grid (CORRECT ID from HTML)
            wait.until(self.EC.presence_of_element_located((self.By.ID, "datagrid_results")))

            grid = self.driver.find_element(self.By.ID, "datagrid_results")
            rows = grid.find_elements(self.By.TAG_NAME, "tr")

            for row in rows:
                try:
                    # Look for charity name link (has href="Details.aspx?result=...")
                    link_elements = row.find_elements(self.By.TAG_NAME, "a")

                    for link_element in link_elements:
                        href = link_element.get_attribute("href")
                        if href and "Details.aspx?result=" in href:
                            charity_name = link_element.text.strip()

                            if charity_name:  # Skip empty names
                                charity_links.append({
                                    'url': href,
                                    'name': charity_name
                                })
                                break  # Only take first charity link per row

                    if len(charity_links) >= MAX_CHARITIES:
                        break  # Safety limit reached

                except Exception as e:
                    continue

            print(f"   ✅ Found {len(charity_links)} charities")
            return charity_links

        except Exception as e:
            print(f"\n   ❌ Error during search: {e}")

            # Save debug info
            try:
                debug_dir = self.output_dir / "debug"
                debug_dir.mkdir(exist_ok=True)

                screenshot_path = debug_dir / "error_screenshot.png"
                self.driver.save_screenshot(str(screenshot_path))
                print(f"   💾 Screenshot saved: {screenshot_path}")

                html_path = debug_dir / "error_page_source.html"
                with open(html_path, 'w') as f:
                    f.write(self.driver.page_source)
                print(f"   💾 Page source saved: {html_path}")
            except:
                pass

            raise

    def extract_website_from_pdf(self, pdf_path, debug=False):
        """Extract website URL from 990-EZ PDF"""
        # Also debug charity #2 to see website field
        debug = debug or (self.total_processed == 1)

        if debug:
            print(f"      DEBUG: Extracting website from PDF (charity #{self.total_processed+1})...")
            print(f"      DEBUG: PDF path: {pdf_path}")
            print(f"      DEBUG: PDF exists: {Path(pdf_path).exists()}")

        try:
            if debug:
                print(f"      Opening PDF with pdfplumber...")

            with self.pdfplumber.open(pdf_path) as pdf:
                # Check first 10 pages (RRF-1 form + attached IRS Form 990)
                if debug:
                    print(f"      PDF has {len(pdf.pages)} pages")
                    print(f"      Searching first 10 pages for website...")

                for page_num in range(min(10, len(pdf.pages))):
                    page = pdf.pages[page_num]
                    text = page.extract_text()

                    if debug:
                        print(f"      Page {page_num+1}: Extracted {len(text) if text else 0} characters")

                    if not text or not text.strip():
                        if debug:
                            print(f"      Page {page_num+1}: No useful text (image-based PDF)")
                        continue

                    # Debug: Save text from all pages
                    if debug:
                        debug_text_file = self.output_dir / "debug_sample_text.txt"
                        mode = 'w' if page_num == 0 else 'a'
                        with open(debug_text_file, mode) as f:
                            f.write(f"=== PAGE {page_num+1} ===\n{text}\n\n")
                        print(f"      Page {page_num+1}: Saved text to debug file")

                    # Look for website field patterns
                    # Pattern 1: "J Website: www.example.org" (allow spaces from OCR errors)
                    website_match = re.search(r'(?:^|\s)[IJ]\s*Website:\s*([^\n]+)', text, re.MULTILINE | re.IGNORECASE)

                    if website_match:
                        if debug:
                            print(f"      Pattern 1 matched 'J Website:' field")

                        website = website_match.group(1).strip()

                        # Clean up OCR errors and extract just the URL part
                        # Remove everything after certain patterns (like "H(c)")
                        website = re.split(r'\s+[A-Z]\([a-z]\)', website)[0]

                        # Remove all spaces (OCR often adds spaces: "www .example .org")
                        website = re.sub(r'\s+', '', website)

                        # Fix common OCR errors
                        website = website.replace('www_', 'www.')
                        website = website.replace('_', '.')

                        if debug:
                            print(f"      Raw website value: '{website}'")

                        if len(website) > 5 and '.' in website:
                            normalized = self.normalize_website(website)
                            if debug:
                                print(f"      Normalized to: '{normalized}'")
                            if normalized:
                                return normalized

                    # Pattern 2: Look for URLs in the text
                    if debug:
                        print(f"      Trying Pattern 2 (URL search)...")
                    url_pattern = r'(?:https?://)?(?:www\.)?([a-zA-Z0-9][-a-zA-Z0-9]*\.)+[a-zA-Z]{2,}'
                    urls = re.findall(url_pattern, text)

                    for url in urls:
                        # Filter out common false positives
                        if any(skip in url.lower() for skip in ['irs.gov', 'ftb.ca.gov', 'doj.ca.gov', 'example.com']):
                            continue
                        if len(url) > 5:
                            return self.normalize_website(url)

            return None

        except Exception as e:
            if debug:
                print(f"      DEBUG: PDF extraction exception: {e}")
                import traceback
                traceback.print_exc()
            return None

    def normalize_website(self, url):
        """Normalize website URL"""
        if not url:
            return ''

        url = url.strip()

        # Remove common junk
        url = re.sub(r'[,;:\s].*$', '', url)  # Remove everything after comma/semicolon/etc

        # Add protocol if missing
        if not url.startswith('http'):
            url = 'https://' + url

        # Basic validation
        if len(url) < 10 or ' ' in url:
            return ''

        return url.lower()

    def scrape_charity_detail(self, charity_info):
        """Navigate to charity detail page and extract data from most recent filing"""
        try:
            if self.total_processed == 0:
                print(f"\n      DEBUG: Visiting {charity_info['url']}")

            self.driver.get(charity_info['url'])
            time.sleep(2)

            # Look for all links with "Renewal Filing" text
            try:
                all_links = self.driver.find_elements(self.By.TAG_NAME, "a")
                renewal_links = []

                for link in all_links:
                    if 'Renewal Filing' in link.text:
                        href = link.get_attribute("href")
                        if href and 'Download.aspx' in href:
                            renewal_links.append(href)

                if self.total_processed == 0:
                    print(f"      DEBUG: Found {len(renewal_links)} renewal filings")
                    if renewal_links:
                        print(f"      DEBUG: Most recent: {renewal_links[0]}")

                if not renewal_links:
                    if self.total_processed == 0:
                        print(f"      DEBUG: No renewal filings found")
                    return None

                # Use most recent (first) renewal filing
                renewal_link = renewal_links[0]

            except Exception as e:
                if self.total_processed == 0:
                    print(f"      DEBUG: Error finding renewal links: {e}")
                    debug_page = self.output_dir / "debug_detail_page.html"
                    with open(debug_page, 'w') as f:
                        f.write(self.driver.page_source)
                    print(f"      DEBUG: Page source saved to {debug_page}")
                return None

            try:

                # Download PDF using driver's session (copy cookies)
                pdf_path = self.temp_dir / f"temp_{self.total_processed}.pdf"

                # Get cookies from Selenium driver
                cookies = self.driver.get_cookies()
                session = requests.Session()
                for cookie in cookies:
                    session.cookies.set(cookie['name'], cookie['value'])

                # Add headers including Referer from current page
                headers = {
                    'Referer': self.driver.current_url,
                    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
                }

                if self.total_processed == 0:
                    print(f"      DEBUG: Downloading PDF with {len(cookies)} cookies and Referer header")
                    print(f"      DEBUG: Referer: {self.driver.current_url}")

                response = session.get(renewal_link, headers=headers, timeout=30)

                if self.total_processed == 0:
                    print(f"      DEBUG: Response status: {response.status_code}")
                    print(f"      DEBUG: Content-Type: {response.headers.get('Content-Type', 'unknown')}")
                    print(f"      DEBUG: Content length: {len(response.content)} bytes")

                with open(pdf_path, 'wb') as f:
                    f.write(response.content)

                # Save first PDF for debugging
                debug_mode = (self.total_processed == 0)
                if debug_mode:
                    debug_pdf = self.output_dir / "debug_sample.pdf"
                    with open(debug_pdf, 'wb') as f:
                        f.write(response.content)
                    print(f"\n   💾 DEBUG: Sample PDF saved to {debug_pdf}")

                # Extract website from PDF
                website = self.extract_website_from_pdf(pdf_path, debug=debug_mode)

                # Clean up PDF
                try:
                    pdf_path.unlink()
                except:
                    pass

                if not website:
                    return None

                # Extract EIN from page (if available)
                try:
                    ein_text = self.driver.find_element(self.By.ID, "ctl00_ContentPlaceHolder1_lblOrgEIN").text
                    ein = re.sub(r'\D', '', ein_text)  # Remove non-digits
                except:
                    ein = ''

                return {
                    'ein_charity_number': ein if ein else '',
                    'name': charity_info['name'],
                    'country': 'US',
                    'website': website,
                    'contact_info': json.dumps({
                        'state': 'CA',  # All CA charities
                    }),
                    'organization_type': 'Public Charity',
                    'is_foundation': False,
                    'created_at': datetime.utcnow().isoformat(),
                    'updated_at': datetime.utcnow().isoformat()
                }

            except Exception as e:
                return None

        except Exception as e:
            return None

    def save_batch(self):
        """Save and upload batch"""
        if not self.charities:
            return

        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = self.output_dir / f"california_ag_batch_{timestamp}.csv"

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

            # Upload charities with EIN (can upsert)
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

            # Upload charities without EIN (insert only)
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

            print(f"   ✅ Uploaded {len(charities)} charities")

        except Exception as e:
            print(f"   ⚠️  Upload error: {e}")

    def run(self):
        """Main execution"""
        print("=" * 80)
        print("  CALIFORNIA AG REGISTRY SCRAPER")
        print("=" * 80)
        print(f"\n📂 Output directory: {self.output_dir}")
        print(f"📂 Temp directory: {self.temp_dir}\n")

        try:
            self.setup_driver()

            # Get all charity links
            charity_links = self.search_charities()

            print(f"🔍 Processing charities...\n")

            for i, charity_info in enumerate(charity_links, 1):
                try:
                    # Rate limiting
                    if i > 1:
                        time.sleep(3)  # 3 seconds between requests

                    charity_data = self.scrape_charity_detail(charity_info)

                    if charity_data and charity_data.get('website'):
                        self.charities.append(charity_data)
                        self.total_with_websites += 1
                        print(f"   [{i}/{len(charity_links)}] ✅ {charity_data['name'][:50]}")
                    else:
                        print(f"   [{i}/{len(charity_links)}] ⚠️  No website: {charity_info['name'][:50]}")

                    self.total_processed += 1

                    # Save batch
                    if len(self.charities) >= BATCH_SIZE:
                        self.save_batch()

                except Exception as e:
                    print(f"   [{i}/{len(charity_links)}] ❌ Error: {str(e)[:50]}")
                    continue

            # Save remaining
            if self.charities:
                self.save_batch()

            print("\n" + "=" * 80)
            print("  ✅ SCRAPING COMPLETE!")
            print("=" * 80)
            print(f"\n📊 Final Statistics:")
            print(f"   Total processed: {self.total_processed}")
            print(f"   Charities with websites: {self.total_with_websites}")
            print(f"   Success rate: {self.total_with_websites/max(self.total_processed,1)*100:.1f}%")
            print(f"   Output directory: {self.output_dir}")
            print(f"\n✅ California charities added to database!\n")

        except Exception as e:
            print(f"\n\n❌ Error: {e}")
            import traceback
            traceback.print_exc()
        finally:
            if self.driver:
                self.driver.quit()

            # Clean up temp directory
            try:
                import shutil
                shutil.rmtree(self.temp_dir)
            except:
                pass

if __name__ == "__main__":
    try:
        print("DEBUG: Starting script...")
        sys.stdout.flush()
        scraper = CaliforniaRegistryScraper()
        print("DEBUG: Scraper initialized")
        sys.stdout.flush()
        scraper.run()
        print("DEBUG: Run completed")
        sys.stdout.flush()
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user.\n")
        sys.exit(0)
    except Exception as e:
        print(f"DEBUG: Exception caught: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
