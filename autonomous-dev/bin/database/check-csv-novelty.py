#!/usr/bin/env python3
"""
Check if CSV contains any new nonprofits not in database
"""

import csv
import requests
import re

CSV_FILE = "/Users/christophertolleymacbook2019/Downloads/charities_domains_cleaned.csv"
SUPABASE_URL = "https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

def normalize_ein(ein):
    if not ein:
        return None
    ein_str = str(ein).replace('-', '').strip()
    if ein_str.isdigit() and len(ein_str) <= 9:
        return ein_str.zfill(9)
    return None

# Sample 1000 EINs from CSV
sample_eins = []
print("📊 Sampling EINs from CSV...")

with open(CSV_FILE, 'r', encoding='utf-8', errors='ignore') as f:
    reader = csv.DictReader(f)
    for i, row in enumerate(reader):
        if i >= 1000:
            break
        ein = normalize_ein(row.get('FILEREIN', ''))
        if ein:
            sample_eins.append(ein)

print(f"   Sampled {len(sample_eins)} EINs\n")

# Check which exist in database
print("🔍 Checking against database...")
ein_list = ','.join([f'"{ein}"' for ein in sample_eins])

response = requests.get(
    f"{SUPABASE_URL}/rest/v1/nonprofits",
    headers={
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
    },
    params={
        'select': 'ein_charity_number',
        'ein_charity_number': f'in.({ein_list})'
    },
    timeout=30
)

existing_eins = set([row['ein_charity_number'] for row in response.json()])
new_eins = set(sample_eins) - existing_eins

print(f"\n📊 Results:")
print(f"   Sampled EINs: {len(sample_eins)}")
print(f"   Already in database: {len(existing_eins)} ({len(existing_eins)/len(sample_eins)*100:.1f}%)")
print(f"   NEW EINs: {len(new_eins)} ({len(new_eins)/len(sample_eins)*100:.1f}%)")

if new_eins:
    print(f"\n✅ CSV contains new nonprofits!")
    print(f"   Estimated total new nonprofits: {len(new_eins)/1000 * 210000:.0f}")
else:
    print(f"\n❌ CSV appears to be redundant - all sampled EINs already in database")
