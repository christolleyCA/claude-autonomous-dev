#!/usr/bin/env python3
"""
Update public_facing classifications from CSV
- Reads CSV files with EIN and Public Facing columns
- Updates only the public_facing field in the database
- Supports batch processing
"""

import csv
import sys
import subprocess
from pathlib import Path

# Configuration
INPUT_DIR = Path.home() / "nonprofit_classification_batches"
OUTPUT_DIR = Path.home() / "nonprofit_classification_updates"

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"


def load_csv_batch(csv_file):
    """Load classifications from a CSV file"""
    print(f"📂 Loading {csv_file.name}...")

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

    print(f"   ✅ Found {classified_rows} classified records (out of {total_rows} total)")
    return classifications


def generate_update_sql(classifications):
    """Generate SQL UPDATE statements"""
    print(f"🔨 Generating UPDATE statements...")

    updates = []

    for ein, is_public_facing in classifications.items():
        sql = f"UPDATE nonprofits SET public_facing = {is_public_facing}, updated_at = NOW() WHERE ein_charity_number = '{ein}';"
        updates.append(sql)

    print(f"   ✅ Generated {len(updates):,} UPDATE statements")
    return updates


def save_sql_file(sql_statements, output_file):
    """Save SQL statements to file"""
    print(f"💾 Saving SQL to {output_file.name}...")

    with open(output_file, 'w') as f:
        f.write("-- Update public_facing classifications\n")
        f.write(f"-- Total updates: {len(sql_statements):,}\n")
        f.write("-- Generated from manually classified CSV data\n\n")

        f.write("BEGIN;\n\n")

        for sql in sql_statements:
            f.write(sql + "\n")

        f.write("\nCOMMIT;\n")

    size_kb = output_file.stat().st_size / 1024
    print(f"   ✅ Saved {len(sql_statements):,} statements ({size_kb:.1f}KB)")


def apply_updates(sql_file):
    """Apply SQL updates to database"""
    print(f"⚡ Applying updates to database...")

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-f', str(sql_file)],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=300
        )

        if result.returncode == 0:
            print(f"   ✅ Successfully applied updates")
            return True
        else:
            print(f"   ❌ Failed to apply updates: {result.stderr}")
            return False

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


def process_batch(csv_file, auto_apply=False):
    """Process a single CSV batch"""
    print(f"\n{'='*80}")
    print(f"Processing: {csv_file.name}")
    print(f"{'='*80}\n")

    # Load classifications
    classifications = load_csv_batch(csv_file)

    if not classifications:
        print("   ⚠️  No classifications found in this file\n")
        return 0

    # Generate SQL
    updates = generate_update_sql(classifications)

    # Save SQL file
    OUTPUT_DIR.mkdir(exist_ok=True)
    sql_file = OUTPUT_DIR / f"{csv_file.stem}_updates.sql"
    save_sql_file(updates, sql_file)

    # Apply updates if requested
    if auto_apply:
        if apply_updates(sql_file):
            return len(updates)
        else:
            return 0
    else:
        print(f"\n   📝 SQL file ready: {sql_file}")
        print(f"   💡 To apply: psql -f {sql_file}")
        return len(updates)


def main():
    print("🔄 Update Public Facing Classifications from CSV")
    print("=" * 80)
    print()

    # Check if input directory exists
    if not INPUT_DIR.exists():
        print(f"❌ Input directory not found: {INPUT_DIR}")
        return 1

    # Find all CSV files
    csv_files = sorted(INPUT_DIR.glob("batch_*.csv"))

    if not csv_files:
        print(f"❌ No batch CSV files found in: {INPUT_DIR}")
        return 1

    print(f"📁 Found {len(csv_files)} batch files\n")

    # Ask if user wants to auto-apply
    print("Choose mode:")
    print("1. Generate SQL files only (review before applying)")
    print("2. Generate and auto-apply to database")
    choice = input("\nEnter choice (1 or 2): ").strip()

    auto_apply = (choice == "2")

    if auto_apply:
        confirm = input("\n⚠️  This will immediately update the database. Continue? (yes/no): ").strip().lower()
        if confirm != "yes":
            print("Cancelled.")
            return 0

    # Process all batches
    total_updates = 0
    processed_batches = 0

    for csv_file in csv_files:
        num_updates = process_batch(csv_file, auto_apply)
        if num_updates > 0:
            total_updates += num_updates
            processed_batches += 1

    # Summary
    print("\n" + "=" * 80)
    print("✅ Processing complete!")
    print(f"\n📊 Summary:")
    print(f"   Batches processed: {processed_batches}/{len(csv_files)}")
    print(f"   Total classifications updated: {total_updates:,}")

    if auto_apply:
        print(f"   ✅ Updates applied to database")
    else:
        print(f"   📁 SQL files saved to: {OUTPUT_DIR}")
        print(f"\n💡 To apply updates manually:")
        print(f"   cd {OUTPUT_DIR}")
        print(f"   psql -h {DB_HOST} -p {DB_PORT} -U {DB_USER} -d {DB_NAME} -f <filename>.sql")

    print("=" * 80)

    return 0


if __name__ == "__main__":
    sys.exit(main())
