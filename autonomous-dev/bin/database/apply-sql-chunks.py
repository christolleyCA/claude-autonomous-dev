#!/usr/bin/env python3
"""
Apply all SQL chunk files to Supabase
"""

import os
import sys
import requests
from pathlib import Path
import time

# Configuration
SUPABASE_URL = "https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

SQL_DIR = Path.home() / "nonprofit_sql_inserts"

def execute_sql(sql):
    """Execute SQL via Supabase REST API"""
    try:
        # Use PostgreSQL REST API endpoint
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/query",
            headers={
                'apikey': SUPABASE_KEY,
                'Authorization': f'Bearer {SUPABASE_KEY}',
                'Content-Type': 'application/json'
            },
            json={'query': sql},
            timeout=120
        )

        return response.status_code in [200, 201, 204]

    except Exception as e:
        print(f"      ❌ Error: {e}")
        return False

def main():
    print("=" * 80)
    print("  APPLYING SQL MIGRATIONS")
    print("=" * 80)
    print(f"\n📁 SQL Directory: {SQL_DIR}\n")

    # Get all SQL files
    sql_files = sorted(SQL_DIR.glob("chunk_*.sql"))
    total_chunks = len(sql_files)

    print(f"📊 Total chunks: {total_chunks}\n")

    successful = 0
    failed = 0

    for i, sql_file in enumerate(sql_files, 1):
        print(f"[{i}/{total_chunks}] Applying {sql_file.name}...", end=' ')
        sys.stdout.flush()

        # Read SQL
        with open(sql_file, 'r') as f:
            sql = f.read()

        # Execute
        if execute_sql(sql):
            print("✅")
            successful += 1
        else:
            print("❌")
            failed += 1

        # Progress update
        if i % 10 == 0:
            print(f"   Progress: {i}/{total_chunks} ({successful} successful, {failed} failed)")

        # Rate limiting
        time.sleep(0.5)

    print("\n" + "=" * 80)
    print("  ✅ MIGRATION COMPLETE!")
    print("=" * 80)
    print(f"\n📊 Summary:")
    print(f"   Total chunks: {total_chunks}")
    print(f"   Successful: {successful}")
    print(f"   Failed: {failed}")
    print(f"\n✅ Migrations applied!\n")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user.\n")
        sys.exit(0)
