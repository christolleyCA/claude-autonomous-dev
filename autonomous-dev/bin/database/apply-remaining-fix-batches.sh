#!/bin/bash

# Apply remaining name fix batches one at a time
# More resilient approach with individual batch execution

BATCH_DIR="$HOME/nonprofit_name_fixes/batches"

# TablePlus connection credentials
HOST="aws-0-ca-central-1.pooler.supabase.com"
PORT="6543"
USER="postgres.hjtvtkffpziopozmtsnb"
DB="postgres"
PASSWORD="Dharini1221su!"
PSQL="/opt/homebrew/opt/postgresql@14/bin/psql"

echo "🚀 Apply Remaining Fix Batches (Individual Execution)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL_BATCHES=$(ls -1 "$BATCH_DIR"/batch_*.sql | wc -l | tr -d ' ')
echo "📦 Total batches: $TOTAL_BATCHES"
echo ""

SUCCESS=0
FAIL=0
SKIPPED=0

for i in {1..15}; do
    FILE="$BATCH_DIR/batch_$i.sql"

    if [ ! -f "$FILE" ]; then
        printf "📦 Batch %2d: ⚠️  Not found\n" "$i"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    UPDATES=$(grep -c "^UPDATE" "$FILE" 2>/dev/null || echo "0")
    SIZE=$(du -h "$FILE" | cut -f1)

    printf "📦 Batch %2d: %6s updates (%4s) ... " "$i" "$UPDATES" "$SIZE"

    # Apply this batch
    START=$(date +%s)
    if PGPASSWORD="$PASSWORD" timeout 120 $PSQL -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" -f "$FILE" -q 2>&1 | grep -qi "error"; then
        echo "❌ FAILED"
        FAIL=$((FAIL + 1))
    else
        END=$(date +%s)
        DURATION=$((END - START))
        echo "✅ (${DURATION}s)"
        SUCCESS=$((SUCCESS + 1))
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Results:"
echo "   Success: $SUCCESS batches"
echo "   Failed:  $FAIL batches"
echo "   Skipped: $SKIPPED batches"
echo ""

# Quick check
FIXED=$(PGPASSWORD="$PASSWORD" $PSQL -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" -t -A -c "SELECT COUNT(*) FROM nonprofits WHERE DATE(updated_at) = '2025-10-23' AND DATE(created_at) = '2025-10-22';" 2>/dev/null | tr -d ' ')
CORRUPTED=$(PGPASSWORD="$PASSWORD" $PSQL -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" -t -A -c "SELECT COUNT(*) FROM nonprofits WHERE DATE(created_at) = '2025-10-22' AND NOT (updated_at > created_at AND DATE(updated_at) = '2025-10-23') AND (name LIKE '%LLC%' OR name LIKE '%LLP%' OR name LIKE '%& Co%' OR name LIKE '%CPA%' OR name LIKE '%P.C.%');" 2>/dev/null | tr -d ' ')

echo "📊 Current Status:"
echo "   Fixed today: $(printf "%'d" $FIXED)"
echo "   Still corrupted: $(printf "%'d" $CORRUPTED)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
