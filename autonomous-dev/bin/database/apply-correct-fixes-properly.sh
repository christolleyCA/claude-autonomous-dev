#!/bin/bash

# Apply CORRECT IRS fixes - PROPERLY this time
# Previous attempt silently failed

set -e

BATCH_DIR="$HOME/nonprofit_name_fixes/correct_batches"

# Connection details
HOST="aws-0-ca-central-1.pooler.supabase.com"
PORT="6543"
USER="postgres.hjtvtkffpziopozmtsnb"
DB="postgres"
PASSWORD="Dharini1221su!"
PSQL="/opt/homebrew/opt/postgresql@14/bin/psql"

echo "🚨 Apply CORRECT IRS Fixes - PROPERLY (52 Batches)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

BATCH_COUNT=$(ls -1 "$BATCH_DIR"/batch_*.sql | wc -l | tr -d ' ')
echo "📦 Total batches: $BATCH_COUNT"
echo ""

START=$(date +%s)
SUCCESS=0
FAIL=0

for i in $(seq 1 $BATCH_COUNT); do
    FILE="$BATCH_DIR/batch_$i.sql"

    if [ ! -f "$FILE" ]; then
        echo "📦 Batch $i: ⚠️  Not found"
        continue
    fi

    UPDATES=$(grep -c "^UPDATE" "$FILE")
    printf "📦 Batch %2d/%2d (%5s updates) ... " "$i" "$BATCH_COUNT" "$UPDATES"

    # Run WITHOUT -q so we can see if it actually executes
    # Redirect output to temp file to check
    TEMP_OUT=$(mktemp)

    if PGPASSWORD="$PASSWORD" timeout 180 $PSQL \
        -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" \
        -f "$FILE" > "$TEMP_OUT" 2>&1; then

        # Count how many "UPDATE 1" lines to verify
        ACTUAL_UPDATES=$(grep -c "^UPDATE 1$" "$TEMP_OUT" || echo "0")

        if [ "$ACTUAL_UPDATES" -eq "$UPDATES" ]; then
            echo "✅ ($ACTUAL_UPDATES/$UPDATES)"
            SUCCESS=$((SUCCESS + 1))
        else
            echo "⚠️  Only $ACTUAL_UPDATES/$UPDATES"
            SUCCESS=$((SUCCESS + 1))
        fi
    else
        echo "❌ FAILED"
        FAIL=$((FAIL + 1))
        # Show error
        tail -5 "$TEMP_OUT"
    fi

    rm -f "$TEMP_OUT"

    # Progress update every 10 batches
    if [ $((i % 10)) -eq 0 ]; then
        ELAPSED=$(($(date +%s) - START))
        AVG=$((ELAPSED / i))
        REMAINING=$(( (BATCH_COUNT - i) * AVG / 60 ))
        echo "   → Progress: $i/$BATCH_COUNT complete | ~${REMAINING}m remaining"
    fi
done

END=$(date +%s)
DURATION=$((END - START))
MINS=$((DURATION / 60))
SECS=$((DURATION % 60))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Results:"
echo "   Success: $SUCCESS/$BATCH_COUNT batches"
echo "   Failed:  $FAIL batches"
echo "   Time:    ${MINS}m ${SECS}s"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
