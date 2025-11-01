#!/usr/bin/env python3
"""
Import Gemini CSV - handles space-separated format on one line
"""

import sys
import subprocess
from pathlib import Path

# Input file
INPUT_FILE = Path.home() / "Downloads" / "first part of 50k block 2 from gemini.csv"

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"


def parse_gemini_format():
    """Parse space-separated records on one line"""
    print(f"📂 Parsing {INPUT_FILE.name}...")

    with open(INPUT_FILE, 'r', encoding='utf-8', errors='replace') as f:
        content = f.read().strip()

    # Skip header
    if content.startswith('EIN,Name,Public-facing,Website '):
        content = content[len('EIN,Name,Public-facing,Website '):]

    # Split by space to get individual records
    # Each record is: EIN,Name,Public-facing,Website
    records = content.split(' ')

    classifications = {}
    skipped = 0

    for i, record in enumerate(records):
        if not record.strip():
            continue

        parts = record.split(',')
        if len(parts) < 3:
            skipped += 1
            continue

        ein = parts[0].strip()
        # Name is parts[1] (we don't need it for update)
        public_facing_str = parts[2].strip() if len(parts) > 2 else ''
        website = parts[3].strip() if len(parts) > 3 else ''

        if not ein:
            skipped += 1
            continue

        if public_facing_str.lower() == 'true':
            public_facing = True
        elif public_facing_str.lower() == 'false':
            public_facing = False
        else:
            skipped += 1
            continue

        classifications[ein] = {
            'public_facing': public_facing,
            'website': website if website else None
        }

        if (i + 1) % 100 == 0:
            print(f"   Progress: {i + 1:,} records parsed...")

    print(f"   ✅ Parsed {len(classifications):,} valid classifications")
    if skipped > 0:
        print(f"   ⚠️  Skipped {skipped:,} invalid records")

    return classifications


def apply_updates_batch(classifications):
    """Apply updates in batches"""
    print(f"\n⚡ Applying {len(classifications):,} updates...")

    ein_list = list(classifications.items())
    batch_size = 50
    total_batches = (len(ein_list) + batch_size - 1) // batch_size

    success_count = 0

    for batch_num in range(total_batches):
        start_idx = batch_num * batch_size
        end_idx = min(start_idx + batch_size, len(ein_list))
        batch = ein_list[start_idx:end_idx]

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
                if (batch_num + 1) % 20 == 0:
                    print(f"   Progress: {batch_num + 1}/{total_batches} batches ({success_count:,} records)")

        except Exception as e:
            pass

    print(f"\n   ✅ Successfully updated: {success_count:,}")
    return success_count


def main():
    print("🚀 Import Gemini Classifications (Space-separated format)")
    print("=" * 80)
    print()

    # Parse file
    classifications = parse_gemini_format()

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
    print("   ./check-classification-progress.sh")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    sys.exit(main())
