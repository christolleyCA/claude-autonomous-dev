#!/usr/bin/env python3
"""
Batch Import CSV/TXT Files - Night Oct 28
Handles CSV formatting issues with quotes
"""

import csv
import subprocess
import time
from pathlib import Path

# Configuration
INPUT_FOLDER = Path.home() / "Downloads" / "CSV Files to Process Oct 28" / "CSV's ready to upload to db Night Oct 28"

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"


def get_db_stats():
    """Get current database statistics"""
    sql = """
    SELECT
        COUNT(*) as total,
        COUNT(CASE WHEN public_facing = TRUE THEN 1 END) as public_facing_true,
        COUNT(CASE WHEN public_facing = FALSE THEN 1 END) as public_facing_false,
        COUNT(CASE WHEN public_facing IS NOT NULL THEN 1 END) as total_classified,
        COUNT(CASE WHEN website IS NOT NULL AND LENGTH(TRIM(website)) > 0 THEN 1 END) as has_website,
        COUNT(CASE WHEN website IS NULL OR LENGTH(TRIM(website)) = 0 THEN 1 END) as no_website,
        COUNT(CASE WHEN public_facing IS NULL THEN 1 END) as no_classification
    FROM nonprofits;
    """

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-t', '-A', '-F', '|', '-c', sql],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=30
        )

        if result.returncode == 0:
            parts = result.stdout.strip().split('|')
            return {
                'total': int(parts[0]),
                'public_facing_true': int(parts[1]),
                'public_facing_false': int(parts[2]),
                'total_classified': int(parts[3]),
                'has_website': int(parts[4]),
                'no_website': int(parts[5]),
                'no_classification': int(parts[6])
            }
    except Exception as e:
        print(f"   ❌ Error getting stats: {e}")

    return None


def analyze_file(file_path):
    """Analyze file contents"""
    print(f"📊 Analyzing file: {file_path.name}")

    stats = {
        'total_rows': 0,
        'has_classification': 0,
        'no_classification': 0,
        'public_facing_true': 0,
        'public_facing_false': 0,
        'has_website': 0,
        'no_website': 0,
        'valid_for_import': 0
    }

    try:
        with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
            # Skip header line
            header = f.readline()

            reader = csv.reader(f)

            for row in reader:
                if len(row) < 5:  # Need at least EIN, Name, City, State, Public-facing
                    continue

                stats['total_rows'] += 1

                ein = row[0].strip()
                if not ein:
                    continue

                # Public-facing is usually at index 4 (0-indexed: EIN, Name, City, State, Public-facing, Website)
                public_facing_idx = 4
                if len(row) > public_facing_idx:
                    classification = str(row[public_facing_idx]).strip().lower()

                    if 'true' in classification:
                        stats['has_classification'] += 1
                        stats['public_facing_true'] += 1
                        stats['valid_for_import'] += 1
                    elif 'false' in classification:
                        stats['has_classification'] += 1
                        stats['public_facing_false'] += 1
                        stats['valid_for_import'] += 1
                    else:
                        stats['no_classification'] += 1

                # Website is at index 5
                website_idx = 5
                if len(row) > website_idx:
                    website = row[website_idx].strip()
                    if website and len(website) > 0:
                        stats['has_website'] += 1
                    else:
                        stats['no_website'] += 1
                else:
                    stats['no_website'] += 1

    except Exception as e:
        print(f"   ❌ Error analyzing file: {e}")
        return None

    return stats


def import_file(file_path):
    """Import file to database"""
    print(f"⚡ Importing data from: {file_path.name}")

    classifications = {}
    skipped = 0

    try:
        with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
            # Skip header
            header = f.readline()

            reader = csv.reader(f)

            for row in reader:
                if len(row) < 5:
                    skipped += 1
                    continue

                ein = row[0].strip()
                if not ein:
                    skipped += 1
                    continue

                # Get classification (index 4)
                public_facing_idx = 4
                if len(row) > public_facing_idx:
                    classification = str(row[public_facing_idx]).strip().lower()

                    if 'true' in classification:
                        public_facing = True
                    elif 'false' in classification:
                        public_facing = False
                    else:
                        skipped += 1
                        continue
                else:
                    skipped += 1
                    continue

                # Get website (index 5)
                website = ''
                website_idx = 5
                if len(row) > website_idx:
                    website = row[website_idx].strip()

                classifications[ein] = {
                    'public_facing': public_facing,
                    'website': website if website else None
                }

    except Exception as e:
        print(f"   ❌ Error reading file: {e}")
        return 0

    if not classifications:
        print(f"   ⚠️  No valid data to import (skipped {skipped} rows)")
        return 0

    # Import in batches
    ein_list = list(classifications.items())
    batch_size = 100
    total_batches = (len(ein_list) + batch_size - 1) // batch_size
    success_count = 0

    print(f"   Processing {len(classifications):,} records in {total_batches} batches...")

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

        except Exception:
            pass

    print(f"   ✅ Successfully imported: {success_count:,} records")
    return success_count


