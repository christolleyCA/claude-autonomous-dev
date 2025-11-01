#!/usr/bin/env python3
"""
Import nonprofits using Supabase MCP (bypasses password issues)
Splits large batch files into manageable chunks for MCP execution
"""

import re
import sys
import time
from pathlib import Path

BATCH_DIR = Path.home() / "nonprofit_sql_inserts"
TOTAL_BATCHES = 22
ROWS_PER_CHUNK = 100  # Process 100 rows at a time

def extract_insert_rows(sql_content):
    """Extract individual INSERT rows from the SQL file"""
    # Find the VALUES section and extract each row
    values_match = re.search(r'VALUES\s+(.*?)\s+ON CONFLICT', sql_content, re.DOTALL)
    if not values_match:
        return []

    values_text = values_match.group(1)

    # Split by "),\n(" pattern to get individual rows
    # Each row starts with '(' and ends with ')'
    rows = []
    current_row = ""
    paren_count = 0

    for char in values_text:
        current_row += char
        if char == '(':
            paren_count += 1
        elif char == ')':
            paren_count -= 1
            if paren_count == 0 and current_row.strip():
                rows.append(current_row.strip().rstrip(','))
                current_row = ""

    return rows

def create_chunk_sql(rows, table_name="nonprofits"):
    """Create a complete INSERT statement for a chunk of rows"""
    if not rows:
        return None

    header = f"""INSERT INTO {table_name} (ein_charity_number, name, country, website, contact_info, annual_revenue, tax_status, organization_type, is_foundation, created_at, updated_at, cause_areas)
VALUES
"""

    values = ",\n".join(rows)
    footer = "\nON CONFLICT (ein_charity_number) DO NOTHING;"

    return header + values + footer

def apply_chunk_via_mcp(chunk_sql):
    """Apply a SQL chunk via Supabase MCP execute_sql"""
    # Import here to avoid issues if module not available
    import subprocess
    import json

    try:
        # Use claude mcp call to execute SQL
        result = subprocess.run(
            ['claude', 'mcp', 'call', 'supabase', 'execute_sql',
             '--project_id', 'hjtvtkffpziopozmtsnb',
             '--query', chunk_sql],
            capture_output=True,
            text=True,
            timeout=60
        )

        if result.returncode == 0:
            return True, None
        else:
            error_msg = result.stderr or result.stdout
            # Check if it's just a "no results" message (which is fine for INSERT)
            if 'INSERT' in error_msg or 'successfully' in error_msg.lower():
                return True, None
            return False, error_msg[:200]  # Truncate long errors

    except subprocess.TimeoutExpired:
        return False, "Timeout (60s)"
    except Exception as e:
        return False, str(e)[:200]

def process_batch_file(batch_num):
    """Process one batch file"""
    batch_file = BATCH_DIR / f"batch_{batch_num}.sql"

    if not batch_file.exists():
        return 0, 0, "File not found"

    print(f"\n📦 Batch {batch_num}/{TOTAL_BATCHES}")
    print(f"   Reading file...")

    with open(batch_file, 'r') as f:
        sql_content = f.read()

    print(f"   Extracting rows...")
    rows = extract_insert_rows(sql_content)

    if not rows:
        return 0, 0, "No rows found in file"

    total_rows = len(rows)
    print(f"   Found {total_rows} rows")
    print(f"   Processing in chunks of {ROWS_PER_CHUNK}...")

    successful_rows = 0
    failed_chunks = 0

    # Process in chunks
    for i in range(0, len(rows), ROWS_PER_CHUNK):
        chunk_rows = rows[i:i + ROWS_PER_CHUNK]
        chunk_num = (i // ROWS_PER_CHUNK) + 1
        total_chunks = (len(rows) + ROWS_PER_CHUNK - 1) // ROWS_PER_CHUNK

        print(f"   Chunk {chunk_num}/{total_chunks} ({len(chunk_rows)} rows)...", end=" ", flush=True)

        chunk_sql = create_chunk_sql(chunk_rows)
        success, error = apply_chunk_via_mcp(chunk_sql)

        if success:
            print("✅")
            successful_rows += len(chunk_rows)
        else:
            print(f"❌ {error}")
            failed_chunks += 1

            # Stop if too many failures
            if failed_chunks >= 5:
                print(f"   ⚠️  Too many failures in batch {batch_num}, stopping this batch")
                break

        # Small delay to avoid overwhelming the API
        time.sleep(0.5)

    return successful_rows, total_rows, None

def main():
    print("🚀 Nonprofit Import via Supabase MCP (Chunked)")
    print("=" * 80)
    print(f"📁 Batch directory: {BATCH_DIR}")
    print(f"📦 Total batches: {TOTAL_BATCHES}")
    print(f"🔢 Rows per chunk: {ROWS_PER_CHUNK}")
    print(f"🔗 Using: Supabase MCP (already authenticated)")
    print("=" * 80)

    if not BATCH_DIR.exists():
        print(f"❌ ERROR: Batch directory not found: {BATCH_DIR}")
        return 1

    total_successful = 0
    total_attempted = 0
    batches_completed = 0
    batches_failed = 0

    start_time = time.time()

    for batch_num in range(1, TOTAL_BATCHES + 1):
        successful, total, error = process_batch_file(batch_num)

        if error:
            print(f"   ❌ {error}")
            batches_failed += 1
        else:
            total_successful += successful
            total_attempted += total
            batches_completed += 1
            print(f"   ✅ Batch complete: {successful}/{total} rows imported")

    duration = time.time() - start_time
    minutes = int(duration // 60)
    seconds = int(duration % 60)

    print()
    print("=" * 80)
    print("✅ Import process completed!")
    print()
    print(f"📊 Results:")
    print(f"   Batches completed: {batches_completed}/{TOTAL_BATCHES}")
    print(f"   Batches failed: {batches_failed}")
    print(f"   Rows imported: {total_successful:,}")
    print(f"   Rows attempted: {total_attempted:,}")
    print(f"   Duration: {minutes}m {seconds}s")
    print("=" * 80)

    return 0 if batches_failed == 0 else 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user")
        sys.exit(1)
