#!/usr/bin/env python3
"""
Download and parse the IRS Business Master File (BMF) - US Organizations
The IRS splits US orgs into 4 regional files based on EIN prefix
"""

import requests
import zipfile
from pathlib import Path
import time

# Configuration
DOWNLOAD_DIR = Path.home() / "irs_bmf_data"
DOWNLOAD_DIR.mkdir(exist_ok=True)

# IRS BMF URLs for US organizations (split by region)
BMF_FILES = {
    'eo1': 'https://www.irs.gov/pub/irs-soi/eo1.zip',  # EINs starting with 0-2
    'eo2': 'https://www.irs.gov/pub/irs-soi/eo2.zip',  # EINs starting with 3-5
    'eo3': 'https://www.irs.gov/pub/irs-soi/eo3.zip',  # EINs starting with 6-8
    'eo4': 'https://www.irs.gov/pub/irs-soi/eo4.zip',  # EINs starting with 9
}

print("=" * 80)
print("  IRS BUSINESS MASTER FILE DOWNLOAD - US ORGANIZATIONS")
print("=" * 80)
print(f"Download directory: {DOWNLOAD_DIR}")
print(f"Downloading 4 regional files...\n")

for file_name, url in BMF_FILES.items():
    print(f"\n📥 Downloading {file_name}.zip...")
    print(f"   URL: {url}")

    zip_path = DOWNLOAD_DIR / f"{file_name}.zip"

    if zip_path.exists():
        print(f"   ✓ Already downloaded: {zip_path}")
        continue

    try:
        response = requests.get(url, stream=True, timeout=300)
        response.raise_for_status()

        total_size = int(response.headers.get('content-length', 0))

        with open(zip_path, 'wb') as f:
            downloaded = 0
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    # Show progress every 5MB
                    if downloaded % (5 * 1024 * 1024) < 8192:
                        mb_downloaded = downloaded / (1024 * 1024)
                        mb_total = total_size / (1024 * 1024)
                        print(f"   Progress: {mb_downloaded:.1f}MB / {mb_total:.1f}MB")

        print(f"   ✓ Downloaded: {zip_path}")

        # Extract immediately
        print(f"   📦 Extracting...")
        extract_dir = DOWNLOAD_DIR / "extracted"
        extract_dir.mkdir(exist_ok=True)

        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_dir)

        # List extracted files
        for extracted_file in extract_dir.glob(f"{file_name.upper()}.*"):
            size_mb = extracted_file.stat().st_size / (1024 * 1024)
            print(f"   ✓ Extracted: {extracted_file.name} ({size_mb:.1f}MB)")

        # Small delay between downloads
        time.sleep(1)

    except Exception as e:
        print(f"   ❌ Error downloading {file_name}: {e}")
        continue

print("\n" + "=" * 80)
print("  DOWNLOAD COMPLETE!")
print("=" * 80)

# Show summary
extract_dir = DOWNLOAD_DIR / "extracted"
all_files = list(extract_dir.glob("EO*.DAT")) + list(extract_dir.glob("EO*.dat"))
total_size = sum(f.stat().st_size for f in all_files) / (1024 * 1024)

print(f"\nExtracted data files:")
for f in sorted(all_files):
    size_mb = f.stat().st_size / (1024 * 1024)
    print(f"  - {f.name} ({size_mb:.1f}MB)")

print(f"\nTotal size: {total_size:.1f}MB")
print(f"\nNext step: Parse these files to extract EIN → Name mappings")
