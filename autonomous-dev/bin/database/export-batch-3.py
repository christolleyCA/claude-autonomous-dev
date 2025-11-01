#!/usr/bin/env python3
"""
Export 50k Batch 3 - Unprocessed nonprofits
"""

import subprocess
from pathlib import Path

# Output file
OUTPUT_DIR = Path.home() / "Downloads"
OUTPUT_FILE = OUTPUT_DIR / "50k batch 3 unprocessed.csv"

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"


def export_batch():
    """Export 50,000 unprocessed nonprofits to CSV"""
    print("📂 Exporting 50k Batch 3 (Unprocessed)...")
    print("=" * 80)
    print()

    sql = """
    COPY (
        SELECT ein_charity_number AS "EIN",
               name AS "Name",
               contact_info->>'city' AS "City",
               contact_info->>'state' AS "State",
               CASE
                   WHEN public_facing = TRUE THEN 'public-facing=true'
                   WHEN public_facing = FALSE THEN 'public-facing=false'
                   ELSE ''
               END AS "Classification",
               website AS "Website"
        FROM nonprofits
        WHERE website IS NOT NULL AND public_facing IS NULL
        ORDER BY annual_revenue DESC NULLS LAST, ein_charity_number
        LIMIT 50000
    ) TO STDOUT WITH CSV HEADER;
    """

    try:
        print(f"🔍 Querying database for 50,000 unprocessed records...")

        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-c', sql],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=180
        )

        if result.returncode == 0:
            # Write output to file
            with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
                f.write(result.stdout)

            # Get file stats
            size_mb = OUTPUT_FILE.stat().st_size / (1024 * 1024)
            line_count = len(result.stdout.strip().split('\n'))

            print(f"   ✅ Export successful!")
            print(f"   📁 File: {OUTPUT_FILE.name}")
            print(f"   📊 Records: {line_count - 1:,}")
            print(f"   💾 Size: {size_mb:.1f} MB")
            print()
            print(f"Full path: {OUTPUT_FILE}")
            return True
        else:
            print(f"   ❌ Export failed: {result.stderr}")
            return False

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


def main():
    print("🚀 Export 50k Batch 3 - Unprocessed Nonprofits")
    print("=" * 80)
    print()

    if export_batch():
        print()
        print("=" * 80)
        print("✅ Export complete!")
        print()
        print("💡 Next steps:")
        print("   1. Classify the nonprofits in the CSV file")
        print("   2. Import back using: python3 ~/import-50k-classified.py")
        print("=" * 80)
        return 0
    else:
        return 1


if __name__ == "__main__":
    import sys
    sys.exit(main())
