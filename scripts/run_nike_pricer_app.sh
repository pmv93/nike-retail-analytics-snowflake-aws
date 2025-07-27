#!/bin/bash
# Run Nike Product Pricer App
# Make sure you're in a Snowflake environment (SiS) or have proper credentials configured

echo "🚀 Starting Nike Product Pricer App..."
echo "📋 Requirements:"
echo "   - Snowflake connection configured"
echo "   - Required Python packages installed"
echo "   - Access to nike_po_prod and nike_reviews databases"
echo ""

# Check if we're in the right directory
if [ ! -f "nike_product_pricer_app.py" ]; then
    echo "❌ Error: nike_product_pricer_app.py not found!"
    echo "Please run this script from the scripts directory"
    exit 1
fi

echo "✅ Found Nike Product Pricer App"
echo "🌐 Starting Streamlit server..."
echo ""

# Run the Streamlit app
streamlit run nike_product_pricer_app.py

echo "👟 Nike Product Pricer App stopped." 