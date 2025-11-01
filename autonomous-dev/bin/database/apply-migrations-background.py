#!/usr/bin/env python3
"""
Apply all SQL migrations in background
Logs progress to file
"""

import os
import sys
import time
from pathlib import Path
from datetime import datetime

# Configuration
SUPABASE_PROJECT = "hjtvtkffpziopozmtsnb"
SQL_DIR = Path.home() / "nonprofit_sql_inserts"
LOG_FILE = Path.home() / "migration_progress.log"

def log(message):
    """Log to file and print"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_message = f"[{timestamp}] {message}"
    print(log_message)
    with open(LOG_FILE, 'a') as f:
        f.write(log_message + '\n')

def apply_migration(sql_file, chunk_num, total_chunks):
    """Apply a single migration file using Supabase CLI"""
    try:
        # Extract migration name from filename
        migration_name = f"add_nonprofits_{sql_file.stem}"

        # Read SQL content
        with open(sql_file, 'r') as f:
            sql_content = f.read()

        # Use mcp__supabase__apply_migration via external script call
        # For background execution, we'll use a direct approach
        import requests

        SUPABASE_URL = "https://hjtvtkffpziopozmtsnb.supabase.co"
        SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

        # Execute via PostgREST
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/exec_sql",
            headers={
                'apikey': SUPABASE_KEY,
                'Authorization': f'Bearer {SUPABASE_KEY}',
                'Content-Type': 'application/json',
                'Prefer': 'return=representation'
            },
            json={'query': sql_content},
            timeout=180
        )

        if response.status_code in [200, 201, 204]:
            log(f"[{chunk_num}/{total_chunks}] ✅ Applied {sql_file.name}")
            return True
        else:
            log(f"[{chunk_num}/{total_chunks}] ⚠️  {sql_file.name} - Status {response.status_code}")
            return False

    except Exception as e:
        log(f"[{chunk_num}/{total_chunks}] ❌ {sql_file.name} - Error: {str(e)[:100]}")
        return False

def main():
    log("="*80)
    log("  BACKGROUND MIGRATION STARTED")
    log("="*80)
    log(f"SQL Directory: {SQL_DIR}")
    log(f"Log File: {LOG_FILE}")

    # Get all SQL files
    sql_files = sorted(SQL_DIR.glob("chunk_*.sql"))
    total_chunks = len(sql_files)

    log(f"Total chunks to apply: {total_chunks}\n")

    start_time = time.time()
    successful = 0
    failed = 0

    for i, sql_file in enumerate(sql_files, 1):
        if apply_migration(sql_file, i, total_chunks):
            successful += 1
        else:
            failed += 1

        # Progress update every 10 chunks
        if i % 10 == 0:
            elapsed = time.time() - start_time
            avg_time = elapsed / i
            remaining = (total_chunks - i) * avg_time
            log(f"Progress: {i}/{total_chunks} ({successful} successful, {failed} failed) - ETA: {remaining/60:.1f} min")

        # Small delay to avoid rate limiting
        time.sleep(0.3)

    elapsed = time.time() - start_time

    log("\n" + "="*80)
    log("  ✅ MIGRATION COMPLETE!")
    log("="*80)
    log(f"Total chunks: {total_chunks}")
    log(f"Successful: {successful}")
    log(f"Failed: {failed}")
    log(f"Time elapsed: {elapsed/60:.1f} minutes")
    log("="*80)

if __name__ == "__main__":
    main()
