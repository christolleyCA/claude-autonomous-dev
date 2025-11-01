#!/bin/bash
# Combine SQL chunks into batches of 10

cd ~/nonprofit_sql_inserts

for batch in {01..21}; do
  batch_num=$((10#$batch))
  start=$(( (batch_num - 1) * 10 + 1 ))
  end=$(( batch_num * 10 ))

  output="batch_${batch}.sql"
  echo "Creating $output from chunks $start to $end..."

  > "$output"

  for chunk_num in $(seq $start $end); do
    chunk_file=$(printf "chunk_%03d.sql" $chunk_num)
    if [ -f "$chunk_file" ]; then
      cat "$chunk_file" >> "$output"
      echo "" >> "$output"
    fi
  done
done

# Handle remaining chunk (211)
echo "Creating batch_22.sql for chunk 211..."
cat chunk_211.sql > batch_22.sql

echo ""
echo "✅ Created batch files!"
ls -lh batch_*.sql
