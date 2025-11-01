#!/bin/bash
# Apply all SQL chunks using Supabase CLI

PROJECT_REF="hjtvtkffpziopozmtsnb"
SQL_DIR="$HOME/nonprofit_sql_inserts"

echo "=========================================="
echo "  APPLYING ALL SQL MIGRATIONS"
echo "=========================================="
echo ""
echo "Project: $PROJECT_REF"
echo "SQL Directory: $SQL_DIR"
echo "Total chunks: $(ls -1 $SQL_DIR/chunk_*.sql | wc -l | tr -d ' ')"
echo ""

# Set up environment
export SUPABASE_ACCESS_TOKEN="${SUPABASE_ACCESS_TOKEN:-}"

COUNT=0
SUCCESS=0
FAILED=0

for SQL_FILE in $SQL_DIR/chunk_*.sql; do
    COUNT=$((COUNT + 1))
    FILENAME=$(basename "$SQL_FILE")

    echo "[$COUNT/211] Applying $FILENAME..."

    # Use supabase db execute with project reference
    if supabase db execute --project-ref "$PROJECT_REF" --file "$SQL_FILE" 2>&1 | grep -q "Error\|Failed"; then
        echo "  ❌ Failed"
        FAILED=$((FAILED + 1))
    else
        echo "  ✅ Success"
        SUCCESS=$((SUCCESS + 1))
    fi

    # Progress update every 10 chunks
    if [ $((COUNT % 10)) -eq 0 ]; then
        echo ""
        echo "Progress: $COUNT/211 ($SUCCESS successful, $FAILED failed)"
        echo ""
    fi

    # Small delay to avoid rate limiting
    sleep 0.5
done

echo ""
echo "=========================================="
echo "  ✅ MIGRATION COMPLETE!"
echo "=========================================="
echo "Total chunks: $COUNT"
echo "Successful: $SUCCESS"
echo "Failed: $FAILED"
