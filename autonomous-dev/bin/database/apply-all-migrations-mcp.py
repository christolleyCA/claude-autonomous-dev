#!/usr/bin/env python3
"""
Apply all 211 SQL migration chunks using direct SQL execution
"""

import requests
import time
from pathlib import Path
from datetime import datetime

# Configuration
SUPABASE_URL = "https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"
SQL_DIR = Path.home() / "nonprofit_sql_inserts"
LOG_FILE = Path.home() / "migration_progress.log"

def log(message):
    """Log to file and print"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_message = f"[{timestamp}] {message}"
    print(log_message)
    with open(LOG_FILE, 'a') as f:
        f.write(log_message + '\n')

def execute_sql_direct(sql_content):
    """Execute SQL using Supabase direct SQL execution"""
    try:
        # Use PostgREST query endpoint
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/exec",
            headers={
                'apikey': SUPABASE_KEY,
                'Authorization': f'Bearer {SUPABASE_KEY}',
                'Content-Type': 'application/json'
            },
            json={'query': sql_content},
            timeout=180
        )

        # Any 2xx status is success
        return response.status_code in range(200, 300)
    except Exception as e:
        log(f"   Error: {str(e)[:100]}")
        return False

def main():
    log("=" * 80)
    log("  STARTING NONPROFIT DATA MIGRATION")
    log("=" * 80)
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
        # Read SQL content
        with open(sql_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()

        log(f"[{i}/{total_chunks}] Applying {sql_file.name}...")

        # Execute SQL
        if execute_sql_direct(sql_content):
            successful += 1
            log(f"   ✅ Success")
        else:
            failed += 1
            log(f"   ❌ Failed")

        # Progress update every 10 chunks
        if i % 10 == 0:
            elapsed = time.time() - start_time
            avg_time = elapsed / i
            remaining = (total_chunks - i) * avg_time
            log(f"\n📊 Progress: {i}/{total_chunks} ({successful} successful, {failed} failed)")
            log(f"   ETA: {remaining/60:.1f} minutes\n")

        # Rate limiting
        time.sleep(0.5)

    elapsed = time.time() - start_time

    log("\n" + "=" * 80)
    log("  ✅ MIGRATION COMPLETE!")
    log("=" * 80)
    log(f"Total chunks: {total_chunks}")
    log(f"Successful: {successful}")
    log(f"Failed: {failed}")
    log(f"Time elapsed: {elapsed/60:.1f} minutes")
    log("=" * 80)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log("\n\n⚠️  Migration interrupted by user")
        exit(1)
