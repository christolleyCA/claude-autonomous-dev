#!/bin/bash
# Quick test: Export 2 batches (1,000 records), classify, and import

echo "🧪 Quick Classification Test"
echo "=============================="
echo ""
echo "This will:"
echo "1. Export 2 batches (1,000 nonprofits)"
echo "2. Wait for you to classify them"
echo "3. Import your classifications"
echo ""
read -p "Press Enter to start..."

# Step 1: Export
echo ""
echo "📊 Step 1: Exporting 2 batches..."
python3 ~/export-nonprofits-for-classification.py

# Check if export succeeded
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Export complete!"
    echo ""
    echo "📝 Step 2: Your turn!"
    echo "=============================="
    echo ""
    echo "1. Open ~/nonprofit_classification_batches/batch_0001.csv"
    echo "2. Review the 'Website' column"
    echo "3. Fill in 'Public Facing' with TRUE or FALSE"
    echo "4. Save the file"
    echo "5. (Optional) Do the same for batch_0002.csv"
    echo ""
    read -p "Press Enter when you're done classifying..."

    # Step 3: Import
    echo ""
    echo "⚡ Step 3: Importing classifications..."
    python3 ~/update-classifications-from-csv.py

    if [ $? -eq 0 ]; then
        echo ""
        echo "=============================="
        echo "✅ Test complete!"
        echo ""
        echo "Check your database to verify:"
        echo "  SELECT COUNT(*) FROM nonprofits WHERE public_facing IS NOT NULL;"
        echo ""
    else
        echo "❌ Import failed!"
    fi
else
    echo "❌ Export failed!"
fi
