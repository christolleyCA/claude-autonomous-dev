#!/usr/bin/env python3
"""
Export a balanced sample template CSV with 20 nonprofits:
- 10 with public-facing=TRUE (real websites)
- 10 with public-facing=FALSE (social media/malformed)
"""

import csv
import sys
import subprocess
from pathlib import Path

# Output file
OUTPUT_FILE = Path.home() / "nonprofit_classification_template.csv"

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"


def get_true_examples():
    """Get 10 nonprofits with public_facing=TRUE"""
    print("✅ Fetching 10 examples with Public-facing=TRUE (real websites)...")

    sql = """
    SELECT
      ein_charity_number,
      name,
      contact_info->>'city' as city,
      contact_info->>'state' as state,
      public_facing,
      website
    FROM nonprofits
    WHERE public_facing = TRUE
    ORDER BY annual_revenue DESC NULLS LAST
    LIMIT 10;
    """

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-t', '-A', '-F', '|', '-c', sql],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=60
        )

        if result.returncode == 0:
            rows = []
            for line in result.stdout.strip().split('\n'):
                if '|' in line:
                    parts = line.split('|')
                    if len(parts) >= 6:
                        rows.append({
                            'EIN': parts[0],
                            'Name': parts[1],
                            'City': parts[2],
                            'State': parts[3],
                            'Public-facing': 'TRUE',
                            'Website': parts[5]
                        })

            print(f"   ✅ Found {len(rows)} TRUE examples")
            return rows
        else:
            print(f"   ❌ Query failed: {result.stderr}")
            return []

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return []


def get_false_examples():
    """Get 10 nonprofits with public_facing=FALSE"""
    print("❌ Fetching 10 examples with Public-facing=FALSE (social/malformed)...")

    sql = """
    SELECT
      ein_charity_number,
      name,
      contact_info->>'city' as city,
      contact_info->>'state' as state,
      public_facing,
      website
    FROM nonprofits
    WHERE public_facing = FALSE
    ORDER BY annual_revenue DESC NULLS LAST
    LIMIT 10;
    """

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-t', '-A', '-F', '|', '-c', sql],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=60
        )

        if result.returncode == 0:
            rows = []
            for line in result.stdout.strip().split('\n'):
                if '|' in line:
                    parts = line.split('|')
                    if len(parts) >= 6:
                        rows.append({
                            'EIN': parts[0],
                            'Name': parts[1],
                            'City': parts[2],
                            'State': parts[3],
                            'Public-facing': 'FALSE',
                            'Website': parts[5]
                        })

            print(f"   ✅ Found {len(rows)} FALSE examples")
            return rows
        else:
            print(f"   ❌ Query failed: {result.stderr}")
            return []

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return []


def save_template(true_rows, false_rows):
    """Save template CSV with balanced TRUE/FALSE examples"""
    print(f"💾 Creating balanced template file: {OUTPUT_FILE.name}...")

    all_rows = true_rows + false_rows

    with open(OUTPUT_FILE, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'EIN', 'Name', 'City', 'State', 'Public-facing', 'Website'
        ])
        writer.writeheader()
        writer.writerows(all_rows)

    size_kb = OUTPUT_FILE.stat().st_size / 1024
    print(f"   ✅ Saved {len(all_rows)} records ({size_kb:.1f} KB)")
    print(f"   📁 Location: {OUTPUT_FILE}")


def main():
    print("📝 Create Balanced Nonprofit Classification Template")
    print("=" * 80)
    print()

    # Get TRUE examples (10 with real websites)
    true_examples = get_true_examples()

    # Get FALSE examples (10 with social/malformed)
    false_examples = get_false_examples()

    if not true_examples or not false_examples:
        print("\n⚠️  Warning: Could not fetch balanced examples")
        if not true_examples and not false_examples:
            print("❌ No data retrieved!")
            return 1

    print()

    # Save template
    save_template(true_examples, false_examples)

    print()
    print("=" * 80)
    print("✅ Balanced template created!")
    print()
    print("📊 Template structure:")
    print(f"   • First 10 rows:   Public-facing=TRUE  (real organizational websites)")
    print(f"   • Last 10 rows:    Public-facing=FALSE (social media/malformed data)")
    print()
    print("✅ Public-facing=TRUE examples include:")
    print("   • Proper domains: example.org, www.example.com")
    print("   • Full URLs: https://organization.org")
    print("   • Real organizational websites")
    print()
    print("❌ Public-facing=FALSE examples include:")
    print("   • Social media handles: @username")
    print("   • Social profiles: facebook.com/page")
    print("   • Internal paths: /about, //subdomain")
    print("   • Malformed data: quoted strings, fragments")
    print()
    print("📝 Use this template to understand:")
    print("   • What makes a website 'public-facing' vs not")
    print("   • How to classify the 100,000 records in your batch files")
    print("   • The difference between TRUE and FALSE classifications")
    print()
    print("💡 Next steps:")
    print("   1. Open: ~/nonprofit_classification_template.csv")
    print("   2. Study the TRUE examples (rows 1-10)")
    print("   3. Study the FALSE examples (rows 11-20)")
    print("   4. Apply this logic to your 50k batch files")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    sys.exit(main())
