#!/bin/bash
# Combine name fix chunks into larger batches for easier application

cd ~/nonprofit_name_fixes

# Create 11 batches (5 chunks each, except last batch with 2 chunks)
for batch in {1..11}; do
    start_chunk=$(( (batch - 1) * 5 + 1 ))
    end_chunk=$(( batch * 5 ))

    if [ $batch -eq 11 ]; then
        end_chunk=52
    fi

    output_file="batch_fix_${batch}.sql"

    echo "-- Name Fix Batch $batch" > "$output_file"
    echo "-- Combines chunks $start_chunk to $end_chunk" >> "$output_file"
    echo "" >> "$output_file"

    for chunk in $(seq $start_chunk $end_chunk); do
        chunk_file=$(printf "fix_chunk_%03d.sql" $chunk)
        if [ -f "$chunk_file" ]; then
            echo "-- From $chunk_file" >> "$output_file"
            tail -n +4 "$chunk_file" >> "$output_file"
            echo "" >> "$output_file"
        fi
    done

    echo "✓ Created $output_file (chunks $start_chunk-$end_chunk)"
done

echo ""
echo "Created 11 batch files combining all 52 chunks"
