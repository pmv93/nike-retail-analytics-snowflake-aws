[![Snowflake - Certified](https://img.shields.io/badge/Snowflake-Certified-2ea44f?style=for-the-badge&logo=snowflake)](https://developers.snowflake.com/solutions/)

# Nike Price Optimization and Customer Reviews Analytics using Snowflake Cortex

## Overview
Nike is one of the world's largest athletic footwear and apparel companies with diverse product lines spread across 15 specialized Nike brands globally. This project demonstrates two powerful use cases:

1. **Price Optimization** - Using machine learning to find the right prices for Nike products to maximize profitability while maintaining customer satisfaction
2. **Customer Reviews Analytics** - Leveraging Snowflake Cortex LLM functions to analyze customer sentiment, extract insights, and inform pricing strategies

## Key Features

### 🔍 **Price Optimization**
- ML-driven price recommendations for Nike products
- Product demand forecasting based on pricing changes
- Interactive Streamlit application for price management
- Real-time profit impact analysis

### 💬 **Customer Reviews Analytics with Snowflake Cortex**
- **Sentiment Analysis** using Cortex SENTIMENT function
- **Multi-language Support** with Cortex TRANSLATE function  
- **Intelligent Insights** using Cortex COMPLETE function for recommendation likelihood
- **Aspect-based Analysis** to understand customer feedback on comfort, style, quality, etc.
- **Integration with Pricing** - sentiment data influences price optimization strategies

### 🖼️ **Enhanced Product Visualization**
- High-quality Nike product images from official sources
- Interactive product galleries in Streamlit
- Visual sentiment indicators alongside pricing data

## Project Structure

```
├── notebooks/
│   ├── 0_start_here.ipynb                    # Price optimization notebook
│   └── nike_product_review_analytics.ipynb   # Cortex-powered review analytics
├── scripts/
│   ├── application_monthly_pricing_app.py    # Streamlit app with reviews integration
│   ├── csv/                                  # Nike product datasets
│   ├── sql/                                  # Database setup scripts
│   └── generate_nike_reviews.py              # Sample review data generator
├── setup/
│   ├── nike_reviews_setup.sql                # Customer reviews database setup
│   └── nike_po_setup.sql                     # Price optimization database setup
└── nike_product_images.json                  # Product image mappings
```

## Attribution

This project is adapted from the following Snowflake quickstart guides:
- [Tasty Bytes Price Optimization using Snowflake Notebooks and Streamlit](https://quickstarts.snowflake.com/guide/tasty_bytes_price_optimization_using_snowflake_notebooks_and_streamlit/index.html?index=..%2F..index#0)
- [Customer Reviews Analytics using Snowflake Cortex](https://quickstarts.snowflake.com/guide/customer_reviews_analytics_using_snowflake_cortex/index.html?index=..%2F..index#0)

The original guides have been significantly modified and enhanced to focus on Nike retail analytics with integrated customer sentiment analysis and visual product selection capabilities.

## Step-By-Step Guide
For prerequisites, environment setup, step-by-step guide and instructions, please refer to the comprehensive [Nike Retail Project README](Nike_Retail_Project_README.ipynb).

## 🗃️ **Nike Data Upload Instructions**

**IMPORTANT**: Before running the SQL scripts, you need to upload your Nike CSV data files to Snowflake stages:

### **📁 Required Files to Upload**

After running `scripts/sql/nike_po_setup.sql`, upload these files from your local repository:

| Snowflake Stage | Upload Files From |
|-----------------|-------------------|
| `raw_pos_stage` | `scripts/csv/raw_pos/` folder |
| `raw_customer_stage` | `scripts/csv/raw_customer/` folder |
| `raw_supply_chain_stage` | `scripts/csv/raw_supply_chain/` folder |
| `raw_safegraph_stage` | `scripts/csv/raw_safegraph/core_poi_geometry.csv` |
| `harmonized_stage` | `scripts/csv/harmonized/menu_item_aggregate_dt/menu_item_aggregate_dt.csv` |
| `analytics_stage` | `scripts/csv/analytics/` folder |

### **💻 Upload Methods**

#### **Option 1: Snowflake Web UI (Recommended)**
1. In Snowflake UI: **Databases** → **NIKE_PO_PROD** → **Schemas** → **PUBLIC** → **Stages**
2. Click each stage → **Upload Files** → Select corresponding CSV files

#### **Option 2: SnowSQL Command Line**
```bash
PUT file://scripts/csv/raw_pos/* @nike_po_prod.public.raw_pos_stage;
PUT file://scripts/csv/raw_customer/* @nike_po_prod.public.raw_customer_stage;
PUT file://scripts/csv/raw_supply_chain/* @nike_po_prod.public.raw_supply_chain_stage;
PUT file://scripts/csv/raw_safegraph/* @nike_po_prod.public.raw_safegraph_stage;
PUT file://scripts/csv/harmonized/* @nike_po_prod.public.harmonized_stage;
PUT file://scripts/csv/analytics/* @nike_po_prod.public.analytics_stage;
```

## 📋 **Execution Order**

1. **Setup Database**: Run `scripts/sql/nike_po_setup.sql` (this creates both databases and loads sample data)
2. **Upload Data**: Upload Nike CSV files to stages (see above)
3. **Re-run Setup**: Re-run `scripts/sql/nike_po_setup.sql` to load data into tables
4. **Deploy Apps**: Upload notebooks and deploy Streamlit apps

## 🎯 **Single Setup Script**

The `nike_po_setup.sql` script now includes everything you need:
- ✅ **Price Optimization Database** (`nike_po_prod`) with all Nike product data
- ✅ **Customer Reviews Database** (`nike_reviews`) with Cortex AI capabilities  
- ✅ **Sample Review Data** (55+ realistic Nike product reviews in multiple languages)
- ✅ **Complete Analytics Views** for both pricing and sentiment analysis

## Customer Reviews Analytics Setup

1. **Database Setup**: Already included in `scripts/sql/nike_po_setup.sql`
2. **Sample Data**: Already included in the main setup script
3. **Analytics Notebook**: Open `notebooks/nike_product_review_analytics.ipynb` for Cortex-powered analysis
4. **Streamlit Integration**: The pricing app now shows customer sentiment alongside pricing data
