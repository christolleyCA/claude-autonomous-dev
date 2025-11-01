#!/bin/bash

# Run all 22 nonprofit batch files automatically
# Uses the same TablePlus connection credentials

set -e

BATCH_DIR="$HOME/nonprofit_sql_inserts"

# TablePlus connection string (from your screenshot)
HOST="aws-0-ca-central-1.pooler.supabase.com"
PORT="6543"
USER="postgres.hjtvtkffpziopozmtsnb"
DB="postgres"
PASSWORD="Dharini1221su!"

echo "🚀 Automatic Batch Import - All 22 Batches"
echo "=" * 80
echo ""
echo "Using TablePlus connection settings..."
echo "Host: $HOST"
echo "Port: $PORT"
echo "Database: $DB"
echo ""

# Check if we have psql or need alternative
if command -v /opt/homebrew/opt/postgresql@14/bin/psql &> /dev/null; then
    PSQL="/opt/homebrew/opt/postgresql@14/bin/psql"
    echo "✅ Using psql: $PSQL"
else
    echo "❌ psql not found - please install: brew install postgresql"
    exit 1
fi

echo ""
echo "Starting import..."
echo ""

SUCCESS=0
FAIL=0

for i in {1..22}; do
    FILE="$BATCH_DIR/batch_$i.sql"

    if [ ! -f "$FILE" ]; then
        echo "⚠️  Batch $i: File not found"
        continue
    fi

    SIZE=$(du -h "$FILE" | cut -f1)
    printf "📦 Batch %2d/22 (%4s) ... " "$i" "$SIZE"

    # Run with same credentials as TablePlus
    if PGPASSWORD="$PASSWORD" $PSQL -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" -f "$FILE" -q 2>&1 | grep -qi "error"; then
        echo "❌"
        FAIL=$((FAIL + 1))
    else
        echo "✅"
        SUCCESS=$((SUCCESS + 1))
    fi
done

echo ""
echo "=" * 80
echo "✅ Complete!"
echo ""
echo "📊 Results:"
echo "   Success: $SUCCESS batches"
echo "   Failed:  $FAIL batches"
echo "=" * 80
