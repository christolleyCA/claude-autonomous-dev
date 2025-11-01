#!/bin/bash

# Apply all 22 nonprofit batch files to Supabase
# This will insert 210,598 new nonprofits

set -e  # Exit on any error

# Supabase connection details
DB_HOST="db.hjtvtkffpziopozmtsnb.supabase.co"
DB_PORT="5432"
DB_USER="postgres"
DB_NAME="postgres"
BATCH_DIR="$HOME/nonprofit_sql_inserts"

echo "🚀 Starting nonprofit batch import..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if password is provided
if [ -z "$PGPASSWORD" ]; then
    echo "❌ ERROR: Database password not set"
    echo ""
    echo "Please set PGPASSWORD environment variable:"
    echo "export PGPASSWORD='your-password-here'"
    echo ""
    echo "Get password from: https://supabase.com/dashboard/project/hjtvtkffpziopozmtsnb/settings/database"
    exit 1
fi

# Verify batch files exist
if [ ! -d "$BATCH_DIR" ]; then
    echo "❌ ERROR: Batch directory not found: $BATCH_DIR"
    exit 1
fi

# Count batch files
BATCH_COUNT=$(ls -1 "$BATCH_DIR"/batch_*.sql 2>/dev/null | wc -l | tr -d ' ')
if [ "$BATCH_COUNT" -eq 0 ]; then
    echo "❌ ERROR: No batch files found in $BATCH_DIR"
    exit 1
fi

echo "📁 Found $BATCH_COUNT batch files to process"
echo ""

# Track progress
SUCCESSFUL=0
FAILED=0
START_TIME=$(date +%s)

# Apply each batch file in order
for i in {1..22}; do
    BATCH_FILE="$BATCH_DIR/batch_$i.sql"

    if [ ! -f "$BATCH_FILE" ]; then
        echo "⚠️  Batch $i: File not found, skipping..."
        continue
    fi

    FILE_SIZE=$(du -h "$BATCH_FILE" | cut -f1)
    echo "📦 Batch $i/22 ($FILE_SIZE)..."

    # Apply the batch using psql
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$BATCH_FILE" -q 2>&1 | grep -q "ERROR"; then
        echo "   ❌ FAILED"
        FAILED=$((FAILED + 1))
    else
        echo "   ✅ SUCCESS"
        SUCCESSFUL=$((SUCCESSFUL + 1))
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Calculate duration
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo "✅ Import completed!"
echo ""
echo "📊 Results:"
echo "   Successful: $SUCCESSFUL batches"
echo "   Failed: $FAILED batches"
echo "   Duration: ${MINUTES}m ${SECONDS}s"
echo ""
echo "🔍 Verifying import..."

# Verify the import by counting nonprofits
NEW_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM nonprofits;" 2>/dev/null | tr -d ' ')

if [ -n "$NEW_COUNT" ]; then
    echo "   Total nonprofits in database: $NEW_COUNT"
    echo ""
    echo "🎉 Import successful! Run the verification query to see details."
else
    echo "   ⚠️  Could not verify count"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
