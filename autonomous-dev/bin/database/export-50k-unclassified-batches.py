#!/usr/bin/env python3
"""
Export 50,000 nonprofits (no website, no classification) in batches of 500
"""

import csv
import subprocess
from pathlib import Path

# Configuration
OUTPUT_FOLDER = Path.home() / "Downloads" / "CSV Files to Process Oct 28"
BATCH_SIZE = 500
TOTAL_RECORDS = 50000

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"


def export_from_database():
    """Export 50,000 nonprofits from database"""
    print("🔍 Querying database for 50,000 unclassified nonprofits...")

    sql = f"""
    SELECT ein_charity_number,
           name,
           contact_info->>'city' as city,
           contact_info->>'state' as state
    FROM nonprofits
    WHERE (website IS NULL OR website = '' OR TRIM(website) = '')
      AND public_facing IS NULL
    ORDER BY annual_revenue DESC NULLS LAST, ein_charity_number
    LIMIT {TOTAL_RECORDS};
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
                    if len(parts) >= 4:
                        ein = parts[0].strip()
                        name = parts[1].strip()
                        city = parts[2].strip() if parts[2] else ''
                        state = parts[3].strip() if parts[3] else ''
                        rows.append({
                            'EIN': ein,
                            'Name': name,
                            'City': city,
                            'State': state,
                            'Public-facing': '',
                            'Website': ''
                        })

            print(f"   ✅ Retrieved {len(rows):,} records")
            return rows
        else:
            print(f"   ❌ Query failed: {result.stderr}")
            return []

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return []


def write_batch_files(rows):
    """Write rows to batch files"""
    print(f"\n✂️  Splitting into batches of {BATCH_SIZE} rows...")

    # Create output folder
    OUTPUT_FOLDER.mkdir(parents=True, exist_ok=True)

    num_batches = (len(rows) + BATCH_SIZE - 1) // BATCH_SIZE

    for batch_num in range(num_batches):
        start_idx = batch_num * BATCH_SIZE
        end_idx = min(start_idx + BATCH_SIZE, len(rows))
        batch_rows = rows[start_idx:end_idx]

        # Create filename
        filename = f"batch_{batch_num + 1:03d}_unclassified.csv"
        filepath = OUTPUT_FOLDER / filename

        # Write CSV
        with open(filepath, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=['EIN', 'Name', 'City', 'State', 'Public-facing', 'Website'])
            writer.writeheader()
            writer.writerows(batch_rows)

        size_kb = filepath.stat().st_size / 1024
        print(f"   ✅ {filename}: {len(batch_rows)} rows ({size_kb:.1f} KB)")

    return num_batches


def main():
    print("🚀 Export 50k Unclassified Nonprofits in Batches")
    print("=" * 80)
    print()
    print(f"📦 Batch size: {BATCH_SIZE} rows")
    print(f"📊 Total to export: {TOTAL_RECORDS:,} records")
    print(f"📁 Output folder: {OUTPUT_FOLDER}")
    print()

    # Export from database
    rows = export_from_database()

    if not rows:
        print("\n❌ No data retrieved!")
        return 1

    # Write batch files
    num_batches = write_batch_files(rows)

    print()
    print("=" * 80)
    print("✅ Export complete!")
    print(f"   Created {num_batches} batch files")
    print(f"   Total rows: {len(rows):,}")
    print(f"   Location: {OUTPUT_FOLDER}")
    print()
    print("💡 Each file contains:")
    print("   • Header: EIN,Name,City,State,Public-facing,Website")
    print("   • 500 rows (last batch may have fewer)")
    print("   • Empty Public-facing and Website columns")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
