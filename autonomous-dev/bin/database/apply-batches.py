#!/usr/bin/env python3
"""
Apply all batch SQL files using Supabase SQL execution
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
LOG_FILE = Path.home() / "batch_migration_progress.log"

def log(message):
    """Log to file and print"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_message = f"[{timestamp}] {message}"
    print(log_message)
    sys.stdout.flush()
    with open(LOG_FILE, 'a') as f:
        f.write(log_message + '\n')

def execute_sql(sql_content):
    """Execute SQL using Supabase PostgREST API"""
    try:
        # Use the REST API to execute SQL via a database function
        # We'll use a direct connection string approach
        import psycopg2
        from urllib.parse import quote_plus

        # Connect directly to PostgreSQL
        conn_string = f"postgresql://postgres.hjtvtkffpziopozmtsnb:{quote_plus('your-password')}@db.hjtvtkffpziopozmtsnb.supabase.co:5432/postgres"

        # This won't work without the password, so let's use the HTTP API instead
        # Use the GraphQL endpoint for raw SQL
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/exec",
            headers={
                'apikey': SUPABASE_KEY,
                'Authorization': f'Bearer {SUPABASE_KEY}',
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal'
            },
            json={'query': sql_content},
            timeout=300
        )

        return response.status_code in range(200, 300)
    except Exception as e:
        log(f"   Error: {str(e)[:200]}")
        return False

def main():
    log("=" * 80)
    log("  STARTING BATCH MIGRATION")
    log("=" * 80)
    log(f"SQL Directory: {SQL_DIR}")
    log(f"Log File: {LOG_FILE}")

    # Get all batch files
    batch_files = sorted(SQL_DIR.glob("batch_*.sql"))
    total_batches = len(batch_files)

    log(f"Total batches to apply: {total_batches}\n")

    start_time = time.time()
    successful = 0
    failed = 0

    for i, batch_file in enumerate(batch_files, 1):
        # Read SQL content
        log(f"[{i}/{total_batches}] Reading {batch_file.name}...")
        with open(batch_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()

        log(f"[{i}/{total_batches}] Applying {batch_file.name} ({len(sql_content)} chars)...")

        # Execute SQL
        if execute_sql(sql_content):
            successful += 1
            log(f"   ✅ Success")
        else:
            failed += 1
            log(f"   ❌ Failed")

        # Progress update
        if i % 5 == 0:
            elapsed = time.time() - start_time
            avg_time = elapsed / i
            remaining = (total_batches - i) * avg_time
            log(f"\n📊 Progress: {i}/{total_batches} ({successful} successful, {failed} failed)")
            log(f"   ETA: {remaining/60:.1f} minutes\n")

        # Rate limiting
        time.sleep(1)

    elapsed = time.time() - start_time

    log("\n" + "=" * 80)
    log("  ✅ MIGRATION COMPLETE!")
    log("=" * 80)
    log(f"Total batches: {total_batches}")
    log(f"Successful: {successful}")
    log(f"Failed: {failed}")
    log(f"Time elapsed: {elapsed/60:.1f} minutes")
    log("=" * 80)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log("\n\n⚠️  Migration interrupted by user")
        sys.exit(1)
