#!/bin/bash

# Apply all name fix batches automatically
# Uses the same TablePlus connection credentials that worked for imports

set -e

BATCH_DIR="$HOME/nonprofit_name_fixes/batches"

# TablePlus connection string (proven to work)
HOST="aws-0-ca-central-1.pooler.supabase.com"
PORT="6543"
USER="postgres.hjtvtkffpziopozmtsnb"
DB="postgres"
PASSWORD="Dharini1221su!"
PSQL="/opt/homebrew/opt/postgresql@14/bin/psql"

echo "🚀 Apply All Name Fix Batches"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Using TablePlus connection settings..."
echo "Host: $HOST"
echo "Port: $PORT"
echo "Database: $DB"
echo ""

# Count batches
BATCH_COUNT=$(ls -1 "$BATCH_DIR"/batch_*.sql 2>/dev/null | wc -l | tr -d ' ')

if [ "$BATCH_COUNT" -eq 0 ]; then
    echo "❌ No batch files found in $BATCH_DIR"
    exit 1
fi

echo "📦 Found $BATCH_COUNT batches to apply"
echo ""
echo "Starting import..."
echo ""

SUCCESS=0
FAIL=0
START=$(date +%s)

for FILE in "$BATCH_DIR"/batch_*.sql; do
    BATCH_NAME=$(basename "$FILE" .sql)
    BATCH_NUM=$(echo "$BATCH_NAME" | sed 's/batch_//')

    SIZE=$(du -h "$FILE" | cut -f1)
    UPDATES=$(grep -c "^UPDATE" "$FILE" 2>/dev/null || echo "0")

    printf "📦 Batch %2s: %6s updates (%4s) ... " "$BATCH_NUM" "$UPDATES" "$SIZE"

    # Run with same credentials as TablePlus
    if PGPASSWORD="$PASSWORD" $PSQL -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" -f "$FILE" -q 2>&1 | grep -qi "error"; then
        echo "❌"
        FAIL=$((FAIL + 1))
    else
        echo "✅"
        SUCCESS=$((SUCCESS + 1))
    fi
done

END=$(date +%s)
DURATION=$((END - START))
MINS=$((DURATION / 60))
SECS=$((DURATION % 60))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Complete!"
echo ""
echo "📊 Results:"
echo "   Success: $SUCCESS batches"
echo "   Failed:  $FAIL batches"
echo "   Time:    ${MINS}m ${SECS}s"
echo ""

# Quick verification
echo "🔍 Verifying fixes..."
FIXED_COUNT=$(PGPASSWORD="$PASSWORD" $PSQL -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" -t -A -c "SELECT COUNT(*) FROM nonprofits WHERE DATE(updated_at) = '2025-10-23' AND DATE(created_at) = '2025-10-22';" 2>/dev/null | tr -d ' ')

if [ -n "$FIXED_COUNT" ]; then
    echo "   Records fixed today: $(printf "%'d" $FIXED_COUNT)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Done! All name fixes applied."
