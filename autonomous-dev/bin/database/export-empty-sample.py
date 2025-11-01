#!/usr/bin/env python3
"""
Export 20 nonprofits with NO website and NO classification
- Completely empty Website and Public-facing columns
- You need to find websites from scratch
"""

import csv
import sys
import subprocess
from pathlib import Path

# Output file
OUTPUT_FILE = Path.home() / "nonprofit_classification_sample_empty.csv"

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"


def get_empty_sample():
    """Get 20 nonprofits with no website and no classification"""
    print("📋 Fetching 20 nonprofits with NO website and NO classification...")

    sql = """
    SELECT
      ein_charity_number,
      name,
      contact_info->>'city' as city,
      contact_info->>'state' as state
    FROM nonprofits
    WHERE (website IS NULL OR website = '')
      AND public_facing IS NULL
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
                    if len(parts) >= 4:
                        rows.append({
                            'EIN': parts[0],
                            'Name': parts[1],
                            'City': parts[2],
                            'State': parts[3],
                            'Website': '',  # Empty - you need to find it
                            'Public-facing': ''  # Empty - you need to classify
                        })

            print(f"   ✅ Found {len(rows)} nonprofits with no website data")
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
    print("📝 Export Empty Sample (No Websites, No Classifications)")
    print("=" * 80)
    print()

    # Get empty sample
    sample_rows = get_empty_sample()

    if not sample_rows:
        print("\n❌ No data retrieved!")
        return 1

    print()

    # Save sample
    save_sample(sample_rows)

    print()
    print("=" * 80)
    print("✅ Empty sample created!")
    print()
    print("📊 This sample contains:")
    print("   • 20 nonprofits with NO website data")
    print("   • EIN, Name, City, State (for reference)")
    print("   • Website column: EMPTY (find from scratch)")
    print("   • Public-facing column: EMPTY (classify after finding)")
    print()
    print("📝 Your complete workflow:")
    print("   1. Use EIN, Name, City, State to search for the organization")
    print("   2. Find their website (Google, IRS database, etc.)")
    print("   3. Enter the website URL in the Website column")
    print("   4. Classify as Public-facing:")
    print("      • TRUE  = Real organizational domain (example.org)")
    print("      • FALSE = Social media (@handle), partial (/path), malformed")
    print()
    print("💡 Search tips:")
    print("   • Google: [Organization Name] [City] [State]")
    print("   • Check IRS 990 forms (they often list websites)")
    print("   • Verify the URL actually loads before classifying")
    print("   • If no website exists, leave Website empty, Public-facing empty")
    print()
    print("🎯 This is the cleanest sample - true 'from scratch' work")
    print("   Practice on these 20 before tackling the 50k batches!")
    print()
    print("📚 Reference files:")
    print("   • nonprofit_classification_template.csv (see TRUE/FALSE examples)")
    print("   • nonprofit_classification_sample_unprocessed.csv (some have websites)")
    print("   • THIS FILE: completely empty (find everything)")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    sys.exit(main())
