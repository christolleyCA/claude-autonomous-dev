#!/usr/bin/env python3
"""
Convert CSV files to TXT with AI prompt prepended
"""

from pathlib import Path

# Configuration
INPUT_FOLDER = Path.home() / "Downloads" / "CSV Files to Process Oct 28"

# The prompt to prepend
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

"""


def convert_csv_to_txt(csv_file):
    """Convert a CSV file to TXT with prompt prepended"""

    # Read CSV content
    with open(csv_file, 'r', encoding='utf-8') as f:
        csv_content = f.read()

    # Create new content with prompt + CSV
    new_content = PROMPT_TEXT + "\n" + csv_content

    # Create new filename: replace .csv with ' ready for AI.txt'
    new_name = csv_file.stem + " ready for AI.txt"
    new_path = csv_file.parent / new_name

    # Write to new TXT file
    with open(new_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

    # Delete original CSV file
    csv_file.unlink()

    return new_path


def main():
    print("🔄 Converting CSV files to TXT with AI prompt")
    print("=" * 80)
    print()
    print(f"📁 Processing folder: {INPUT_FOLDER}")
    print()

    # Get all CSV files
    csv_files = sorted(INPUT_FOLDER.glob("*.csv"))

    if not csv_files:
        print("❌ No CSV files found!")
        return 1

    print(f"📊 Found {len(csv_files)} CSV file(s) to convert")
    print()

    converted = 0

    for csv_file in csv_files:
        try:
            new_path = convert_csv_to_txt(csv_file)
            print(f"✅ {csv_file.name} → {new_path.name}")
            converted += 1
        except Exception as e:
            print(f"❌ Error converting {csv_file.name}: {e}")

    print()
    print("=" * 80)
    print("✅ Conversion complete!")
    print(f"   Converted {converted} files")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
