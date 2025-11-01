#!/bin/bash
# Apply all SQL chunks one by one

SQL_DIR="$HOME/nonprofit_sql_inserts"
LOG_FILE="$HOME/chunk_application_progress.log"

echo "=============================================" | tee -a "$LOG_FILE"
echo "  APPLYING ALL SQL CHUNKS VIA SUPABASE MCP" | tee -a "$LOG_FILE"
echo "=============================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

TOTAL_CHUNKS=211
SUCCESS=0
FAILED=0

for i in $(seq 1 $TOTAL_CHUNKS); do
    CHUNK_NUM=$(printf "%03d" $i)
    SQL_FILE="$SQL_DIR/chunk_${CHUNK_NUM}.sql"

    if [ ! -f "$SQL_FILE" ]; then
        echo "[$i/$TOTAL_CHUNKS] ❌ File not found: $SQL_FILE" | tee -a "$LOG_FILE"
        FAILED=$((FAILED + 1))
        continue
    fi

    echo "[$i/$TOTAL_CHUNKS] Applying chunk_${CHUNK_NUM}.sql..." | tee -a "$LOG_FILE"

    # Note: This script is just for logging
    # The actual execution needs to be done via the MCP tool
    echo "  → Chunk ready: $SQL_FILE" | tee -a "$LOG_FILE"

    # Progress every 10 chunks
    if [ $((i % 10)) -eq 0 ]; then
        echo "" | tee -a "$LOG_FILE"
        echo "Progress: $i/$TOTAL_CHUNKS" | tee -a "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"
    fi
done

echo "" | tee -a "$LOG_FILE"
echo "=============================================" | tee -a "$LOG_FILE"
echo "  ✅ READY TO APPLY $TOTAL_CHUNKS CHUNKS" | tee -a "$LOG_FILE"
echo "=============================================" | tee -a "$LOG_FILE"
