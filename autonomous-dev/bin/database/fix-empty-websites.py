#!/usr/bin/env python3
"""
Replace empty string websites with NULL values in batches
"""

import subprocess
import time
from pathlib import Path

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"


def get_count():
    """Get count of rows with empty websites"""
    sql = """
    SELECT COUNT(*)
    FROM nonprofits
    WHERE website = '' OR TRIM(website) = '';
    """

    result = subprocess.run(
        [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
         '-t', '-A', '-c', sql],
        env={'PGPASSWORD': DB_PASSWORD},
        capture_output=True,
        text=True,
        timeout=30
    )

    if result.returncode == 0:
        return int(result.stdout.strip())
    return 0


def update_batch(batch_size=10000):
    """Update one batch of empty websites to NULL"""
    sql = f"""
    UPDATE nonprofits
    SET website = NULL, updated_at = NOW()
    WHERE ein_charity_number IN (
        SELECT ein_charity_number
        FROM nonprofits
        WHERE website = '' OR TRIM(website) = ''
        LIMIT {batch_size}
    );
    """

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-c', sql, '-q'],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=60
        )

        return result.returncode == 0
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


def main():
    print("🔧 Replace Empty Website Strings with NULL")
    print("=" * 80)
    print()

    # Get initial count
    initial_count = get_count()
    print(f"📊 Found {initial_count:,} rows with empty website strings")
    print()

    if initial_count == 0:
        print("✅ No empty websites found!")
        return 0

    batch_size = 10000
    total_updated = 0
    batch_num = 0

    print(f"⚡ Updating in batches of {batch_size:,}...")
    print()

    while True:
        batch_num += 1
        remaining = get_count()

        if remaining == 0:
            break

        print(f"   Batch {batch_num}: Updating {min(batch_size, remaining):,} rows... ", end='', flush=True)

        if update_batch(batch_size):
            updated_this_batch = min(batch_size, remaining)
            total_updated += updated_this_batch
            print(f"✅ ({total_updated:,}/{initial_count:,} complete)")
        else:
            print("❌ Failed")
            break

        # Small delay to not overwhelm the database
        time.sleep(0.5)

    print()
    print("=" * 80)
    print("✅ Update complete!")
    print(f"   Updated {total_updated:,} rows")
    print(f"   Empty websites remaining: {get_count():,}")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
