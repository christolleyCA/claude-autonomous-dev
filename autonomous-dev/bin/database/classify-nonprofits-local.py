#!/usr/bin/env python3
"""
Local Nonprofit Classifier
Reads CSV files, classifies nonprofits as public-facing or not based on name patterns
"""

import csv
import re
from pathlib import Path

# Configuration
INPUT_FOLDER = Path.home() / "Downloads" / "CSV Files to Process Oct 28"

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


def classify_nonprofit(name):
    """
    Classify a nonprofit as public-facing or not based on its name

    Returns:
        True if public-facing
        False if not public-facing
    """
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
    # This is the safer assumption for nonprofits
    return True


def process_csv_file(file_path):
    """Process a single CSV file"""
    print(f"\n📄 Processing: {file_path.name}")
    print("-" * 80)

    # Read CSV
    rows = []
    classified_count = 0
    already_classified = 0

    try:
        with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
            reader = csv.DictReader(f)
            fieldnames = reader.fieldnames

            for row in reader:
                # Check if already classified
                public_facing_value = str(row.get('Public-facing', '')).strip().lower()

                if public_facing_value in ['true', 'false']:
                    # Already classified, keep as is
                    already_classified += 1
                else:
                    # Needs classification
                    name = row.get('Name', '')
                    classification = classify_nonprofit(name)
                    row['Public-facing'] = str(classification)
                    classified_count += 1

                rows.append(row)

        # Write updated CSV
        with open(file_path, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)

        # Rename file (unclassified -> classified)
        if 'unclassified' in file_path.name:
            new_name = file_path.name.replace('unclassified', 'classified')
            new_path = file_path.parent / new_name
            file_path.rename(new_path)
            print(f"✅ Renamed to: {new_name}")

        # Print summary
        print(f"\nSummary:")
        print(f"  Rows processed: {len(rows)}")
        print(f"  Newly classified: {classified_count}")
        print(f"  Already classified: {already_classified}")
        print("-" * 80)

        return True

    except Exception as e:
        print(f"❌ Error processing file: {e}")
        return False


def main():
    print("🚀 Local Nonprofit Classifier")
    print("=" * 80)
    print()
    print(f"📁 Processing files in: {INPUT_FOLDER}")
    print()

    # Get list of unclassified CSV files
    csv_files = sorted([
        f for f in INPUT_FOLDER.glob("*unclassified*.csv")
    ])

    if not csv_files:
        print("❌ No unclassified CSV files found!")
        print()
        print("Looking for files matching pattern: *unclassified*.csv")
        return 1

    print(f"📊 Found {len(csv_files)} file(s) to process")
    print()

    # Process each file
    processed = 0
    failed = 0

    for idx, csv_file in enumerate(csv_files, 1):
        print(f"\n{'=' * 80}")
        print(f"Batch {idx} of {len(csv_files)}")
        print(f"{'=' * 80}")

        if process_csv_file(csv_file):
            processed += 1
        else:
            failed += 1

    # Final summary
    print()
    print("=" * 80)
    print("✅ ALL BATCHES COMPLETE")
    print("=" * 80)
    print(f"  Total files processed: {processed}")
    print(f"  Failed: {failed}")
    print("=" * 80)

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
