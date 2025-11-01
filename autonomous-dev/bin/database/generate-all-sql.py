#!/usr/bin/env python3
"""
Generate ALL SQL INSERT statements for new nonprofits from CSV
Creates multiple files in chunks of 1000 inserts each
"""

import csv
import json
import re
from datetime import datetime
from pathlib import Path

CSV_FILE = "/Users/christophertolleymacbook2019/Downloads/charities_domains_cleaned.csv"
OUTPUT_DIR = Path.home() / "nonprofit_sql_inserts"
CHUNK_SIZE = 1000  # 1000 inserts per file

def normalize_website(url):
    if not url:
        return ''
    url = url.strip()
    if url.upper() in ['N/A', 'NA', 'NONE', 'NULL', 'NOT APPLICABLE', 'S3.AMAZONAWS.COM']:
        return ''
    url = re.sub(r'^WWW\.', '', url, flags=re.IGNORECASE)
    url = re.sub(r'^HTTPS?://', '', url, flags=re.IGNORECASE)
    url = url.split('/')[0]
    if url and not url.startswith('http'):
        url = 'https://' + url
    if len(url) < 10 or ' ' in url:
        return ''
    return url.lower()

def normalize_ein(ein):
    if not ein:
        return None
    ein_str = str(ein).replace('-', '').strip()
    if ein_str.isdigit() and len(ein_str) <= 9:
        return ein_str.zfill(9)
    return None

def escape_sql(s):
    """Escape single quotes for SQL"""
    if s is None:
        return ''
    return str(s).replace("'", "''")

print("=" * 80)
print("  GENERATING SQL INSERTS FOR ALL NEW NONPROFITS")
print("=" * 80)
print(f"\n📂 Reading CSV: {CSV_FILE}")
print(f"📁 Output directory: {OUTPUT_DIR}\n")

OUTPUT_DIR.mkdir(exist_ok=True)

current_chunk = []
chunk_num = 0
total_count = 0
now = datetime.utcnow().isoformat()

with open(CSV_FILE, 'r', encoding='utf-8', errors='ignore') as f:
    reader = csv.DictReader(f)

    for row in reader:
        ein = normalize_ein(row.get('FILEREIN', ''))
        name = row.get('FILERNAME1', '').strip()
        website = normalize_website(row.get('WEBSITSITEIT', ''))

        if not ein or not name or not website:
            continue

        total_count += 1

        # Build contact_info JSON
        contact_info = json.dumps({
            'address': row.get('FILERUS1', ''),
            'address2': row.get('FILERUS2', ''),
            'city': row.get('FILERUSCITY', ''),
            'state': row.get('FILERUSSTATE', ''),
            'zip': str(row.get('FILERUSZIP', '')).split('.')[0],
            'phone': ''
        })

        revenue = int(float(row.get('TOTREVCURYEA', 0) or 0))

        # Generate INSERT VALUES line
        insert_line = f"('{escape_sql(ein)}', '{escape_sql(name)}', 'US', '{escape_sql(website)}', '{escape_sql(contact_info)}', {revenue}, '501(c)(3)', 'Public Charity', false, '{now}', '{now}', ARRAY['General'])"

        current_chunk.append(insert_line)

        # Save chunk when full
        if len(current_chunk) >= CHUNK_SIZE:
            chunk_num += 1
            chunk_file = OUTPUT_DIR / f"chunk_{str(chunk_num).zfill(3)}.sql"

            with open(chunk_file, 'w') as f:
                f.write(f"-- Chunk {chunk_num}: Inserts {(chunk_num-1)*CHUNK_SIZE + 1} to {chunk_num*CHUNK_SIZE}\n\n")
                f.write("INSERT INTO nonprofits (ein_charity_number, name, country, website, contact_info, annual_revenue, tax_status, organization_type, is_foundation, created_at, updated_at, cause_areas)\n")
                f.write("VALUES\n")
                f.write(',\n'.join(current_chunk))
                f.write("\nON CONFLICT (ein_charity_number) DO NOTHING;")

            print(f"   ✅ Created {chunk_file.name} ({len(current_chunk)} inserts)")
            current_chunk = []

    # Save remaining chunk
    if current_chunk:
        chunk_num += 1
        chunk_file = OUTPUT_DIR / f"chunk_{str(chunk_num).zfill(3)}.sql"

        with open(chunk_file, 'w') as f:
            f.write(f"-- Chunk {chunk_num}: Final {len(current_chunk)} inserts\n\n")
            f.write("INSERT INTO nonprofits (ein_charity_number, name, country, website, contact_info, annual_revenue, tax_status, organization_type, is_foundation, created_at, updated_at, cause_areas)\n")
            f.write("VALUES\n")
            f.write(',\n'.join(current_chunk))
            f.write("\nON CONFLICT (ein_charity_number) DO NOTHING;")

        print(f"   ✅ Created {chunk_file.name} ({len(current_chunk)} inserts)")

print("\n" + "=" * 80)
print("  ✅ SQL GENERATION COMPLETE!")
print("=" * 80)
print(f"\n📊 Summary:")
print(f"   Total nonprofits: {total_count:,}")
print(f"   SQL chunk files: {chunk_num}")
print(f"   Inserts per chunk: {CHUNK_SIZE}")
print(f"   Output directory: {OUTPUT_DIR}")
print(f"\n✅ Ready to apply migrations!\n")
