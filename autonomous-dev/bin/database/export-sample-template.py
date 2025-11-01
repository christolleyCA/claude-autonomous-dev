#!/usr/bin/env python3
"""
Export a sample template CSV with 20 nonprofits:
- 10 with websites and classifications (examples)
- 10 without (for you to fill in)
"""

import csv
import sys
import subprocess
from pathlib import Path

# Output file
OUTPUT_FILE = Path.home() / "nonprofit_classification_template.csv"

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"


def get_completed_examples():
    """Get 10 nonprofits with websites and classifications"""
    print("📋 Fetching 10 completed examples (with classifications)...")

    sql = """
    SELECT
      ein_charity_number,
      name,
      contact_info->>'city' as city,
      contact_info->>'state' as state,
      public_facing,
      website
    FROM nonprofits
    WHERE website IS NOT NULL
      AND public_facing IS NOT NULL
    ORDER BY annual_revenue DESC NULLS LAST
    LIMIT 10;
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
                    if len(parts) >= 6:
                        rows.append({
                            'EIN': parts[0],
                            'Name': parts[1],
                            'City': parts[2],
                            'State': parts[3],
                            'Public-facing': parts[4].upper() if parts[4] else '',
                            'Website': parts[5]
                        })

            print(f"   ✅ Found {len(rows)} completed examples")
            return rows
        else:
            print(f"   ❌ Query failed: {result.stderr}")
            return []

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return []


def get_empty_examples():
    """Get 10 nonprofits without classifications (for template)"""
    print("📋 Fetching 10 unprocessed examples (to fill in)...")

    sql = """
    SELECT
      ein_charity_number,
      name,
      contact_info->>'city' as city,
      contact_info->>'state' as state
    FROM nonprofits
    WHERE (website IS NULL OR public_facing IS NULL)
      AND contact_info->>'city' IS NOT NULL
    ORDER BY annual_revenue DESC NULLS LAST
    LIMIT 10;
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
                            'Public-facing': '',  # Empty for you to fill
                            'Website': ''  # Empty for you to fill
                        })

            print(f"   ✅ Found {len(rows)} unprocessed examples")
            return rows
        else:
            print(f"   ❌ Query failed: {result.stderr}")
            return []

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return []


def save_template(completed_rows, empty_rows):
    """Save template CSV with both completed and empty examples"""
    print(f"💾 Creating template file: {OUTPUT_FILE.name}...")

    all_rows = completed_rows + empty_rows

    with open(OUTPUT_FILE, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'EIN', 'Name', 'City', 'State', 'Public-facing', 'Website'
        ])
        writer.writeheader()
        writer.writerows(all_rows)

    size_kb = OUTPUT_FILE.stat().st_size / 1024
    print(f"   ✅ Saved {len(all_rows)} records ({size_kb:.1f} KB)")
    print(f"   📁 Location: {OUTPUT_FILE}")


def main():
    print("📝 Create Nonprofit Classification Template")
    print("=" * 80)
    print()

    # Get completed examples (10 with data)
    completed = get_completed_examples()

    # Get empty examples (10 without data)
    empty = get_empty_examples()

    if not completed and not empty:
        print("\n❌ No data retrieved!")
        return 1

    print()

    # Save template
    save_template(completed, empty)

    print()
    print("=" * 80)
    print("✅ Template created!")
    print()
    print("📊 Template structure:")
    print(f"   • First 10 rows:  COMPLETED examples (with classifications)")
    print(f"   • Last 10 rows:   EMPTY examples (for you to fill in)")
    print()
    print("📝 How to use this template:")
    print("   1. Open the CSV file")
    print("   2. See the first 10 rows as examples of completed data")
    print("   3. Fill in the last 10 rows following the same format")
    print("   4. For Public-facing column, use: TRUE or FALSE")
    print("   5. Save and use this as your guide for the larger files")
    print()
    print("💡 Column definitions:")
    print("   • EIN:           Tax ID number (don't change)")
    print("   • Name:          Organization name (don't change)")
    print("   • City:          City (don't change)")
    print("   • State:         State (don't change)")
    print("   • Public-facing: TRUE (real domain) or FALSE (social/malformed)")
    print("   • Website:       The website URL you found")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    sys.exit(main())
