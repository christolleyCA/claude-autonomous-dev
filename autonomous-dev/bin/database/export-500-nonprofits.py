#!/usr/bin/env python3
"""
Export 500 nonprofits without websites to CSV
"""

import csv
import sys
import subprocess
from pathlib import Path

# Output file
OUTPUT_FILE = Path.home() / "nonprofits_without_websites_500.csv"

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"

def export_nonprofits():
    """Export 500 nonprofits without websites"""
    print("🔍 Querying nonprofits without websites...")

    sql = """
    SELECT
      ein_charity_number,
      name,
      contact_info->>'address' as address,
      contact_info->>'city' as city,
      contact_info->>'state' as state,
      contact_info->>'zip' as zip,
      contact_info->>'phone' as phone,
      annual_revenue,
      organization_type
    FROM nonprofits
    WHERE (website IS NULL OR website = '')
      AND contact_info->>'address' IS NOT NULL
      AND DATE(created_at) = '2025-10-22'
    ORDER BY annual_revenue DESC NULLS LAST
    LIMIT 500;
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
                    if len(parts) >= 9:
                        rows.append({
                            'EIN': parts[0],
                            'Name': parts[1],
                            'Address': parts[2],
                            'City': parts[3],
                            'State': parts[4],
                            'ZIP': parts[5],
                            'Phone': parts[6],
                            'Annual Revenue': parts[7],
                            'Organization Type': parts[8]
                        })

            print(f"✅ Retrieved {len(rows)} nonprofits\n")
            return rows
        else:
            print(f"❌ Query failed: {result.stderr}")
            return []

    except Exception as e:
        print(f"❌ Error: {e}")
        return []


def save_to_csv(rows):
    """Save rows to CSV file"""
    print(f"💾 Saving to {OUTPUT_FILE}...")

    with open(OUTPUT_FILE, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'EIN', 'Name', 'Address', 'City', 'State', 'ZIP', 'Phone',
            'Annual Revenue', 'Organization Type'
        ])
        writer.writeheader()
        writer.writerows(rows)

    print(f"✅ Saved {len(rows)} nonprofits to CSV")
    print(f"📁 File: {OUTPUT_FILE}")


def main():
    print("📊 Export 500 Nonprofits Without Websites")
    print("=" * 80)
    print()

    # Query database
    rows = export_nonprofits()

    if not rows:
        print("❌ No data retrieved!")
        return 1

    # Save to CSV
    save_to_csv(rows)

    print("\n" + "=" * 80)
    print("✅ Export complete!")
    print("\nYou can now add websites and classifications to the CSV.")
    print("When ready, I'll update the database with your changes.")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    sys.exit(main())
