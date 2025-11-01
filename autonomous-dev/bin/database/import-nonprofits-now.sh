#!/bin/bash

# Quick import script for 210,598 nonprofits
# Run this after setting your database password

set -e

# Use full path to psql
PSQL="/opt/homebrew/opt/postgresql@14/bin/psql"

# Supabase connection
DB_HOST="db.hjtvtkffpziopozmtsnb.supabase.co"
DB_PORT="5432"
DB_USER="postgres"
DB_NAME="postgres"
BATCH_DIR="$HOME/nonprofit_sql_inserts"

echo "🚀 Nonprofit Import Starting..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check password
if [ -z "$PGPASSWORD" ]; then
    echo "❌ No password set!"
    echo ""
    echo "Get your password from Supabase:"
    echo "https://supabase.com/dashboard/project/hjtvtkffpziopozmtsnb/settings/database"
    echo ""
    echo "Then run:"
    echo "  export PGPASSWORD='your-password-here'"
    echo "  $0"
    exit 1
fi

echo "✅ Password detected"
echo "📁 Applying 22 batch files..."
echo ""

START=$(date +%s)
SUCCESS=0
FAIL=0

# Apply batches
for i in {1..22}; do
    FILE="$BATCH_DIR/batch_$i.sql"

    if [ ! -f "$FILE" ]; then
        echo "⚠️  Batch $i: Not found"
        continue
    fi

    SIZE=$(du -h "$FILE" | cut -f1)
    printf "📦 Batch %2d/22 (%4s) ... " "$i" "$SIZE"

    if $PSQL -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$FILE" -q 2>&1 | grep -qi "error"; then
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
echo "✅ Import Complete!"
echo ""
echo "📊 Results:"
echo "   Success: $SUCCESS batches"
echo "   Failed:  $FAIL batches"
echo "   Time:    ${MINS}m ${SECS}s"
echo ""

# Get count
echo "🔍 Verifying..."
COUNT=$($PSQL -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM nonprofits;" 2>/dev/null | tr -d ' ')

if [ -n "$COUNT" ]; then
    echo "   Total nonprofits: $(printf "%'d" $COUNT)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Done! Check Supabase to verify the import."
