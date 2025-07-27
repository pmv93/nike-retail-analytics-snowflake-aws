# Nike Retail Analytics Platform
## Price Optimization & Customer Sentiment Analysis using Snowflake Cortex

![Nike Analytics](https://img.shields.io/badge/Nike-Analytics-orange.svg) ![Snowflake](https://img.shields.io/badge/Snowflake-Cortex-blue.svg) ![Streamlit](https://img.shields.io/badge/Streamlit-App-red.svg)

### 🎯 **Project Overview**

This comprehensive analytics platform demonstrates advanced retail analytics for Nike products with **pure Nike data end-to-end**, combining:

- **🔍 Price Optimization** - ML-driven pricing recommendations using demand forecasting
- **🧠 Customer Sentiment Analysis** - AI-powered review analysis using Snowflake Cortex LLM functions  
- **📊 Interactive Dashboards** - Visual product selection with real-time insights
- **🎨 Enhanced User Experience** - Product images, sentiment visualization, and intelligent recommendations

### 🏆 **Nike Products in Your Database**

Your analytics platform includes actual Nike products:
- **Nike Air Force 1 07** - Classic lifestyle sneakers
- **Nike Air Max 90** - Iconic running heritage  
- **Nike Air Zoom Pegasus 40** - Performance running shoes
- **Nike Metcon 9** - Cross-training excellence
- **Nike Air Jordan 1 Low** - Basketball legend
- **Nike Tech Fleece Hoodie** - Premium athleisure
- **Nike Dunk Low** - Streetwear essential

---

## 🚀 **ONE-SCRIPT SETUP PROCESS**

### **📋 Prerequisites**

| Requirement | Details |
|-------------|---------|
| **Snowflake Account** | Enterprise edition recommended |
| **Snowflake Role** | `ACCOUNTADMIN` or sufficient privileges |
| **Browser** | Modern browser for Snowflake UI |
| **Git Repository** | This repository cloned locally |

### **⚡ Step-by-Step Setup**

#### **Step 1: Run the Setup Script**
```sql
-- Run in Snowflake SQL Worksheet: scripts/sql/nike_po_setup.sql
-- The script will create everything and then PAUSE with upload instructions
-- ✅ nike_po_prod database (price optimization)
-- ✅ nike_reviews database (customer sentiment)  
-- ✅ Single nike_data_stage for ALL file uploads
-- ✅ 55+ sample Nike product reviews
-- ✅ All database infrastructure

#### **Step 2: Upload Files When Prompted**

The script will **automatically pause** with prominent instructions:

**"🛑 STOP HERE! UPLOAD YOUR CSV FILES BEFORE CONTINUING 🛑"**

### **📁 Upload Instructions - FLAT FILE STRUCTURE**

All CSV files are now in ONE flat folder for maximum simplicity!

**Single Stage:** `nike_data_stage` - All CSV files are in `scripts/csv/` folder

#### **Snowflake Web UI Upload Instructions**
1. In Snowflake UI: **Databases** → **NIKE_PO_PROD** → **Schemas** → **PUBLIC** → **Stages**
2. Click **NIKE_DATA_STAGE**
3. Upload all 10 CSV files directly from the `scripts/csv/` folder (no subfolders needed!)

#### **📋 Files to Upload (10 files in scripts/csv/):**
- `item.csv` - Nike product details
- `recipe.csv` - Product composition data
- `item_prices.csv` - Pricing information
- `menu_prices.csv` - Menu pricing data
- `price_elasticity.csv` - Demand elasticity data
- `core_poi_geometry.csv` - Geographic data
- `menu_item_aggregate_dt.csv` - Daily transaction aggregates
- `menu_item_cogs_and_price_v.csv` - Cost and pricing view
- `menu_item_aggregate_v.csv` - Analytics aggregates
- `order_item_cost_agg_v.csv` - Order cost aggregations

#### **Step 3: Continue the Script**
After uploading, continue running the same script - it will automatically load all data into tables and complete the setup.

---

## 📱 **Application Deployment**

### **🖥️ Deploy Streamlit App**

**Prerequisites:** API Integration is automatically created by the setup script (requires ACCOUNTADMIN role at the end).

1. **In Snowflake UI:** Projects → Streamlit → "+ Streamlit App"
2. **Choose:** "From Git Repository"
3. **Configure Deployment Settings:**
   - **Role:** `NIKE_PO_DATA_SCIENTIST`
   - **Database:** `NIKE_PO_PROD`
   - **Schema:** `PUBLIC`
   - **Warehouse:** `NIKE_PO_DS_WH`
   - **Python Version:** `3.10` ⚠️ **IMPORTANT: Select Python 3.10 for package compatibility**
   - **API Integration:** `NIKE_GITHUB_API_INTEGRATION` ✅
   - **Repository URL:** `https://github.com/pmv93/nike-retail-analytics-snowflake-aws`
   - **Main File:** `scripts/nike_product_pricer_app.py`
   - **Packages:** Add required packages via "Packages" dropdown (listed in app comments)
4. **Click:** "Create"

**Package Management:** Required packages with compatible versions are listed in comments at the top of the Streamlit app file. When creating the app in Snowflake, add them via the "Packages" dropdown: pandas==2.0.3, numpy==1.24.3, plotly==5.17.0, matplotlib==3.7.2, seaborn==0.12.2, wordcloud==1.9.2, snowflake-ml-python==1.4.0. Note: streamlit and snowflake-snowpark-python are built-in.
**Note:** The `nike_github_api_integration` is created automatically by the setup script to enable Git repository access (requires ACCOUNTADMIN role for API integration creation).
### **📓 Upload Analytics Notebooks**
1. **In Snowflake UI:** Projects → Notebooks → "+ Notebook" → "Import .ipynb file"
2. **Upload Files:**
   - `notebooks/0_start_here.ipynb` (Price Optimization with ML)
   - `notebooks/nike_product_review_analytics.ipynb` (Cortex Sentiment Analysis)
3. **Run:** The sentiment analytics notebook to create additional aggregated tables

---

## 📈 **What You'll Get**

After complete deployment:

✅ **2 Complete Databases**: `nike_po_prod` + `nike_reviews` with **pure Nike data**  
✅ **Visual Nike Product Pricer**: Interactive app with product images and AI insights  
✅ **ML-Powered Analytics**: Price optimization + sentiment analysis workflows  
✅ **55+ Nike Product Reviews**: Multi-language customer feedback (English, Spanish, French)  
✅ **Snowflake Cortex Integration**: SENTIMENT, TRANSLATE, COMPLETE functions  

---

## 🎯 **Key Files Reference**

### **🗂️ Essential Setup Files**
- **`scripts/sql/nike_po_setup.sql`** - Single comprehensive setup script
- **`scripts/csv/*.csv`** - 10 Nike data files (flat structure)

### **📱 Application Files**  
- **`scripts/nike_product_pricer_app.py`** - Main Streamlit application
- **`notebooks/0_start_here.ipynb`** - Price optimization notebook
- **`notebooks/nike_product_review_analytics.ipynb`** - Sentiment analysis notebook

### **📖 Documentation**
- **`Nike_Retail_Project_README.ipynb`** - Comprehensive setup guide (detailed version)

---

## 🎉 **Setup Evolution - Maximum Simplicity**

**Original:** 3 separate SQL scripts + complex folder structure  
**Previous:** 1 script run twice + subfolders  
**NOW:** 1 script + 1 stage + 10 flat files  

**Process:** Start script → Upload 10 files when prompted → Script completes → Deploy apps

**ABSOLUTE MAXIMUM SIMPLICITY ACHIEVED!** 🚀

---

## 🔧 **Troubleshooting**

**Common Issues:**
- **File Upload:** Ensure all 10 CSV files are uploaded to nike_data_stage
- **Permissions:** Use ACCOUNTADMIN role or ensure sufficient privileges
- **Script Pause:** Look for the prominent "STOP HERE" message in the SQL output

**Need Help?** Check the detailed `Nike_Retail_Project_README.ipynb` for comprehensive guidance.

---

## 📜 **Attribution**

This project is adapted from Snowflake quickstart guides:
- [Tasty Bytes Price Optimization](https://quickstarts.snowflake.com/guide/tasty_bytes_price_optimization_using_snowflake_notebooks_and_streamlit/)
- [Customer Reviews Analytics using Snowflake Cortex](https://quickstarts.snowflake.com/guide/customer_reviews_analytics_using_snowflake_cortex/)
