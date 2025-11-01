#!/usr/bin/env python3
"""
Import processed CSV file with classifications
- Works with any CSV file containing: EIN, Website, Public-facing columns
- Flexible - handles various CSV formats
"""

import csv
import sys
import subprocess
from pathlib import Path
import argparse

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"


def load_csv(csv_file):
    """Load classifications from CSV file"""
    print(f"📂 Loading {csv_file.name}...")

    if not csv_file.exists():
        print(f"   ❌ File not found: {csv_file}")
        return {}

    classifications = {}
    total_rows = 0
    classified_rows = 0
    skipped_rows = 0

    with open(csv_file, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)

        for row in reader:
            total_rows += 1

            # Get EIN (required)
            ein = row.get('EIN', '').strip()
            if not ein:
                skipped_rows += 1
                continue

            # Get Public-facing value
            public_facing_value = row.get('Public-facing', '').strip().upper()

            # Skip if not classified
            if not public_facing_value or public_facing_value not in ['TRUE', 'FALSE']:
                skipped_rows += 1
                continue

            # Get website (may be empty)
            website = row.get('Website', '').strip()

            classifications[ein] = {
                'public_facing': (public_facing_value == 'TRUE'),
                'website': website if website else None
            }
            classified_rows += 1

    print(f"   ✅ Total rows: {total_rows:,}")
    print(f"   ✅ Classified: {classified_rows:,}")
    print(f"   ⚠️  Skipped: {skipped_rows:,} (missing EIN or Public-facing)")
    return classifications


def generate_sql(classifications):
    """Generate SQL UPDATE statements"""
    print(f"\n🔨 Generating UPDATE statements...")

    updates = []

    for ein, data in classifications.items():
        public_facing = data['public_facing']
        website = data['website']

        # Escape single quotes in website
        if website:
            website_escaped = website.replace("'", "''")
            sql = f"UPDATE nonprofits SET website = '{website_escaped}', public_facing = {public_facing}, updated_at = NOW() WHERE ein_charity_number = '{ein}';"
        else:
            sql = f"UPDATE nonprofits SET public_facing = {public_facing}, updated_at = NOW() WHERE ein_charity_number = '{ein}';"

        updates.append(sql)

    print(f"   ✅ Generated {len(updates):,} UPDATE statements")
    return updates


def save_sql(updates, output_file):
    """Save SQL to file"""
    print(f"\n💾 Saving SQL to {output_file.name}...")

    with open(output_file, 'w') as f:
        f.write("-- Update nonprofits with processed classifications\n")
        f.write(f"-- Total updates: {len(updates):,}\n\n")
        f.write("BEGIN;\n\n")

        for sql in updates:
            f.write(sql + "\n")

        f.write("\nCOMMIT;\n")

    size_kb = output_file.stat().st_size / 1024
    print(f"   ✅ Saved {len(updates):,} statements ({size_kb:.1f} KB)")


def apply_sql(sql_file):
    """Apply SQL updates to database"""
    print(f"\n⚡ Applying updates to database...")

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-f', str(sql_file)],
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
    parser = argparse.ArgumentParser(description='Import processed CSV classifications to database')
    parser.add_argument('csv_file', help='Path to CSV file with processed classifications')
    parser.add_argument('--apply', action='store_true', help='Apply updates to database immediately')
    args = parser.parse_args()

    csv_path = Path(args.csv_file)

    print("🔄 Import Processed Classifications from CSV")
    print("=" * 80)
    print()

    # Load CSV
    classifications = load_csv(csv_path)

    if not classifications:
        print("\n❌ No classifications found!")
        print("\n💡 Make sure your CSV has:")
        print("   • EIN column (required)")
        print("   • Public-facing column with TRUE or FALSE (required)")
        print("   • Website column (optional)")
        return 1

    # Generate SQL
    updates = generate_sql(classifications)

    # Prepare output file
    output_dir = Path.home() / "nonprofit_classification_updates"
    output_dir.mkdir(exist_ok=True)
    output_file = output_dir / f"{csv_path.stem}_updates.sql"

    # Save SQL
    save_sql(updates, output_file)

    print()

    # Apply or prompt
    if args.apply:
        print("🚀 Applying to database (--apply flag detected)...")
        if apply_sql(output_file):
            print()
            print("=" * 80)
            print("✅ Import complete!")
            print(f"   Updated {len(classifications):,} nonprofits in database")
            print("=" * 80)
        else:
            return 1
    else:
        print("📝 SQL file saved. Choose next step:")
        print()
        print("Option 1 - Review SQL file:")
        print(f"   cat {output_file}")
        print()
        print("Option 2 - Apply now:")
        print(f"   python3 {__file__} '{csv_path}' --apply")
        print()
        print("Option 3 - Apply manually:")
        print(f"   psql -h {DB_HOST} -p {DB_PORT} -U {DB_USER} -d {DB_NAME} -f {output_file}")
        print()
        print("=" * 80)

    return 0


if __name__ == "__main__":
    sys.exit(main())
