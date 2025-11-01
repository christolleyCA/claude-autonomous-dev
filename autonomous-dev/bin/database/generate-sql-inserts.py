#!/usr/bin/env python3
"""
Generate SQL INSERT statements for new nonprofits
"""

import csv
import json
import re
from datetime import datetime

CSV_FILE = "/Users/christophertolleymacbook2019/Downloads/charities_domains_cleaned.csv"
OUTPUT_FILE = "/Users/christophertolleymacbook2019/new_nonprofits_inserts.sql"

# These are the EINs that already exist (first 613K fetched)
EXISTING_EINS_FILE = "/Users/christophertolleymacbook2019/existing_eins.txt"

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

print("Generating SQL INSERT statements...")
print(f"This will create inserts for NEW nonprofits only\n")

inserts = []
count = 0
now = datetime.utcnow().isoformat()

with open(CSV_FILE, 'r', encoding='utf-8', errors='ignore') as f:
    reader = csv.DictReader(f)

    for row in reader:
        ein = normalize_ein(row.get('FILEREIN', ''))
        name = row.get('FILERNAME1', '').strip()
        website = normalize_website(row.get('WEBSITSITEIT', ''))

        if not ein or not name or not website:
            continue

        count += 1

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

        # Generate INSERT
        insert = f"""INSERT INTO nonprofits (ein_charity_number, name, country, website, contact_info, annual_revenue, tax_status, organization_type, is_foundation, created_at, updated_at, cause_areas)
VALUES ('{escape_sql(ein)}', '{escape_sql(name)}', 'US', '{escape_sql(website)}', '{escape_sql(contact_info)}', {revenue}, '501(c)(3)', 'Public Charity', false, '{now}', '{now}', '["General"]')
ON CONFLICT (ein_charity_number) DO NOTHING;"""

        inserts.append(insert)

        # Limit to 5000 for now (test)
        if count >= 5000:
            break

print(f"Generated {len(inserts)} INSERT statements")
print(f"Writing to {OUTPUT_FILE}...\n")

with open(OUTPUT_FILE, 'w') as f:
    f.write("-- Insert new nonprofits from CSV\n")
    f.write("-- ON CONFLICT DO NOTHING will skip duplicates\n\n")
    f.write('\n'.join(inserts))

print(f"✅ SQL file created: {OUTPUT_FILE}")
print(f"   Total inserts: {len(inserts)}")
print(f"\nYou can now run this with: apply_migration")
