#!/usr/bin/env python3
"""
Export and Classify Remaining Nonprofits
Part 1: Export nonprofits without classification and without websites
Part 2: Classify them based on name patterns
Part 3: Split into 1,000-row batches with prompts
"""

import csv
import subprocess
from pathlib import Path

# Configuration
OUTPUT_FOLDER = Path.home() / "Downloads" / "CSV Files to Process Oct 28" / "Rest of NFPs without classification or websites but with prompts"
EXPORT_CSV = OUTPUT_FOLDER / "Rest of the NFPs without classification and without websites Oct 30.csv"
BATCH_SIZE = 1000

# Database connection
DB_HOST = "aws-0-ca-central-1.pooler.supabase.com"
DB_PORT = "6543"
DB_USER = "postgres.hjtvtkffpziopozmtsnb"
DB_NAME = "postgres"
DB_PASSWORD = "Dharini1221su!"
PSQL = "/opt/homebrew/opt/postgresql@14/bin/psql"

# Classification keywords
NOT_PUBLIC_FACING_KEYWORDS = [
    'veba', 'benefit', 'benefits', 'plan', 'master trust', 'retire', 'retirees',
    'postretirement', 'post-retirement', 'insurance', 'reinsurance', 'sick leave',
    'vacation trust', 'life insurance', 'disability', 'apprenticeship', 'training trust',
    'teamsters', 'ibew', 'operating engineers', 'laborers', 'carpenters', 'sheet metal',
    'plumbers', 'electrical workers', 'security fund', 'trust fund', 'health & welfare',
    'health and welfare', 'welfare fund', 'pension', 'annuity', '401k', 'defined benefit'
]

PUBLIC_FACING_KEYWORDS = [
    'university', 'school', 'college', 'hospital', 'medical center', 'medical group',
    'clinic', 'health system', 'foundation', 'charitable foundation', 'donor-advised',
    'museum', 'library', 'public charity', 'community clinic', 'cooperative',
    'authority', 'transit', 'power', 'water', 'church', 'temple', 'synagogue',
    'ministry', 'mission', 'food bank', 'shelter', 'community center', 'ymca', 'ywca',
    'boys club', 'girls club', 'scouts', 'fire department', 'rescue', 'ambulance'
]

# The prompt to prepend to each batch
PROMPT_TEXT = """**Role**
You find and verify official websites for U.S. nonprofit organizations. You output the text as a properly formatted CSV file in a code box that can be easily copied and pasted.

---

## INPUT
A CSV dataset with 1,000 rows containing nonprofit information with columns:
EIN, Name, City, State, Public Facing, Website

---

## YOUR TASK
For rows where **Website is empty AND Public Facing = TRUE**:
1. Search the web for the organization's official website
2. Verify the website matches the organization
3. Add the verified URL to the Website column
4. Leave blank if no reliable official website exists

For rows where **Public Facing = FALSE**: Skip (no website search needed)

---

## WEBSITE SEARCH & VERIFICATION PROTOCOL

### Search Strategy
1. Search: `"[Organization Name]" [City] [State]` (optionally include EIN)
2. Look for the official domain (not directories or intermediaries)
3. For departments within larger institutions, find the specific program page

### Verification Checklist
✓ Site loads successfully (not 404)
✓ Name and location match the organization
✓ Appears to be the official domain (check About, footer, contact)
✓ For charities within companies, use specific program URL (e.g., `company.com/foundation`)

### What NOT to Use
✗ Third-party directories (GuideStar, Charity Navigator)
✗ Donation platforms or fundraising intermediaries
✗ Social media (unless no official site exists)
✗ Unrelated or suspicious domains

### URL Formatting
- Use HTTPS only
- Remove tracking parameters (UTM codes, etc.)
- Use clean, official domain format
- Facebook Page as last resort only if verified
- When uncertain, leave blank

---

## OUTPUT REQUIREMENTS

### CSV Format
- Valid CSV with proper escaping
- Text with commas wrapped in quotes
- Quotes escaped as `""`
- **DO NOT include header row** (EIN,Name,City,State,Public Facing,Website)
- Include these columns only: EIN, Name, City, State, Public Facing, Website
- Keep all original data exactly as provided

**Export as text in a properly formatted CSV in a code box for easy copy/paste**

---

## FINAL SUMMARY

After processing all 1,000 rows:

```
Summary:
Rows processed: [number]
Websites found: [number]
Already had websites: [number]
Left blank (no reliable site): [number]
Needs Review: [number]
```

### Needs Review Section
List any unclear/questionable websites:

```
Needs Review:
- [Organization Name] — [brief reason]
```

---

## EXECUTION RULES

**DO:**
- Search thoroughly before leaving blank
- Verify every URL loads and matches
- Use proper CSV escaping
- Preserve all original data exactly

**DO NOT:**
- Invent or guess URLs
- Use markdown formatting in CSV
- Modify organization names, addresses, or data
- Include commentary or filler text
- Add or remove rows

---

**The 1,000-row CSV data below (columns: EIN, Name, City, State, Public Facing, Website):**

"""


