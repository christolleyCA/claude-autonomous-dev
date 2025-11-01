#!/usr/bin/env python3
"""
Import 50k Classifications - handles "public-facing=true/false" format
"""

import csv
import sys
import subprocess
from pathlib import Path

# Input file
INPUT_FILE = Path.home() / "Downloads" / "processed_50k_classified.csv"

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"


def load_csv():
    """Load classifications from CSV"""
    print(f"📂 Loading {INPUT_FILE.name}...")

    classifications = {}
    total_rows = 0
    skipped = 0

    with open(INPUT_FILE, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)

        for row in reader:
            total_rows += 1

            ein = row.get('EIN', '').strip()
            if not ein:
                skipped += 1
                continue

            classification = row.get('Classification', '').strip().lower()

            # Parse "public-facing=true" or "public-facing=false"
            if 'true' in classification:
                public_facing = True
            elif 'false' in classification:
                public_facing = False
            else:
                skipped += 1
                continue

            website = row.get('Website', '') or ''
            website = website.strip()

            classifications[ein] = {
                'public_facing': public_facing,
                'website': website if website else None
            }

            if total_rows % 1000 == 0:
                print(f"   Progress: {total_rows:,} rows processed...")

    print(f"   ✅ Loaded {len(classifications):,} classifications")
    if skipped > 0:
        print(f"   ⚠️  Skipped {skipped:,} invalid rows")

    return classifications


def apply_updates_batch(classifications):
    """Apply updates in batches for speed"""
    print(f"\n⚡ Applying {len(classifications):,} updates...")

    # Split into batches of 100
    ein_list = list(classifications.items())
    batch_size = 100
    total_batches = (len(ein_list) + batch_size - 1) // batch_size

    success_count = 0

    for batch_num in range(total_batches):
        start_idx = batch_num * batch_size
        end_idx = min(start_idx + batch_size, len(ein_list))
        batch = ein_list[start_idx:end_idx]

        # Build batch SQL
        updates = []
        for ein, data in batch:
            public_facing = data['public_facing']
            website = data['website']

            if website:
                website_escaped = website.replace("'", "''")
                sql = f"UPDATE nonprofits SET website = '{website_escaped}', public_facing = {public_facing}, updated_at = NOW() WHERE ein_charity_number = '{ein}';"
            else:
                sql = f"UPDATE nonprofits SET public_facing = {public_facing}, updated_at = NOW() WHERE ein_charity_number = '{ein}';"

            updates.append(sql)

        # Execute batch
        batch_sql = "BEGIN;\n" + "\n".join(updates) + "\nCOMMIT;"

        try:
            result = subprocess.run(
                [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
                 '-c', batch_sql, '-q'],
                env={'PGPASSWORD': DB_PASSWORD},
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.returncode == 0:
                success_count += len(batch)
                if (batch_num + 1) % 50 == 0:
                    print(f"   Progress: {batch_num + 1}/{total_batches} batches ({success_count:,} records)")

        except Exception as e:
            pass

    print(f"\n   ✅ Successfully updated: {success_count:,}")
    return success_count


def main():
    print("🚀 Import 50k Classifications (public-facing=true/false format)")
    print("=" * 80)
    print()

    # Load CSV
    classifications = load_csv()

    if not classifications:
        print("\n❌ No classifications found!")
        return 1

    # Apply updates
    success_count = apply_updates_batch(classifications)

    print()
    print("=" * 80)
    print("✅ Import complete!")
    print(f"   Updated {success_count:,} nonprofits in database")
    print()
    print("💡 Check results:")
    print("   ~/check-classification-progress.sh")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    sys.exit(main())
