#!/usr/bin/env python3
"""
Update public_facing classifications from the 50k batch CSV files
"""

import csv
import sys
import subprocess
from pathlib import Path

# Input files
INPUT_FILE_1 = Path.home() / "nonprofits_batch_1_50k.csv"
INPUT_FILE_2 = Path.home() / "nonprofits_batch_2_50k.csv"

# Output SQL file
OUTPUT_DIR = Path.home() / "nonprofit_classification_updates"
OUTPUT_SQL = OUTPUT_DIR / "update_100k_classifications.sql"

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"


def load_classifications(csv_file):
    """Load classifications from CSV file"""
    print(f"📂 Loading {csv_file.name}...")

    if not csv_file.exists():
        print(f"   ⚠️  File not found!")
        return {}

    classifications = {}
    total_rows = 0
    classified_rows = 0

    with open(csv_file, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)

        for row in reader:
            total_rows += 1

            ein = row['EIN'].strip()
            public_facing_value = row['Public Facing'].strip().upper()

            # Skip if not classified
            if not public_facing_value or public_facing_value not in ['TRUE', 'FALSE']:
                continue

            classifications[ein] = (public_facing_value == 'TRUE')
            classified_rows += 1

    print(f"   ✅ Found {classified_rows:,} classified records (out of {total_rows:,} total)")
    return classifications


def generate_sql(all_classifications):
    """Generate SQL UPDATE statements"""
    print(f"🔨 Generating UPDATE statements...")

    updates = []

    for ein, is_public_facing in all_classifications.items():
        sql = f"UPDATE nonprofits SET public_facing = {is_public_facing}, updated_at = NOW() WHERE ein_charity_number = '{ein}';"
        updates.append(sql)

    print(f"   ✅ Generated {len(updates):,} UPDATE statements")
    return updates


def save_sql(updates):
    """Save SQL to file"""
    print(f"💾 Saving SQL to {OUTPUT_SQL.name}...")

    OUTPUT_DIR.mkdir(exist_ok=True)

    with open(OUTPUT_SQL, 'w') as f:
        f.write("-- Update public_facing classifications\n")
        f.write(f"-- Total updates: {len(updates):,}\n")
        f.write("-- Generated from 100k batch CSV files\n\n")
        f.write("BEGIN;\n\n")

        for sql in updates:
            f.write(sql + "\n")

        f.write("\nCOMMIT;\n")

    size_mb = OUTPUT_SQL.stat().st_size / 1024 / 1024
    print(f"   ✅ Saved {len(updates):,} statements ({size_mb:.1f} MB)")
    print(f"   📁 Location: {OUTPUT_SQL}")


def apply_updates():
    """Apply SQL updates to database"""
    print(f"\n⚡ Applying updates to database...")

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-f', str(OUTPUT_SQL)],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=600
        )

        if result.returncode == 0:
            print(f"   ✅ Successfully applied updates to database")
            return True
        else:
            print(f"   ❌ Failed: {result.stderr}")
            return False

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


def main():
    print("🔄 Update Classifications from 50k Batch Files")
    print("=" * 80)
    print()

    # Load classifications from both files
    print("📂 Loading classifications from both files...")
    all_classifications = {}

    classifications_1 = load_classifications(INPUT_FILE_1)
    all_classifications.update(classifications_1)

    classifications_2 = load_classifications(INPUT_FILE_2)
    all_classifications.update(classifications_2)

    print()
    print(f"📊 Total classifications loaded: {len(all_classifications):,}")
    print()

    if not all_classifications:
        print("❌ No classifications found!")
        print()
        print("💡 Make sure you:")
        print("   1. Opened the CSV files")
        print("   2. Filled in the 'Public Facing' column with TRUE or FALSE")
        print("   3. Saved the files")
        return 1

    # Generate SQL
    updates = generate_sql(all_classifications)
    print()

    # Save SQL
    save_sql(updates)
    print()

    # Ask if user wants to apply
    print("Choose action:")
    print("1. Save SQL only (review before applying)")
    print("2. Save and apply to database now")
    choice = input("\nEnter choice (1 or 2): ").strip()

    if choice == "2":
        confirm = input("\n⚠️  This will update the database. Continue? (yes/no): ").strip().lower()
        if confirm == "yes":
            if apply_updates():
                print()
                print("=" * 80)
                print("✅ All done!")
                print(f"   Updated {len(all_classifications):,} nonprofits in database")
                print("=" * 80)
            else:
                return 1
        else:
            print("\nCancelled. SQL file saved for manual application.")
    else:
        print()
        print("=" * 80)
        print("✅ SQL file saved!")
        print()
        print("To apply manually:")
        print(f"   psql -h {DB_HOST} -p {DB_PORT} -U {DB_USER} -d {DB_NAME} -f {OUTPUT_SQL}")
        print("=" * 80)

    return 0


if __name__ == "__main__":
    sys.exit(main())