def export_from_database():
    """Part 1: Export nonprofits without classification and without websites"""
    print("=" * 80)
    print("PART 1: EXPORTING FROM DATABASE")
    print("=" * 80)
    print()
    print("🔍 Querying database for nonprofits without classification and without websites...")

    sql = """
    SELECT ein_charity_number,
           name,
           contact_info->>'city' as city,
           contact_info->>'state' as state,
           '' as public_facing,
           '' as website
    FROM nonprofits
    WHERE (website IS NULL OR website = '' OR TRIM(website) = '')
      AND public_facing IS NULL
    ORDER BY annual_revenue DESC NULLS LAST, ein_charity_number;
    """

    try:
        result = subprocess.run(
            [PSQL, '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-d', DB_NAME,
             '-t', '-A', '-F', '|', '-c', sql],
            env={'PGPASSWORD': DB_PASSWORD},
            capture_output=True,
            text=True,
            timeout=300
        )

        if result.returncode == 0:
            rows = []
            for line in result.stdout.strip().split('\n'):
                if '|' in line:
                    parts = line.split('|')
                    if len(parts) >= 6:
                        rows.append({
                            'EIN': parts[0].strip(),
                            'Name': parts[1].strip(),
                            'City': parts[2].strip() if parts[2] else '',
                            'State': parts[3].strip() if parts[3] else '',
                            'Public Facing': '',
                            'Website': ''
                        })

            print(f"   ✅ Retrieved {len(rows):,} records")
            return rows
        else:
            print(f"   ❌ Query failed: {result.stderr}")
            return []

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return []


def classify_nonprofit(name):
    """Classify a nonprofit as public-facing or not based on its name"""
    name_lower = name.lower()

    # Check for public-facing indicators
    public_facing_score = 0
    for keyword in PUBLIC_FACING_KEYWORDS:
        if keyword in name_lower:
            public_facing_score += 1

    # Check for not-public-facing indicators
    not_public_facing_score = 0
    for keyword in NOT_PUBLIC_FACING_KEYWORDS:
        if keyword in name_lower:
            not_public_facing_score += 1

    # If both appear, prefer public-facing (per requirements)
    if public_facing_score > 0:
        return True

    if not_public_facing_score > 0:
        return False

    # Default to public-facing if no clear indicators
    return True


def save_initial_export(rows):
    """Save the initial export before classification"""
    print()
    print("💾 Saving initial export...")

    # Create output folder
    OUTPUT_FOLDER.mkdir(parents=True, exist_ok=True)

    # Write CSV
    with open(EXPORT_CSV, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['EIN', 'Name', 'City', 'State', 'Public Facing', 'Website'])
        writer.writeheader()
        writer.writerows(rows)

    size_mb = EXPORT_CSV.stat().st_size / (1024 * 1024)
    print(f"   ✅ Saved: {EXPORT_CSV.name}")
    print(f"   📊 Records: {len(rows):,}")
    print(f"   💾 Size: {size_mb:.1f} MB")
    print(f"   📁 Location: {OUTPUT_FOLDER}")


def classify_and_batch(rows):
    """Part 2 & 3: Classify rows and create batches with prompts"""
    print()
    print("=" * 80)
    print("PART 2 & 3: CLASSIFICATION AND BATCH CREATION")
    print("=" * 80)
    print()

    # Classify all rows
    print("🤖 Classifying nonprofits based on name patterns...")
    classified_true = 0
    classified_false = 0

    for row in rows:
        classification = classify_nonprofit(row['Name'])
        row['Public Facing'] = str(classification)
        if classification:
            classified_true += 1
        else:
            classified_false += 1

    print(f"   ✅ Classified {len(rows):,} rows")
    print(f"      • Public-facing (True): {classified_true:,}")
    print(f"      • Not public (False): {classified_false:,}")

    # Create batches
    print()
    print(f"✂️  Creating batches of {BATCH_SIZE:,} rows...")
    print()

    num_batches = (len(rows) + BATCH_SIZE - 1) // BATCH_SIZE

    for batch_num in range(num_batches):
        start_idx = batch_num * BATCH_SIZE
        end_idx = min(start_idx + BATCH_SIZE, len(rows))
        batch_rows = rows[start_idx:end_idx]

        # Create filename
        filename = f"NFP classified, without websites, with prompts Batch {batch_num + 1}.txt"
        filepath = OUTPUT_FOLDER / filename

        # Write batch file with prompt
        with open(filepath, 'w', encoding='utf-8') as f:
            # Write prompt
            f.write(PROMPT_TEXT)
            f.write('\n')

            # Write CSV header
            f.write('EIN,Name,City,State,Public Facing,Website\n')

            # Write CSV rows
            writer = csv.DictWriter(f, fieldnames=['EIN', 'Name', 'City', 'State', 'Public Facing', 'Website'])
            writer.writerows(batch_rows)

        size_kb = filepath.stat().st_size / 1024
        print(f"   ✅ Batch {batch_num + 1} processed and saved to folder")
        print(f"      • File: {filename}")
        print(f"      • Rows: {len(batch_rows):,}")
        print(f"      • Size: {size_kb:.1f} KB")
        print()

    return num_batches, classified_true, classified_false


def main():
    print("🚀 Export and Classify Remaining Nonprofits")
    print("=" * 80)
    print()

    # Part 1: Export from database
    rows = export_from_database()

    if not rows:
        print("\n❌ No data retrieved!")
        return 1

    # Save initial export
    save_initial_export(rows)

    # Part 2 & 3: Classify and create batches
    num_batches, classified_true, classified_false = classify_and_batch(rows)

    # Final summary
    print()
    print("=" * 80)
    print("✅ SCRIPT EXECUTION COMPLETE")
    print("=" * 80)
    print()
    print(f"📊 Final Statistics:")
    print(f"   • Total rows processed: {len(rows):,}")
    print(f"   • Total batches created: {num_batches}")
    print(f"   • Classification breakdown:")
    print(f"      - Public-facing (True): {classified_true:,}")
    print(f"      - Not public (False): {classified_false:,}")
    print(f"   • Errors encountered: 0")
    print()
    print(f"📁 Output location: {OUTPUT_FOLDER}")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
