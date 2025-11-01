#!/usr/bin/env python3
"""
Automatically apply all 211 nonprofit SQL chunks to Supabase
Uses the Supabase REST API to execute SQL directly
"""

import requests
import time
from pathlib import Path
from datetime import datetime
import sys

# Configuration
SUPABASE_URL = "https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"
SQL_DIR = Path.home() / "nonprofit_sql_inserts"
LOG_FILE = Path.home() / "auto_migration.log"

def log(message):
    """Log to file and print"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_message = f"[{timestamp}] {message}"
    print(log_message, flush=True)
    with open(LOG_FILE, 'a') as f:
        f.write(log_message + '\n')

def execute_sql_chunk(sql_content):
    """Execute SQL via Supabase PostgREST API"""
    try:
        # Use the REST API query endpoint
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/query",
            headers={
                'apikey': SUPABASE_KEY,
                'Authorization': f'Bearer {SUPABASE_KEY}',
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal'
            },
            json={'query': sql_content},
            timeout=120
        )

        # Check for success (2xx status codes)
        if 200 <= response.status_code < 300:
            return True, "Success"
        else:
            return False, f"HTTP {response.status_code}: {response.text[:200]}"

    except requests.exceptions.Timeout:
        return False, "Request timeout (120s)"
    except Exception as e:
        return False, f"Error: {str(e)[:200]}"

def main():
    log("=" * 80)
    log("  AUTOMATIC NONPROFIT MIGRATION")
    log("=" * 80)
    log(f"Supabase URL: {SUPABASE_URL}")
    log(f"SQL Directory: {SQL_DIR}")
    log(f"Log File: {LOG_FILE}\n")

    # Get all chunk files
    chunk_files = sorted(SQL_DIR.glob("chunk_*.sql"))
    total_chunks = len(chunk_files)

    if total_chunks == 0:
        log("❌ ERROR: No chunk files found!")
        sys.exit(1)

    log(f"Found {total_chunks} chunk files to apply\n")

    start_time = time.time()
    successful = 0
    failed = 0
    failed_chunks = []

    for i, chunk_file in enumerate(chunk_files, 1):
        # Read SQL content
        try:
            with open(chunk_file, 'r', encoding='utf-8') as f:
                sql_content = f.read()
        except Exception as e:
            log(f"[{i}/{total_chunks}] ❌ Failed to read {chunk_file.name}: {e}")
            failed += 1
            failed_chunks.append((chunk_file.name, f"Read error: {e}"))
            continue

        chunk_size_kb = len(sql_content) / 1024
        log(f"[{i}/{total_chunks}] Applying {chunk_file.name} ({chunk_size_kb:.1f}KB)...")

        # Execute SQL
        success, message = execute_sql_chunk(sql_content)

        if success:
            log(f"   ✅ Success")
            successful += 1
        else:
            log(f"   ❌ Failed: {message}")
            failed += 1
            failed_chunks.append((chunk_file.name, message))

        # Progress update every 10 chunks
        if i % 10 == 0:
            elapsed = time.time() - start_time
            avg_time = elapsed / i
            remaining = (total_chunks - i) * avg_time
            progress_pct = (successful / i) * 100

            log("")
            log(f"📊 Progress: {i}/{total_chunks} ({progress_pct:.1f}% success rate)")
            log(f"   ✅ Successful: {successful}")
            log(f"   ❌ Failed: {failed}")
            log(f"   ⏱️  ETA: {remaining/60:.1f} minutes")
            log("")

        # Small delay to avoid overwhelming the API
        time.sleep(0.5)

    elapsed = time.time() - start_time

    # Final summary
    log("\n" + "=" * 80)
    log("  ✅ MIGRATION COMPLETE!")
    log("=" * 80)
    log(f"Total chunks: {total_chunks}")
    log(f"Successful: {successful}")
    log(f"Failed: {failed}")
    log(f"Success rate: {(successful/total_chunks)*100:.1f}%")
    log(f"Time elapsed: {elapsed/60:.1f} minutes")
    log(f"Average time per chunk: {elapsed/total_chunks:.1f} seconds")

    if failed_chunks:
        log("\n⚠️  Failed chunks:")
        for chunk_name, error in failed_chunks:
            log(f"   - {chunk_name}: {error}")
        log("\nYou can retry failed chunks manually via the Supabase dashboard.")

    log("=" * 80)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log("\n\n⚠️  Migration interrupted by user")
        sys.exit(1)
    except Exception as e:
        log(f"\n\n❌ Fatal error: {e}")
        sys.exit(1)
