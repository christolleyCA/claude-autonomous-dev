#!/usr/bin/env python3
"""
Import nonprofits using Supabase MCP (already authenticated)
This bypasses password issues by using the MCP connection
"""

import sys
import time
import subprocess
import json
from pathlib import Path

BATCH_DIR = Path.home() / "nonprofit_sql_inserts"
PROJECT_ID = "hjtvtkffpziopozmtsnb"
TOTAL_BATCHES = 22

def read_batch_file(batch_num):
    """Read a batch SQL file"""
    batch_file = BATCH_DIR / f"batch_{batch_num}.sql"
    if not batch_file.exists():
        return None

    with open(batch_file, 'r') as f:
        return f.read()

def apply_via_supabase_mcp(sql_content, batch_num):
    """Apply SQL via Supabase MCP using apply_migration"""
    migration_name = f"import_nonprofits_batch_{batch_num}_{int(time.time())}"

    # Use Claude's MCP to apply the migration
    cmd = [
        "claude",
        "mcp",
        "call",
        "supabase",
        "apply_migration",
        "--project_id", PROJECT_ID,
        "--name", migration_name,
        "--query", sql_content
    ]

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )

        if result.returncode == 0:
            return True, None
        else:
            return False, result.stderr or result.stdout
    except subprocess.TimeoutExpired:
        return False, "Timeout after 5 minutes"
    except Exception as e:
        return False, str(e)

def main():
    print("🚀 Nonprofit Import via Supabase MCP")
    print("=" * 80)
    print()
    print(f"📁 Batch directory: {BATCH_DIR}")
    print(f"📦 Batches to process: {TOTAL_BATCHES}")
    print(f"🔗 Using MCP (already authenticated)")
    print()

    if not BATCH_DIR.exists():
        print(f"❌ ERROR: Batch directory not found: {BATCH_DIR}")
        return 1

    successful = 0
    failed = 0
    start_time = time.time()

    for batch_num in range(1, TOTAL_BATCHES + 1):
        print(f"📦 Batch {batch_num}/{TOTAL_BATCHES}...", end=" ", flush=True)

        # Read the SQL file
        sql_content = read_batch_file(batch_num)
        if sql_content is None:
            print("⚠️  File not found")
            continue

        # Apply via MCP
        success, error = apply_via_supabase_mcp(sql_content, batch_num)

        if success:
            print("✅")
            successful += 1
        else:
            print(f"❌ {error}")
            failed += 1

            # Ask if user wants to continue after failure
            if failed >= 3:
                print()
                print("⚠️  Multiple failures detected. Continue? (y/n): ", end="")
                response = input().strip().lower()
                if response != 'y':
                    break

    duration = time.time() - start_time
    minutes = int(duration // 60)
    seconds = int(duration % 60)

    print()
    print("=" * 80)
    print("✅ Import process completed!")
    print()
    print(f"📊 Results:")
    print(f"   Successful: {successful} batches")
    print(f"   Failed: {failed} batches")
    print(f"   Duration: {minutes}m {seconds}s")
    print("=" * 80)

    return 0 if failed == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
