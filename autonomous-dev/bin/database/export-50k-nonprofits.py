#!/usr/bin/env python3
"""
Export two CSV files of 50,000 nonprofits each for classification
- Simple format: EIN, Name, City, State, Website, Public Facing
"""

import csv
import sys
import subprocess
from pathlib import Path

# Output files
OUTPUT_FILE_1 = Path.home() / "nonprofits_batch_1_50k.csv"
OUTPUT_FILE_2 = Path.home() / "nonprofits_batch_2_50k.csv"

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"


def export_batch(batch_num, offset, output_file):
    """Export 50,000 nonprofits to CSV"""
    print(f"📦 Exporting batch {batch_num} (records {offset+1:,} to {offset+50000:,})...")

    sql = f"""
    SELECT
      ein_charity_number,
      name,
      contact_info->>'city' as city,
      contact_info->>'state' as state,
      website,
      public_facing
    FROM nonprofits
    WHERE website IS NOT NULL
      AND public_facing IS NULL
    ORDER BY annual_revenue DESC NULLS LAST, ein_charity_number
    LIMIT 50000 OFFSET {offset};
    """

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-t', '-A', '-F', '|', '-c', sql],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=180
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
                            'Website': parts[4],
                            'Public Facing': parts[5] if parts[5] else ''  # Empty if NULL
                        })

            print(f"   ✅ Retrieved {len(rows):,} records")
            return rows
        else:
            print(f"   ❌ Query failed: {result.stderr}")
            return []

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return []


def save_to_csv(rows, output_file):
    """Save rows to CSV file"""
    print(f"💾 Saving to {output_file.name}...")

    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'EIN', 'Name', 'City', 'State', 'Website', 'Public Facing'
        ])
        writer.writeheader()
        writer.writerows(rows)

    size_mb = output_file.stat().st_size / 1024 / 1024
    print(f"   ✅ Saved {len(rows):,} records ({size_mb:.1f} MB)")
    print(f"   📁 Location: {output_file}")


def main():
    print("📊 Export 100,000 Nonprofits for Classification (2 files of 50k each)")
    print("=" * 80)
    print()

    # Export batch 1 (records 1-50,000)
    print("🔹 BATCH 1")
    rows_1 = export_batch(1, 0, OUTPUT_FILE_1)

    if rows_1:
        save_to_csv(rows_1, OUTPUT_FILE_1)
    else:
        print("❌ Batch 1 failed!")
        return 1

    print()

    # Export batch 2 (records 50,001-100,000)
    print("🔹 BATCH 2")
    rows_2 = export_batch(2, 50000, OUTPUT_FILE_2)

    if rows_2:
        save_to_csv(rows_2, OUTPUT_FILE_2)
    else:
        print("❌ Batch 2 failed!")
        return 1

    print()
    print("=" * 80)
    print("✅ Export complete!")
    print()
    print("📊 Summary:")
    print(f"   Batch 1: {len(rows_1):,} records → {OUTPUT_FILE_1}")
    print(f"   Batch 2: {len(rows_2):,} records → {OUTPUT_FILE_2}")
    print(f"   Total:   {len(rows_1) + len(rows_2):,} records")
    print()
    print("📝 Next steps:")
    print("   1. Open each CSV file")
    print("   2. Review the 'Website' column")
    print("   3. Fill in 'Public Facing' with TRUE or FALSE")
    print("   4. Save the CSV files")
    print("   5. Run: python3 update-50k-classifications.py")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    sys.exit(main())
