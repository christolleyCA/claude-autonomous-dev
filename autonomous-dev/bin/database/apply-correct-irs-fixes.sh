#!/bin/bash

# Apply all CORRECT IRS name fixes (52 batches)
# This will FIX the bad updates made with outdated JSON file

set -e

BATCH_DIR="$HOME/nonprofit_name_fixes/correct_batches"

# TablePlus connection credentials
HOST="aws-0-ca-central-1.pooler.supabase.com"
PORT="6543"
USER="postgres.hjtvtkffpziopozmtsnb"
DB="postgres"
PASSWORD="Dharini1221su!"
PSQL="/opt/homebrew/opt/postgresql@14/bin/psql"

echo "🚨 Apply CORRECT IRS Name Fixes (52 Batches)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This will fix the 514,807 incorrect names in the database"
echo "using authoritative IRS bulk CSV data."
echo ""

TOTAL_BATCHES=$(ls -1 "$BATCH_DIR"/batch_*.sql 2>/dev/null | wc -l | tr -d ' ')

if [ "$TOTAL_BATCHES" -eq 0 ]; then
    echo "❌ No batch files found in $BATCH_DIR"
    exit 1
fi

echo "📦 Found $TOTAL_BATCHES batches to apply"
echo ""
echo "Starting fixes..."
echo ""

SUCCESS=0
FAIL=0
START=$(date +%s)

for i in $(seq 1 $TOTAL_BATCHES); do
    FILE="$BATCH_DIR/batch_$i.sql"

    if [ ! -f "$FILE" ]; then
        printf "📦 Batch %2d: ⚠️  Not found\n" "$i"
        continue
    fi

    UPDATES=$(grep -c "^UPDATE" "$FILE" 2>/dev/null || echo "0")
    SIZE=$(du -h "$FILE" | cut -f1)

    printf "📦 Batch %2d/%2d: %6s updates (%4s) ... " "$i" "$TOTAL_BATCHES" "$UPDATES" "$SIZE"

    # Apply this batch with timeout
    if PGPASSWORD="$PASSWORD" timeout 120 $PSQL -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" -f "$FILE" -q 2>&1 | grep -qi "error"; then
        echo "❌ FAILED"
        FAIL=$((FAIL + 1))
    else
        echo "✅"
        SUCCESS=$((SUCCESS + 1))
    fi

    # Brief progress update every 10 batches
    if [ $((i % 10)) -eq 0 ]; then
        ELAPSED=$(($(date +%s) - START))
        AVG_TIME=$(( ELAPSED / i ))
        REMAINING=$(( (TOTAL_BATCHES - i) * AVG_TIME ))
        MINS=$((REMAINING / 60))
        echo "   Progress: $i/$TOTAL_BATCHES | Est. time remaining: ${MINS}m"
    fi
done

END=$(date +%s)
DURATION=$((END - START))
MINS=$((DURATION / 60))
SECS=$((DURATION % 60))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Results:"
echo "   Success: $SUCCESS batches"
echo "   Failed:  $FAIL batches"
echo "   Time:    ${MINS}m ${SECS}s"
echo ""

# Verification
echo "🔍 Verifying fixes..."

TOTAL=$(PGPASSWORD="$PASSWORD" $PSQL -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" -t -A -c "SELECT COUNT(*) FROM nonprofits;" 2>/dev/null | tr -d ' ')

echo "   Total nonprofits: $(printf "%'d" $TOTAL)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Done! All CORRECT names applied from authoritative IRS CSV data."
echo ""
echo "The database now has accurate nonprofit names!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
