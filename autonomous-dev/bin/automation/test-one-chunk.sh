#!/bin/bash
# Test applying one SQL chunk via direct SQL execution

SQL_FILE="$HOME/nonprofit_sql_inserts/chunk_001.sql"

echo "Testing chunk_001.sql..."
echo "File size: $(wc -c < "$SQL_FILE") bytes"
echo "Line count: $(wc -l < "$SQL_FILE") lines"
echo ""
echo "First 5 data rows:"
head -8 "$SQL_FILE" | tail -5
echo ""
echo "Last 3 rows:"
tail -3 "$SQL_FILE"
