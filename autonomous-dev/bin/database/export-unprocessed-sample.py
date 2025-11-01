#!/usr/bin/env python3
"""
Export 20 unprocessed nonprofits as a sample template
- All rows need classification (public_facing IS NULL)
- Empty Website and Public-facing columns for you to fill in
"""

import csv
import sys
import subprocess
from pathlib import Path

# Output file
OUTPUT_FILE = Path.home() / "nonprofit_classification_sample_unprocessed.csv"

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"


def get_unprocessed_sample():
    """Get 20 unprocessed nonprofits"""
    print("📋 Fetching 20 unprocessed nonprofits (for classification)...")

    sql = """
    SELECT
      ein_charity_number,
      name,
      contact_info->>'city' as city,
      contact_info->>'state' as state,
      website
    FROM nonprofits
    WHERE public_facing IS NULL
      AND contact_info->>'city' IS NOT NULL
    ORDER BY annual_revenue DESC NULLS LAST
    LIMIT 20;
    """

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-t', '-A', '-F', '|', '-c', sql],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=60
        )

        if result.returncode == 0:
            rows = []
            for line in result.stdout.strip().split('\n'):
                if '|' in line:
                    parts = line.split('|')
                    if len(parts) >= 5:
                        # Show existing website if any, but leave Public-facing empty
                        existing_website = parts[4] if len(parts) > 4 and parts[4] else ''

                        rows.append({
                            'EIN': parts[0],
                            'Name': parts[1],
                            'City': parts[2],
                            'State': parts[3],
                            'Website': existing_website,
                            'Public-facing': ''  # Empty for classification
                        })

            print(f"   ✅ Found {len(rows)} unprocessed nonprofits")
            return rows
        else:
            print(f"   ❌ Query failed: {result.stderr}")
            return []

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return []


def save_sample(rows):
    """Save sample CSV"""
    print(f"💾 Creating sample file: {OUTPUT_FILE.name}...")

    with open(OUTPUT_FILE, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'EIN', 'Name', 'City', 'State', 'Website', 'Public-facing'
        ])
        writer.writeheader()
        writer.writerows(rows)

    size_kb = OUTPUT_FILE.stat().st_size / 1024
    print(f"   ✅ Saved {len(rows)} records ({size_kb:.1f} KB)")
    print(f"   📁 Location: {OUTPUT_FILE}")


def main():
    print("📝 Export Unprocessed Sample for Classification")
    print("=" * 80)
    print()

    # Get unprocessed sample
    sample_rows = get_unprocessed_sample()

    if not sample_rows:
        print("\n❌ No data retrieved!")
        return 1

    print()

    # Save sample
    save_sample(sample_rows)

    print()
    print("=" * 80)
    print("✅ Unprocessed sample created!")
    print()
    print("📊 This sample contains:")
    print("   • 20 nonprofits needing classification")
    print("   • EIN, Name, City, State (reference data)")
    print("   • Website column (some may have existing websites to verify)")
    print("   • Public-facing column (EMPTY - for you to fill in)")
    print()
    print("📝 Your task:")
    print("   1. For each row, find/verify the organization's website")
    print("   2. Fill in the Website column (if empty or needs correction)")
    print("   3. Classify as Public-facing:")
    print("      • TRUE  = Real organizational domain (example.org)")
    print("      • FALSE = Social media, internal path, or malformed")
    print()
    print("💡 This sample represents what you'll see in the 50k batch files:")
    print("   • Some orgs already have websites listed")
    print("   • Some need you to find their websites")
    print("   • ALL need Public-facing classification (TRUE/FALSE)")
    print()
    print("🎯 Practice on these 20 rows, then apply to your larger files:")
    print("   • nonprofits_batch_1_50k.csv")
    print("   • nonprofits_batch_2_50k.csv")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    sys.exit(main())
