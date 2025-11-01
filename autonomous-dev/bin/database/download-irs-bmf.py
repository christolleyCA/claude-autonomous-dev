#!/usr/bin/env python3
"""
Download and parse the IRS Business Master File (BMF)
This file contains ALL tax-exempt organizations with their official names
"""

import requests
import zipfile
from pathlib import Path
import csv
from datetime import datetime

# Configuration
DOWNLOAD_DIR = Path.home() / "irs_bmf_data"
DOWNLOAD_DIR.mkdir(exist_ok=True)

# IRS BMF URL (this is the current extract)
BMF_URL = "https://www.irs.gov/pub/irs-soi/eo_xx.zip"

print("=" * 80)
print("  IRS BUSINESS MASTER FILE DOWNLOAD")
print("=" * 80)
print(f"Download directory: {DOWNLOAD_DIR}")
print(f"URL: {BMF_URL}\n")

# Step 1: Download the file
zip_path = DOWNLOAD_DIR / "eo_xx.zip"

if zip_path.exists():
    print(f"✓ File already downloaded: {zip_path}")
else:
    print("Downloading IRS Business Master File...")
    print("This is a large file (~500MB), it may take a few minutes...\n")

    response = requests.get(BMF_URL, stream=True)
    total_size = int(response.headers.get('content-length', 0))

    with open(zip_path, 'wb') as f:
        downloaded = 0
        for chunk in response.iter_content(chunk_size=8192):
            if chunk:
                f.write(chunk)
                downloaded += len(chunk)
                # Show progress every 10MB
                if downloaded % (10 * 1024 * 1024) < 8192:
                    mb_downloaded = downloaded / (1024 * 1024)
                    mb_total = total_size / (1024 * 1024)
                    print(f"  Downloaded: {mb_downloaded:.1f}MB / {mb_total:.1f}MB")

    print(f"\n✓ Download complete: {zip_path}")

# Step 2: Extract the file
print("\nExtracting ZIP file...")
extract_dir = DOWNLOAD_DIR / "extracted"
extract_dir.mkdir(exist_ok=True)

with zipfile.ZipFile(zip_path, 'r') as zip_ref:
    zip_ref.extractall(extract_dir)

print(f"✓ Extracted to: {extract_dir}")

# List what we extracted
extracted_files = list(extract_dir.glob("*"))
print(f"\nExtracted files:")
for f in extracted_files:
    size_mb = f.stat().st_size / (1024 * 1024)
    print(f"  - {f.name} ({size_mb:.1f}MB)")

print("\n" + "=" * 80)
print("  DOWNLOAD COMPLETE!")
print("=" * 80)
print(f"\nNext step: Parse the extracted file to get EIN → Name mappings")
