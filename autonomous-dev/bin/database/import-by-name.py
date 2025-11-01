#!/usr/bin/env python3
"""
Import classifications by matching organization NAME
- Maps "public-facing" → TRUE
- Maps "internal corporate benefit trusts" → FALSE
"""

import csv
import sys
import subprocess
from pathlib import Path

# Input file
INPUT_FILE = Path.home() / "Downloads" / "500 processed for upload to supabase oct 27.csv"

# Output
OUTPUT_DIR = Path.home() / "nonprofit_classification_updates"
OUTPUT_SQL = OUTPUT_DIR / "500_processed_oct27_updates.sql"

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

    classifications = []
    total_rows = 0
    classified_rows = 0
    skipped_rows = 0

    with open(INPUT_FILE, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)

        for row in reader:
            total_rows += 1

            # Get name (required)
            name = row.get('Name', '').strip()
            if not name:
                skipped_rows += 1
                continue

            # Get classification
            classification = row.get('Classification', '').strip().lower()

            # Map classification to boolean
            if classification == 'public-facing':
                public_facing = True
            elif classification == 'internal corporate benefit trusts':
                public_facing = False
            elif classification == '':
                # Check if website column has a value (some rows missing classification)
                website = row.get('Website', '').strip()
                if website:
                    # If there's a website but no classification, assume public-facing
                    public_facing = True
                else:
                    skipped_rows += 1
                    continue
            else:
                skipped_rows += 1
                continue

            # Get website (may be empty)
            website = row.get('Website', '').strip()

            classifications.append({
                'name': name,
                'public_facing': public_facing,
                'website': website if website else None
            })
            classified_rows += 1

    print(f"   ✅ Total rows: {total_rows:,}")
    print(f"   ✅ Classified: {classified_rows:,}")
    if skipped_rows > 0:
        print(f"   ⚠️  Skipped: {skipped_rows:,}")

    return classifications


def generate_sql(classifications):
    """Generate SQL UPDATE statements"""
    print(f"\n🔨 Generating UPDATE statements...")

    updates = []

    for data in classifications:
        name = data['name']
        public_facing = data['public_facing']
        website = data['website']

        # Escape single quotes
        name_escaped = name.replace("'", "''")

        # Build UPDATE statement
        if website:
            website_escaped = website.replace("'", "''")
            sql = f"""UPDATE nonprofits
SET website = '{website_escaped}',
    public_facing = {public_facing},
    updated_at = NOW()
WHERE UPPER(name) = UPPER('{name_escaped}');"""
        else:
            sql = f"""UPDATE nonprofits
SET public_facing = {public_facing},
    updated_at = NOW()
WHERE UPPER(name) = UPPER('{name_escaped}');"""

        updates.append(sql)

    print(f"   ✅ Generated {len(updates):,} UPDATE statements")
    return updates


def save_sql(updates):
    """Save SQL to file"""
    print(f"\n💾 Saving SQL to {OUTPUT_SQL.name}...")

    OUTPUT_DIR.mkdir(exist_ok=True)

    with open(OUTPUT_SQL, 'w') as f:
        f.write("-- Update nonprofits with 500 processed classifications\n")
        f.write("-- Matched by organization name\n")
        f.write(f"-- Total updates: {len(updates):,}\n\n")
        f.write("BEGIN;\n\n")

        for sql in updates:
            f.write(sql + "\n\n")

        f.write("COMMIT;\n")

    size_kb = OUTPUT_SQL.stat().st_size / 1024
    print(f"   ✅ Saved {len(updates):,} statements ({size_kb:.1f} KB)")
    print(f"   📁 Location: {OUTPUT_SQL}")


def apply_sql():
    """Apply SQL updates to database"""
    print(f"\n⚡ Applying updates to database...")

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-f', str(OUTPUT_SQL), '-q'],
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
    print("🔄 Import 500 Processed Classifications (Match by Name)")
    print("=" * 80)
    print()

    # Check if file exists
    if not INPUT_FILE.exists():
        print(f"❌ File not found: {INPUT_FILE}")
        return 1

    # Load CSV
    classifications = load_csv()

    if not classifications:
        print("\n❌ No classifications found!")
        return 1

    # Generate SQL
    updates = generate_sql(classifications)

    # Save SQL
    save_sql(updates)

    print()
    print("=" * 80)
    print("📝 Ready to apply!")
    print()
    print("⚠️  Note: Updates match by NAME (case-insensitive)")
    print("   Organizations with exact name matches will be updated")
    print()

    confirm = input("Apply these updates to database? (yes/no): ").strip().lower()

    if confirm == "yes":
        if apply_sql():
            print()
            print("=" * 80)
            print("✅ Import complete!")
            print(f"   Processed {len(classifications):,} organizations")
            print()
            print("💡 Check results:")
            print("   ./check-classification-progress.sh")
            print("=" * 80)
        else:
            return 1
    else:
        print("\n⏸️  Updates saved but not applied.")
        print(f"   SQL file: {OUTPUT_SQL}")
        print()
        print("To apply manually:")
        print(f"   psql -h {DB_HOST} -p {DB_PORT} -U {DB_USER} -d {DB_NAME} -f {OUTPUT_SQL}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
