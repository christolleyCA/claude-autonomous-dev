#!/bin/bash
# Split each SQL chunk into mini-chunks of 100 INSERT statements each

SQL_DIR="$HOME/nonprofit_sql_inserts"
MINI_DIR="$HOME/nonprofit_sql_mini_chunks"

mkdir -p "$MINI_DIR"

echo "Splitting SQL chunks into mini-chunks of 100 records each..."

MINI_COUNT=0

for chunk_file in "$SQL_DIR"/chunk_*.sql; do
    if [ ! -f "$chunk_file" ]; then
        continue
    fi

    filename=$(basename "$chunk_file")
    chunk_num="${filename#chunk_}"
    chunk_num="${chunk_num%.sql}"

    echo "Processing $filename..."

    # Extract the header and the VALUES lines
    HEADER=$(head -4 "$chunk_file")

    # Get all the value lines (skip header and conflict clause)
    VALUES_START=5
    VALUES_END=$(($(wc -l < "$chunk_file") - 1))

    # Read value lines into array
    mapfile -t -s $((VALUES_START - 1)) -n $((VALUES_END - VALUES_START + 1)) VALUE_LINES < "$chunk_file"

    # Split into groups of 100
    TOTAL_VALUES=${#VALUE_LINES[@]}
    MINI_NUM=0

    for ((i=0; i<$TOTAL_VALUES; i+=100)); do
        MINI_NUM=$((MINI_NUM + 1))
        MINI_FILE="$MINI_DIR/mini_${chunk_num}_${MINI_NUM}.sql"
        MINI_COUNT=$((MINI_COUNT + 1))

        # Write header
        echo "$HEADER" > "$MINI_FILE"

        # Write up to 100 values
        END=$((i + 100))
        if [ $END -gt $TOTAL_VALUES ]; then
            END=$TOTAL_VALUES
        fi

        for ((j=i; j<END; j++)); do
            LINE="${VALUE_LINES[$j]}"
            # Remove trailing comma from last line
            if [ $j -eq $((END - 1)) ]; then
                LINE="${LINE%,}"
            fi
            echo "$LINE" >> "$MINI_FILE"
        done

        # Add conflict clause
        echo "ON CONFLICT (ein_charity_number) DO NOTHING;" >> "$MINI_FILE"
    done
done

echo ""
echo "✅ Created $MINI_COUNT mini-chunk files in $MINI_DIR"
ls -lh "$MINI_DIR" | head -10
