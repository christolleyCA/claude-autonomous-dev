#!/bin/bash

# Split the large fix file into manageable batches
# Similar to how we split the nonprofit imports

INPUT_FILE="$HOME/nonprofit_name_fixes/remaining_fixes_batch.sql"
OUTPUT_DIR="$HOME/nonprofit_name_fixes/batches"
UPDATES_PER_BATCH=10000

echo "🔪 Splitting fix file into batches..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Input: $INPUT_FILE"
echo "Output: $OUTPUT_DIR"
echo "Updates per batch: $UPDATES_PER_BATCH"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Extract header (first 3 comment lines)
head -n 3 "$INPUT_FILE" > /tmp/header.sql

# Count total UPDATE statements
TOTAL_UPDATES=$(grep -c "^UPDATE" "$INPUT_FILE")
echo "📊 Total UPDATE statements: $(printf "%'d" $TOTAL_UPDATES)"

# Calculate number of batches needed
TOTAL_BATCHES=$(( ($TOTAL_UPDATES + $UPDATES_PER_BATCH - 1) / $UPDATES_PER_BATCH ))
echo "📦 Creating $TOTAL_BATCHES batches..."
echo ""

# Split the file
BATCH_NUM=1
CURRENT_COUNT=0

{
    # Copy header to first batch
    cat /tmp/header.sql > "$OUTPUT_DIR/batch_$BATCH_NUM.sql"

    # Process UPDATE statements
    grep "^UPDATE" "$INPUT_FILE" | while IFS= read -r line; do
        echo "$line" >> "$OUTPUT_DIR/batch_$BATCH_NUM.sql"
        CURRENT_COUNT=$((CURRENT_COUNT + 1))

        if [ $CURRENT_COUNT -ge $UPDATES_PER_BATCH ]; then
            SIZE=$(du -h "$OUTPUT_DIR/batch_$BATCH_NUM.sql" | cut -f1)
            printf "✅ Batch %2d: %6d updates (%4s)\n" "$BATCH_NUM" "$UPDATES_PER_BATCH" "$SIZE"

            BATCH_NUM=$((BATCH_NUM + 1))
            CURRENT_COUNT=0

            # Start new batch with header
            cat /tmp/header.sql > "$OUTPUT_DIR/batch_$BATCH_NUM.sql"
        fi
    done

    # Final batch
    if [ $CURRENT_COUNT -gt 0 ]; then
        SIZE=$(du -h "$OUTPUT_DIR/batch_$BATCH_NUM.sql" | cut -f1)
        printf "✅ Batch %2d: %6d updates (%4s)\n" "$BATCH_NUM" "$CURRENT_COUNT" "$SIZE"
    fi
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Split complete!"
echo "📁 Location: $OUTPUT_DIR"
echo "📦 Total batches: $TOTAL_BATCHES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
