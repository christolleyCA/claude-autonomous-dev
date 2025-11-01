#!/usr/bin/env python3
"""
Fast import: Match names to get EINs first, then update by EIN
"""

import csv
import sys
import subprocess
from pathlib import Path

# Input file
INPUT_FILE = Path.home() / "Downloads" / "500 processed for upload to supabase oct 27.csv"

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

    with open(INPUT_FILE, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)

        for row in reader:
            total_rows += 1
            name = row.get('Name', '').strip()
            if not name:
                continue

            classification = row.get('Classification', '') or ''
            classification = classification.strip().lower()

            website = row.get('Website', '') or ''
            website = website.strip()

            if classification == 'public-facing':
                public_facing = True
            elif classification == 'internal corporate benefit trusts':
                public_facing = False
            elif website:
                # If there's a website but no classification, assume public-facing
                public_facing = True
            else:
                continue

            # Use uppercase name as key for matching
            name_upper = name.upper()
            classifications[name_upper] = {
                'name': name,
                'public_facing': public_facing,
                'website': website if website else None
            }

    print(f"   ✅ Loaded {len(classifications):,} organizations to classify")
    return classifications


def match_names_to_eins(classifications):
    """Query database to match names to EINs"""
    print(f"\n🔍 Matching organization names to EINs...")

    # Build WHERE clause with all names
    names_list = list(classifications.keys())
    names_sql = "', '".join([n.replace("'", "''") for n in names_list])

    sql = f"""
    SELECT ein_charity_number, UPPER(name) as name_upper
    FROM nonprofits
    WHERE UPPER(name) IN ('{names_sql}');
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
            matches = {}
            for line in result.stdout.strip().split('\n'):
                if '|' in line:
                    parts = line.split('|')
                    if len(parts) >= 2:
                        ein = parts[0].strip()
                        name_upper = parts[1].strip()
                        if name_upper in classifications:
                            matches[ein] = classifications[name_upper]

            print(f"   ✅ Matched {len(matches):,} organizations")
            print(f"   ⚠️  Unmatched: {len(classifications) - len(matches):,}")
            return matches
        else:
            print(f"   ❌ Query failed: {result.stderr}")
            return {}

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return {}


def apply_updates(ein_matches):
    """Apply updates by EIN (fast)"""
    print(f"\n⚡ Applying {len(ein_matches):,} updates by EIN...")

    success_count = 0
    error_count = 0

    for ein, data in ein_matches.items():
        public_facing = data['public_facing']
        website = data['website']

        # Build UPDATE statement
        if website:
            website_escaped = website.replace("'", "''")
            sql = f"UPDATE nonprofits SET website = '{website_escaped}', public_facing = {public_facing}, updated_at = NOW() WHERE ein_charity_number = '{ein}';"
        else:
            sql = f"UPDATE nonprofits SET public_facing = {public_facing}, updated_at = NOW() WHERE ein_charity_number = '{ein}';"

        try:
            result = subprocess.run(
                [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
                 '-c', sql, '-q'],
                env={'PGPASSWORD': DB_PASSWORD},
                capture_output=True,
                text=True,
                timeout=10
            )

            if result.returncode == 0:
                success_count += 1
                if success_count % 50 == 0:
                    print(f"   Progress: {success_count}/{len(ein_matches)}")
            else:
                error_count += 1

        except Exception as e:
            error_count += 1

    print(f"\n   ✅ Successfully updated: {success_count:,}")
    if error_count > 0:
        print(f"   ❌ Errors: {error_count}")

    return success_count


def main():
    print("🚀 Fast Import (Match Names → Get EINs → Update by EIN)")
    print("=" * 80)
    print()

    # Load CSV
    classifications = load_csv()

    if not classifications:
        print("❌ No classifications found!")
        return 1

    # Match names to EINs
    ein_matches = match_names_to_eins(classifications)

    if not ein_matches:
        print("\n❌ No matches found!")
        return 1

    # Apply updates
    success_count = apply_updates(ein_matches)

    print()
    print("=" * 80)
    print("✅ Import complete!")
    print(f"   Updated {success_count:,} organizations in database")
    print()
    print("💡 Check results:")
    print("   ./check-classification-progress.sh")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    sys.exit(main())
