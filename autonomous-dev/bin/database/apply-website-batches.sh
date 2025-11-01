#!/bin/bash
# Apply all website update batches to Supabase

BATCH_DIR="$HOME/nonprofit_website_updates/batches"
PGPASSWORD="Dharini1221su!"
PSQL="/opt/homebrew/opt/postgresql@14/bin/psql"
HOST="aws-0-ca-central-1.pooler.supabase.com"
PORT="6543"
USER="postgres.hjtvtkffpziopozmtsnb"
DB="postgres"

export PGPASSWORD

echo "🚀 Applying Website Update Batches"
echo "=================================="
echo ""

total_batches=$(ls -1 "$BATCH_DIR"/batch_*.sql 2>/dev/null | wc -l | tr -d ' ')

if [ "$total_batches" -eq 0 ]; then
    echo "❌ No batch files found in $BATCH_DIR"
    exit 1
fi

echo "Found $total_batches batches to apply"
echo ""

success_count=0
fail_count=0
start_time=$(date +%s)

for batch_file in "$BATCH_DIR"/batch_*.sql; do
    batch_name=$(basename "$batch_file")
    batch_num="${batch_name#batch_}"
    batch_num="${batch_num%.sql}"

    echo "📝 Applying $batch_name..."
    batch_start=$(date +%s)

    if $PSQL -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" -f "$batch_file" -q 2>&1; then
        batch_end=$(date +%s)
        batch_duration=$((batch_end - batch_start))
        success_count=$((success_count + 1))
        echo "   ✅ Success (${batch_duration}s)"
    else
        batch_end=$(date +%s)
        batch_duration=$((batch_end - batch_start))
        fail_count=$((fail_count + 1))
        echo "   ❌ Failed (${batch_duration}s)"
    fi

    echo ""
done

end_time=$(date +%s)
total_duration=$((end_time - start_time))
total_minutes=$((total_duration / 60))
total_seconds=$((total_duration % 60))

echo "=================================="
echo "📊 Summary"
echo "=================================="
echo "Total batches: $total_batches"
echo "Successful: $success_count"
echo "Failed: $fail_count"
echo "Total time: ${total_minutes}m ${total_seconds}s"
echo ""

if [ "$fail_count" -eq 0 ]; then
    echo "✅ All website updates applied successfully!"
else
    echo "⚠️  Some batches failed. Check output above for details."
    exit 1
fi
