#!/usr/bin/env python3
"""
Split CSV into batches of 500 rows with prompt for website research
"""

import csv
from pathlib import Path

# Configuration
INPUT_FILE = Path.home() / "Downloads" / "50k entries without websites.csv"
OUTPUT_FOLDER = Path.home() / "Downloads" / "CSV Files to Process Oct 28"
CHUNK_SIZE = 500

# The prompt to include in each file
PROMPT_TEXT = """**Role**
You find and verify official websites for U.S. nonprofit organizations. You output the text as a properly formatted CSV file in a code box that can be easily copied and pasted.

---

## INPUT
A CSV dataset with 500 rows containing nonprofit information with columns including:
`EIN, Name, City, State, Public Facing, Website`

At minimum: `Name, City, State`

---

## YOUR TASK
For each row where the **Website** field is empty or needs verification AND where **Public-facing=TRUE**:
1. Search the web to find the organization's **official website**
2. Verify the website matches the organization
3. Add the verified URL to the Website column
4. Leave blank if no reliable official website can be found

**If a website is already present:** Verify it loads and is correct. Update only if clearly wrong.

---

## WEBSITE SEARCH & VERIFICATION PROTOCOL

### Search Strategy
1. Search: `"[Organization Name]" [City] [State]` and optionally include EIN
2. Look for the organization's official domain (not directories or intermediaries)
3. For university departments or hospital clinics, find the specific program's page within the parent institution

### Verification Requirements
✓ Site must load successfully (not 404)
✓ Name and location match the organization
✓ Appears to be the official domain (check About page, footer, contact info)
✓ For charities within larger entities, find the specific charity program URL (e.g., `company.com/foundation` not just `company.com`)

### What NOT to Use
✗ Third-party charity directories (GuideStar, Charity Navigator, etc.)
✗ Donation platforms or fundraising intermediaries
✗ Social media pages (unless absolutely no official site exists)
✗ Unrelated or suspicious domains

### URL Formatting
- Use HTTPS only
- Remove tracking parameters (UTM codes, etc.)
- Use clean, official domain format
- If no official website exists, use verified Facebook Page as last resort
- If uncertain about authenticity, leave blank

---

## OUTPUT REQUIREMENTS

### CSV File Specifications

- **Format:** Valid CSV with proper escaping
    - Text containing commas must be wrapped in quotes
    - Text containing quotes must have quotes escaped (`""`)
    - No characters that break CSV integrity

- **Columns:** Include all original columns, with Website column updated BUT DO NOT INCLUDE THE HEADER (ie: 'EIN,Name,City,State,Website,Public-facing')

- **Do not modify:** Keep all original data (EIN, Name, City, State, etc.) exactly as provided

- **Export the result as text in a properly formatted CSV format in a code box that can be easily copied and pasted**
---

## FINAL SUMMARY

After processing all 500 rows, provide:

```
Summary:
Rows processed: [number]
Websites found: [number]
Already had websites: [number]
Left blank (no reliable site): [number]
Needs Review: [number]
```

### Needs Review Section
If any websites are unclear or questionable, list them:

```
Needs Review:
- [Organization Name] — [brief reason]
```

---

## ERROR HANDLING & RULES

**DO:**
- Search thoroughly before leaving blank
- Verify every URL loads and matches
- Use proper CSV escaping for special characters
- Preserve all original data exactly

**DO NOT:**
- Invent or guess URLs
- Use markdown link formatting in CSV
- Modify organization names, addresses, or other original data
- Include filler phrases or commentary
- Add rows or remove rows from the dataset

---

## EXECUTION APPROACH

Process all 500 entries efficiently:
1. For entries with existing websites: Quick verification only
2. For blank websites: Thorough search and verification
3. Focus on accuracy over speed
4. When in doubt, leave blank and add to Needs Review

---

The 500-row CSV data below:

```"""


def read_csv(file_path):
    """Read CSV file and return headers and rows"""
    rows = []
    with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.reader(f)
        headers = next(reader)  # Get headers
        for row in reader:
            rows.append(row)
    return headers, rows


def write_batch_file(batch_num, headers, rows, output_folder):
    """Write a batch file with prompt and CSV data"""
    filename = f"batch_{batch_num:03d}.txt"
    filepath = output_folder / filename

    with open(filepath, 'w', encoding='utf-8') as f:
        # Write the prompt
        f.write(PROMPT_TEXT)
        f.write('\n\n')

        # Write headers
        f.write(','.join(headers))
        f.write('\n')

        # Write CSV rows
        writer = csv.writer(f)
        writer.writerows(rows)

    return filepath


def main():
    print("🚀 Split CSV into Batches for Processing")
    print("=" * 80)
    print()

    # Check input file exists
    if not INPUT_FILE.exists():
        print(f"❌ Input file not found: {INPUT_FILE}")
        return 1

    # Create output folder
    OUTPUT_FOLDER.mkdir(parents=True, exist_ok=True)
    print(f"📂 Input file: {INPUT_FILE.name}")
    print(f"📁 Output folder: {OUTPUT_FOLDER}")
    print(f"📦 Chunk size: {CHUNK_SIZE} rows")
    print()

    # Read CSV
    print("📖 Reading CSV file...")
    headers, all_rows = read_csv(INPUT_FILE)
    total_rows = len(all_rows)
    print(f"   ✅ Read {total_rows:,} rows")
    print(f"   📋 Columns: {', '.join(headers)}")
    print()

    # Calculate number of batches
    num_batches = (total_rows + CHUNK_SIZE - 1) // CHUNK_SIZE
    print(f"✂️  Splitting into {num_batches} batches...")
    print()

    # Create batch files
    for batch_num in range(num_batches):
        start_idx = batch_num * CHUNK_SIZE
        end_idx = min(start_idx + CHUNK_SIZE, total_rows)
        batch_rows = all_rows[start_idx:end_idx]

        filepath = write_batch_file(batch_num + 1, headers, batch_rows, OUTPUT_FOLDER)

        size_kb = filepath.stat().st_size / 1024
        print(f"   ✅ {filepath.name}: {len(batch_rows)} rows ({size_kb:.1f} KB)")

    print()
    print("=" * 80)
    print("✅ Split complete!")
    print(f"   Created {num_batches} batch files")
    print(f"   Total rows processed: {total_rows:,}")
    print(f"   Location: {OUTPUT_FOLDER}")
    print()
    print("💡 Each file contains:")
    print("   • Complete prompt instructions")
    print("   • CSV headers")
    print("   • 500 rows of data (last batch may have fewer)")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
