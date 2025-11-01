#!/usr/bin/env python3
"""
Apply nonprofit batches to Supabase automatically
Uses Supabase MCP to apply all 22 batch files
"""

import os
import sys
import time
from pathlib import Path

# Check if we can import the required module
try:
    import subprocess
    import json
except ImportError as e:
    print(f"❌ Missing required module: {e}")
    sys.exit(1)

# Configuration
PROJECT_ID = "hjtvtkffpziopozmtsnb"
BATCH_DIR = Path.home() / "nonprofit_sql_inserts"
TOTAL_BATCHES = 22

def apply_batch_via_psql(batch_num, batch_file, password):
    """Apply a batch file using psql command"""
    cmd = [
        "psql",
        "-h", "db.hjtvtkffpziopozmtsnb.supabase.co",
        "-p", "5432",
        "-U", "postgres",
        "-d", "postgres",
        "-f", str(batch_file),
        "-q"
    ]

    env = os.environ.copy()
    env['PGPASSWORD'] = password

    try:
        result = subprocess.run(
            cmd,
            env=env,
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout per batch
        )

        if result.returncode != 0 or "ERROR" in result.stderr:
            return False, result.stderr
        return True, None
    except subprocess.TimeoutExpired:
        return False, "Timeout after 5 minutes"
    except Exception as e:
        return False, str(e)

def main():
    print("🚀 Starting Nonprofit Batch Import")
    print("=" * 80)
    print()

    # Get password from environment or prompt
    password = os.environ.get('PGPASSWORD') or os.environ.get('SUPABASE_PASSWORD')

    if not password:
        print("❌ ERROR: Database password not set")
        print()
        print("Set password using either:")
        print("  export PGPASSWORD='your-password-here'")
        print("  export SUPABASE_PASSWORD='your-password-here'")
        print()
        print("Get password from:")
        print("  https://supabase.com/dashboard/project/hjtvtkffpziopozmtsnb/settings/database")
        sys.exit(1)

    # Check psql is installed
    try:
        subprocess.run(["psql", "--version"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ ERROR: psql not found")
        print()
        print("Install PostgreSQL client:")
        print("  brew install postgresql")
        sys.exit(1)

    # Verify batch directory exists
    if not BATCH_DIR.exists():
        print(f"❌ ERROR: Batch directory not found: {BATCH_DIR}")
        sys.exit(1)

    print(f"📁 Batch directory: {BATCH_DIR}")
    print(f"📦 Batches to process: {TOTAL_BATCHES}")
    print()

    # Track progress
    successful = 0
    failed = 0
    start_time = time.time()

    # Apply each batch
    for i in range(1, TOTAL_BATCHES + 1):
        batch_file = BATCH_DIR / f"batch_{i}.sql"

        if not batch_file.exists():
            print(f"⚠️  Batch {i}/{TOTAL_BATCHES}: File not found, skipping...")
            continue

        file_size = batch_file.stat().st_size / (1024 * 1024)  # MB
        print(f"📦 Batch {i}/{TOTAL_BATCHES} ({file_size:.1f}MB)...", end=" ", flush=True)

        success, error = apply_batch_via_psql(i, batch_file, password)

        if success:
            print("✅")
            successful += 1
        else:
            print(f"❌ FAILED: {error}")
            failed += 1

    print()
    print("=" * 80)

    # Calculate duration
    duration = time.time() - start_time
    minutes = int(duration // 60)
    seconds = int(duration % 60)

    print("✅ Import completed!")
    print()
    print(f"📊 Results:")
    print(f"   Successful: {successful} batches")
    print(f"   Failed: {failed} batches")
    print(f"   Duration: {minutes}m {seconds}s")
    print()

    if successful > 0:
        print("🔍 Run this query in Supabase to verify:")
        print()
        print("   SELECT COUNT(*) as total_nonprofits,")
        print("          COUNT(website) as with_websites")
        print("   FROM nonprofits;")
        print()
        print("Expected: ~937,650 total (was ~727K)")

    print("=" * 80)

    return 0 if failed == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
