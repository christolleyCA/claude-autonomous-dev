#!/usr/bin/env python3
"""
Export nonprofits needing public_facing classification to CSV
- Exports nonprofits where website is NOT NULL but public_facing IS NULL
- Creates batches for manual review and classification
"""

import csv
import sys
import subprocess
from pathlib import Path

# Configuration
BATCH_SIZE = 500  # Number of records per batch
OUTPUT_DIR = Path.home() / "nonprofit_classification_batches"

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"


def get_total_count():
    """Get total count of nonprofits needing classification"""
    print("🔍 Counting nonprofits needing classification...")

    sql = """
    SELECT COUNT(*)
    FROM nonprofits
    WHERE website IS NOT NULL
      AND public_facing IS NULL;
    """

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-t', '-A', '-c', sql],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=60
        )

        if result.returncode == 0:
            count = int(result.stdout.strip())
            print(f"✅ Found {count:,} nonprofits needing classification\n")
            return count
        else:
            print(f"❌ Query failed: {result.stderr}")
            return 0

    except Exception as e:
        print(f"❌ Error: {e}")
        return 0


def export_batch(batch_num, offset):
    """Export a single batch of nonprofits"""
    print(f"📦 Exporting batch {batch_num}...")

    sql = f"""
    SELECT
      ein_charity_number,
      name,
      website,
      contact_info->>'address' as address,
      contact_info->>'city' as city,
      contact_info->>'state' as state,
      contact_info->>'zip' as zip,
      annual_revenue,
      organization_type,
      country
    FROM nonprofits
    WHERE website IS NOT NULL
      AND public_facing IS NULL
    ORDER BY annual_revenue DESC NULLS LAST, ein_charity_number
    LIMIT {BATCH_SIZE} OFFSET {offset};
    """

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-t', '-A', '-F', '|', '-c', sql],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=120
        )

        if result.returncode == 0:
            rows = []
            for line in result.stdout.strip().split('\n'):
                if '|' in line:
                    parts = line.split('|')
                    if len(parts) >= 10:
                        rows.append({
                            'EIN': parts[0],
                            'Name': parts[1],
                            'Website': parts[2],
                            'Address': parts[3],
                            'City': parts[4],
                            'State': parts[5],
                            'ZIP': parts[6],
                            'Annual Revenue': parts[7],
                            'Organization Type': parts[8],
                            'Country': parts[9],
                            'Public Facing': ''  # Empty column for manual classification
                        })

            return rows
        else:
            print(f"❌ Query failed: {result.stderr}")
            return []

    except Exception as e:
        print(f"❌ Error: {e}")
        return []


def save_batch_to_csv(batch_num, rows):
    """Save batch to CSV file"""
    output_file = OUTPUT_DIR / f"batch_{batch_num:04d}.csv"

    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'EIN', 'Name', 'Website', 'Address', 'City', 'State', 'ZIP',
            'Annual Revenue', 'Organization Type', 'Country', 'Public Facing'
        ])
        writer.writeheader()
        writer.writerows(rows)

    print(f"   ✅ Saved {len(rows)} records to {output_file.name}")
    return output_file


def main():
    print("📊 Export Nonprofits for Public Facing Classification")
    print("=" * 80)
    print()

    # Create output directory
    OUTPUT_DIR.mkdir(exist_ok=True)
    print(f"📁 Output directory: {OUTPUT_DIR}\n")

    # Get total count
    total_count = get_total_count()

    if total_count == 0:
        print("❌ No records to export!")
        return 1

    # Calculate number of batches
    num_batches = (total_count + BATCH_SIZE - 1) // BATCH_SIZE
    print(f"📦 Creating {num_batches:,} batches of {BATCH_SIZE} records each\n")

    # Export batches
    exported_batches = []
    total_exported = 0

    for batch_num in range(1, num_batches + 1):
        offset = (batch_num - 1) * BATCH_SIZE

        rows = export_batch(batch_num, offset)

        if rows:
            output_file = save_batch_to_csv(batch_num, rows)
            exported_batches.append(output_file)
            total_exported += len(rows)

        # Status update every 10 batches
        if batch_num % 10 == 0:
            print(f"   📊 Progress: {batch_num}/{num_batches} batches ({total_exported:,} records)")

    print("\n" + "=" * 80)
    print(f"✅ Export complete!")
    print(f"\n📊 Summary:")
    print(f"   Total records: {total_count:,}")
    print(f"   Exported: {total_exported:,}")
    print(f"   Batches created: {len(exported_batches)}")
    print(f"   Location: {OUTPUT_DIR}")
    print("\n📝 Next steps:")
    print("   1. Open a batch CSV file")
    print("   2. Review the 'Website' column")
    print("   3. Mark 'Public Facing' as TRUE or FALSE:")
    print("      • TRUE = proper domain (example.org, example.com)")
    print("      • FALSE = social media, internal pages, malformed data")
    print("   4. Save the CSV")
    print("   5. Run update-classifications-from-csv.py to import")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    sys.exit(main())