def print_stats_summary(title, stats):
    """Print formatted statistics"""
    print()
    print("=" * 80)
    print(title)
    print("=" * 80)
    print(f"  Total nonprofits:           {stats['total']:>10,}")
    print()
    print(f"  Classified (total):         {stats['total_classified']:>10,}")
    print(f"    - Public-facing (TRUE):   {stats['public_facing_true']:>10,}")
    print(f"    - Not public (FALSE):     {stats['public_facing_false']:>10,}")
    print(f"  Unclassified:               {stats['no_classification']:>10,}")
    print()
    print(f"  With websites:              {stats['has_website']:>10,}")
    print(f"  Without websites:           {stats['no_website']:>10,}")
    print()
    percent = (stats['total_classified'] / stats['total'] * 100) if stats['total'] > 0 else 0
    print(f"  Classification progress:    {percent:>9.2f}%")
    print("=" * 80)


def print_file_summary(title, stats):
    """Print file analysis summary"""
    print()
    print("-" * 80)
    print(title)
    print("-" * 80)
    print(f"  Total rows:                 {stats['total_rows']:>10,}")
    print(f"  Valid for import:           {stats['valid_for_import']:>10,}")
    print()
    print(f"  With classification:        {stats['has_classification']:>10,}")
    print(f"    - Public-facing (TRUE):   {stats['public_facing_true']:>10,}")
    print(f"    - Not public (FALSE):     {stats['public_facing_false']:>10,}")
    print(f"  Without classification:     {stats['no_classification']:>10,}")
    print()
    print(f"  With websites:              {stats['has_website']:>10,}")
    print(f"  Without websites:           {stats['no_website']:>10,}")
    print("-" * 80)


def main():
    print("🚀 Batch Import - Night Oct 28")
    print("=" * 80)
    print()

    # Get list of files (CSV or TXT)
    files = sorted([f for f in INPUT_FOLDER.glob("*.txt") if not f.name.endswith('done.txt')])
    files += sorted([f for f in INPUT_FOLDER.glob("*.csv") if not f.name.endswith('done.csv')])

    if not files:
        print("❌ No files found to process!")
        return 1

    print(f"📁 Found {len(files)} file(s) to process:")
    for f in files:
        size_mb = f.stat().st_size / (1024 * 1024)
        print(f"   • {f.name} ({size_mb:.1f} MB)")

    # Get initial database stats
    print()
    print("📊 Fetching BEFORE database statistics...")
    before_stats = get_db_stats()

    if not before_stats:
        print("❌ Could not get database statistics!")
        return 1

    print_stats_summary("DATABASE STATISTICS - BEFORE IMPORT", before_stats)

    # Process each file
    total_imported = 0

    for idx, file_path in enumerate(files, 1):
        print()
        print("=" * 80)
        print(f"Processing File {idx}/{len(files)}: {file_path.name}")
        print("=" * 80)

        # Analyze file
        file_stats = analyze_file(file_path)
        if not file_stats:
            continue

        print_file_summary("FILE CONTENTS", file_stats)

        # Import file
        print()
        imported = import_file(file_path)
        total_imported += imported

        # Rename file
        if imported > 0:
            new_name = file_path.stem + " done" + file_path.suffix
            new_path = file_path.parent / new_name
            file_path.rename(new_path)
            print(f"   ✅ Renamed to: {new_name}")
        else:
            print(f"   ⚠️  File not renamed (no data imported)")

        # Small delay between files
        time.sleep(1)

    # Get final database stats
    print()
    print()
    print("📊 Fetching AFTER database statistics...")
    after_stats = get_db_stats()

    if after_stats:
        print_stats_summary("DATABASE STATISTICS - AFTER IMPORT", after_stats)

        # Calculate changes
        print()
        print("=" * 80)
        print("CHANGES")
        print("=" * 80)
        print(f"  Classified added:           {after_stats['total_classified'] - before_stats['total_classified']:>10,}")
        print(f"  Websites added:             {after_stats['has_website'] - before_stats['has_website']:>10,}")
        print(f"  Total records imported:     {total_imported:>10,}")
        print("=" * 80)

    print()
    print("✅ All files processed!")

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
