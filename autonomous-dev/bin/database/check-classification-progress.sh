#!/bin/bash
# Check classification progress

echo "📊 Nonprofit Website Classification Progress"
echo "============================================="
echo ""

# Database connection
export PGPASSWORD="Dharini1221su!"
PSQL="/opt/homebrew/opt/postgresql@14/bin/psql"
DB_HOST="aws-0-ca-central-1.pooler.supabase.com"
DB_PORT="6543"
DB_USER="postgres.hjtvtkffpziopozmtsnb"
DB_NAME="postgres"

echo "Querying database..."
echo ""

# Get counts
RESULT=$($PSQL -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -F "|" -c "
SELECT
    COUNT(*) as total,
    COUNT(CASE WHEN website IS NOT NULL THEN 1 END) as has_website,
    COUNT(CASE WHEN public_facing = TRUE THEN 1 END) as public_facing_true,
    COUNT(CASE WHEN public_facing = FALSE THEN 1 END) as public_facing_false,
    COUNT(CASE WHEN website IS NOT NULL AND public_facing IS NULL THEN 1 END) as needs_classification
FROM nonprofits;
")

# Parse results
IFS='|' read -r TOTAL HAS_WEBSITE TRUE_COUNT FALSE_COUNT NEEDS_CLASS <<< "$RESULT"

# Calculate percentages
CLASSIFIED=$((TRUE_COUNT + FALSE_COUNT))
if [ "$HAS_WEBSITE" -gt 0 ]; then
    PERCENT_DONE=$(echo "scale=2; $CLASSIFIED * 100 / $HAS_WEBSITE" | bc)
else
    PERCENT_DONE=0
fi

# Display results
echo "📈 Statistics:"
echo "   Total nonprofits:           $TOTAL"
echo "   With websites:              $HAS_WEBSITE"
echo ""
echo "✅ Classified:"
echo "   Public facing (TRUE):       $TRUE_COUNT"
echo "   Not public facing (FALSE):  $FALSE_COUNT"
echo "   Total classified:           $CLASSIFIED"
echo ""
echo "⏳ Remaining:"
echo "   Needs classification:       $NEEDS_CLASS"
echo ""
echo "📊 Progress:"
echo "   Completion:                 $PERCENT_DONE%"
echo ""

# Calculate remaining batches
BATCH_SIZE=500
BATCHES_REMAINING=$((($NEEDS_CLASS + $BATCH_SIZE - 1) / $BATCH_SIZE))

echo "📦 Batch Info:"
echo "   Batches remaining:          $BATCHES_REMAINING"
echo "   Records per batch:          $BATCH_SIZE"
echo ""

# Estimate time
if [ "$CLASSIFIED" -gt 0 ]; then
    echo "💡 Tips:"
    echo "   • Process 10 batches (5,000 records) per session"
    echo "   • Use Excel filters to group similar patterns"
    echo "   • Common rules: @handle=FALSE, /path=FALSE, proper.domain=TRUE"
    echo ""
fi

echo "============================================="
