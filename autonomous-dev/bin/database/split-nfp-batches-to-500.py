#!/usr/bin/env python3
"""
Split nonprofit batch files from 1,000 entries to max 500 entries each.

Each original file has:
- 108 lines of instructions
- 1,000 CSV rows of nonprofit data

This script will create 2 new files per original file, each with:
- 108 lines of instructions (copied)
- 500 CSV rows
"""

import os
from pathlib import Path

# Paths
SOURCE_DIR = Path("/Users/christophertolleymacbook2019/Downloads/CSV Files to Process Oct 28/Rest of NFPs without classification or websites but with prompts")
OUTPUT_DIR = Path("/Users/christophertolleymacbook2019/Downloads/CSV Files to Process Oct 28/Split 500-Entry Batches")

# Constants
INSTRUCTION_LINES = 108
BATCH_SIZE = 500

def split_batch_file(input_path: Path, batch_num: int):
    """Split a single batch file into smaller 500-entry batches."""

    print(f"Processing: {input_path.name}")

    with open(input_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Extract instructions and CSV data
    instructions = lines[:INSTRUCTION_LINES]
    csv_data = lines[INSTRUCTION_LINES:]

    actual_csv_count = len(csv_data)
    print(f"  Found {actual_csv_count} CSV rows")

    # Split CSV data into chunks of BATCH_SIZE
    chunks = []
    for i in range(0, len(csv_data), BATCH_SIZE):
        chunk = csv_data[i:i + BATCH_SIZE]
        chunks.append(chunk)

    print(f"  Creating {len(chunks)} new files...")

    # Create new files
    for idx, chunk in enumerate(chunks):
        # Update the instruction to reflect new batch size
        updated_instructions = instructions.copy()

        # Find and replace the "1,000 rows" reference
        for i, line in enumerate(updated_instructions):
            if "1,000 rows" in line:
                updated_instructions[i] = line.replace("1,000 rows", f"{len(chunk)} rows")
            if "all 1,000 rows" in line:
                updated_instructions[i] = line.replace("all 1,000 rows", f"all {len(chunk)} rows")

        # Create output filename
        output_name = f"NFP classified, without websites, with prompts Batch {batch_num} Part {idx + 1}.txt"
        output_path = OUTPUT_DIR / output_name

        # Write new file
        with open(output_path, 'w', encoding='utf-8') as f:
            f.writelines(updated_instructions)
            f.writelines(chunk)

        print(f"  ✓ Created: {output_name} ({len(chunk)} rows)")

def main():
    """Main processing function."""

    # Create output directory
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Output directory: {OUTPUT_DIR}\n")

    # Get all batch files
    batch_files = sorted(SOURCE_DIR.glob("NFP classified, without websites, with prompts Batch *.txt"))

    total_files = len(batch_files)
    print(f"Found {total_files} batch files to process\n")
    print("=" * 60)

    # Process each file
    for batch_file in batch_files:
        # Extract batch number from filename
        # Example: "NFP classified, without websites, with prompts Batch 1.txt"
        parts = batch_file.stem.split("Batch ")
        if len(parts) == 2:
            batch_num = parts[1]
        else:
            batch_num = "unknown"

        split_batch_file(batch_file, batch_num)
        print()

    print("=" * 60)
    print("✅ Processing complete!")

    # Count output files
    output_files = list(OUTPUT_DIR.glob("*.txt"))
    print(f"\nCreated {len(output_files)} new batch files")
    print(f"Original files: {total_files}")
    print(f"New files: {len(output_files)}")
    print(f"\nAll files saved to:\n{OUTPUT_DIR}")

if __name__ == "__main__":
    main()
