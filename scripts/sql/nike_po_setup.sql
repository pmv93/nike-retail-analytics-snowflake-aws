/*----------------------------------------------------------------------------------
Instructions: Run all of this script to create the required tables and roles.

 ----------------------------------------------------------------------------------*/

use role securityadmin;

-- create nike_po_data_scientist
CREATE OR REPLACE ROLE nike_po_data_scientist;

use role accountadmin;

/*---------------------------*/
-- create our Database
/*---------------------------*/
CREATE OR REPLACE DATABASE nike_po_prod;

/*---------------------------*/
-- create our Schemas
/*---------------------------*/
CREATE OR REPLACE SCHEMA nike_po_prod.raw_pos;
CREATE OR REPLACE SCHEMA nike_po_prod.raw_supply_chain;
CREATE OR REPLACE SCHEMA nike_po_prod.raw_customer;
CREATE OR REPLACE SCHEMA nike_po_prod.harmonized;
CREATE OR REPLACE SCHEMA nike_po_prod.analytics;
CREATE OR REPLACE SCHEMA nike_po_prod.raw_safegraph;
CREATE OR REPLACE SCHEMA nike_po_prod.public;

/*---------------------------*/
-- create our Warehouses
/*---------------------------*/

-- data science warehouse
CREATE OR REPLACE WAREHOUSE nike_po_ds_wh
    WAREHOUSE_SIZE = 'xxxlarge'
    WAREHOUSE_TYPE = 'standard'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
COMMENT = 'data science warehouse for nike';

CREATE OR REPLACE WAREHOUSE nike_po_app_wh
    WAREHOUSE_SIZE = 'xsmall'
    WAREHOUSE_TYPE = 'standard'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
COMMENT = 'streamlit app warehouse for nike';

-- use our Warehouse
USE WAREHOUSE nike_po_ds_wh;

-- grant nike_po_ds_wh priviledges to nike_po_data_scientist role
GRANT USAGE ON WAREHOUSE nike_po_ds_wh TO ROLE nike_po_data_scientist;
GRANT OPERATE ON WAREHOUSE nike_po_ds_wh TO ROLE nike_po_data_scientist;
GRANT MONITOR ON WAREHOUSE nike_po_ds_wh TO ROLE nike_po_data_scientist;
GRANT MODIFY ON WAREHOUSE nike_po_ds_wh TO ROLE nike_po_data_scientist;

-- grant nike_po_app_wh priviledges to nike_po_data_scientist role
GRANT USAGE ON WAREHOUSE nike_po_app_wh TO ROLE nike_po_data_scientist;
GRANT OPERATE ON WAREHOUSE nike_po_app_wh TO ROLE nike_po_data_scientist;
GRANT MONITOR ON WAREHOUSE nike_po_app_wh TO ROLE nike_po_data_scientist;
GRANT MODIFY ON WAREHOUSE nike_po_app_wh TO ROLE nike_po_data_scientist;

-- grant nike database privileges
GRANT ALL ON DATABASE nike_po_prod TO ROLE nike_po_data_scientist;

GRANT ALL ON SCHEMA nike_po_prod.raw_pos TO ROLE nike_po_data_scientist;
GRANT ALL ON SCHEMA nike_po_prod.raw_supply_chain TO ROLE nike_po_data_scientist;
GRANT ALL ON SCHEMA nike_po_prod.raw_customer TO ROLE nike_po_data_scientist;
GRANT ALL ON SCHEMA nike_po_prod.harmonized TO ROLE nike_po_data_scientist;
GRANT ALL ON SCHEMA nike_po_prod.analytics TO ROLE nike_po_data_scientist;
GRANT ALL ON SCHEMA nike_po_prod.raw_safegraph TO ROLE nike_po_data_scientist;
GRANT ALL ON SCHEMA nike_po_prod.public TO ROLE nike_po_data_scientist;

GRANT CREATE STAGE ON SCHEMA nike_po_prod.analytics TO ROLE nike_po_data_scientist;
GRANT CREATE STAGE ON SCHEMA nike_po_prod.public TO ROLE nike_po_data_scientist;

GRANT ALL ON ALL STAGES IN SCHEMA nike_po_prod.analytics TO ROLE nike_po_data_scientist;
GRANT ALL ON ALL STAGES IN SCHEMA nike_po_prod.public TO ROLE nike_po_data_scientist;

-- set my_user_var variable to equal the logged-in user
SET my_user_var = (SELECT  '"' || CURRENT_USER() || '"' );

-- grant the logged in user the doc_ai_role
GRANT ROLE nike_po_data_scientist TO USER identifier($my_user_var);

USE ROLE nike_po_data_scientist;

show grants to role accountadmin;

/*---------------------------*/
-- create file format
/*---------------------------*/

create or replace file format nike_po_prod.public.csv_ff
type = 'CSV'
field_delimiter = ','
record_delimiter = '\n'
field_optionally_enclosed_by = '"'
skip_header = 1;


/*---------------------------*/
-- create Single Internal Stage for All Nike Data
/*---------------------------*/
-- NOTE: You need to upload ALL Nike CSV files to this single stage after running this script
-- Upload your entire scripts/csv/ folder structure to maintain organization
-- See README.md for detailed upload instructions

CREATE OR REPLACE STAGE nike_po_prod.public.nike_data_stage
  FILE_FORMAT = nike_po_prod.public.csv_ff
  COMMENT = 'Single stage for all Nike product data - maintains folder structure';


/*---------------------------*/
-- DATA UPLOAD INSTRUCTIONS
/*---------------------------*/
-- IMPORTANT: After running this setup script, you need to upload Nike CSV files to the single stage.
-- 
-- Option 1: Using Snowflake Web UI (Recommended)
-- 1. Go to Snowflake UI -> Databases -> NIKE_PO_PROD -> Schemas -> PUBLIC -> Stages
-- 2. Click on NIKE_DATA_STAGE
-- 3. Upload your ENTIRE scripts/csv/ folder structure to maintain the folder organization
--    The stage will contain:
--    - csv/raw_supply_chain/item/item.csv
--    - csv/raw_supply_chain/recipe/recipe.csv
--    - csv/raw_supply_chain/item_prices/item_prices.csv
--    - csv/raw_supply_chain/menu_prices/menu_prices.csv
--    - csv/raw_supply_chain/price_elasticity/price_elasticity.csv
--    - csv/raw_safegraph/core_poi_geometry.csv
--    - csv/harmonized/menu_item_aggregate_dt/menu_item_aggregate_dt.csv
--    - csv/harmonized/menu_item_cogs_and_price_v/menu_item_cogs_and_price_v.csv
--    - csv/analytics/menu_item_aggregate_v/menu_item_aggregate_v.csv
--    - csv/analytics/menu_item_cogs_and_price_v/menu_item_cogs_and_price_v.csv
--    - csv/analytics/order_item_cost_agg_v/order_item_cost_agg_v.csv
-- 
-- Option 2: Using SnowSQL command line (if you have SnowSQL installed)
-- PUT file://scripts/csv/* @nike_po_prod.public.nike_data_stage auto_compress=false recursive=true;
--
-- THEN re-run this script to load the data into tables.

/*---------------------------*/
-- create raw_pos tables
/*---------------------------*/

--> menu
CREATE OR REPLACE TABLE nike_po_prod.raw_pos.menu
(
    menu_id NUMBER(19,0),
    menu_type_id NUMBER(38,0),
    menu_type VARCHAR(16777216),
    truck_brand_name VARCHAR(16777216),
    menu_item_id NUMBER(38,0),
    menu_item_name VARCHAR(16777216),
    item_category VARCHAR(16777216),
    item_subcategory VARCHAR(16777216),
    cost_of_goods_usd NUMBER(38,4),
    sale_price_usd NUMBER(38,4),
    menu_item_health_metrics_obj VARIANT
);

-- --> menu
-- NOTE: No raw_pos data available in Nike dataset
-- COPY INTO nike_po_prod.raw_pos.menu
-- FROM @nike_po_prod.public.nike_data_stage/csv/raw_pos/menu/menu.csv
-- file_format = (format_name = 'nike_po_prod.public.csv_ff');

--> truck
CREATE OR REPLACE TABLE nike_po_prod.raw_pos.truck
(
    truck_id NUMBER(38,0),
    menu_type_id NUMBER(38,0),
    primary_city VARCHAR(16777216),
    region VARCHAR(16777216),
    iso_region VARCHAR(16777216),
    country VARCHAR(16777216),
    iso_country_code VARCHAR(16777216),
    franchise_flag NUMBER(38,0),
    year NUMBER(38,0),
    make VARCHAR(16777216),
    model VARCHAR(16777216),
    ev_flag NUMBER(38,0),
    franchise_id NUMBER(38,0),
    truck_opening_date DATE
);

--> truck
COPY INTO nike_po_prod.raw_pos.truck
FROM @nike_po_prod.public.nike_data_stage/raw_pos/truck/truck.csv
file_format = (format_name = 'nike_po_prod.public.csv_ff');


--> country
CREATE OR REPLACE TABLE nike_po_prod.raw_pos.country
(
	COUNTRY_ID NUMBER(18,0),
	COUNTRY VARCHAR(16777216),
	ISO_CURRENCY VARCHAR(3),
	ISO_COUNTRY VARCHAR(2),
	CITY_ID NUMBER(19,0),
	CITY VARCHAR(16777216),
	CITY_POPULATION NUMBER(38,0)
);

--> country
COPY INTO nike_po_prod.raw_pos.country
FROM @nike_po_prod.public.nike_data_stage/raw_pos/country/country.csv
file_format = (format_name = 'nike_po_prod.public.csv_ff');

--> franchise
CREATE OR REPLACE TABLE nike_po_prod.raw_pos.franchise
(
    FRANCHISE_ID NUMBER(38,0),
	FIRST_NAME VARCHAR(16777216),
	LAST_NAME VARCHAR(16777216),
	CITY VARCHAR(16777216),
	COUNTRY VARCHAR(16777216),
	E_MAIL VARCHAR(16777216),
	PHONE_NUMBER VARCHAR(16777216)
);

--> franchise
COPY INTO nike_po_prod.raw_pos.franchise
FROM @nike_po_prod.public.nike_data_stage/raw_pos/franchise/franchise.csv
file_format = (format_name = 'nike_po_prod.public.csv_ff');


--> location
CREATE OR REPLACE TABLE nike_po_prod.raw_pos.location
(
	LOCATION_ID NUMBER(19,0),
	PLACEKEY VARCHAR(16777216),
	LOCATION VARCHAR(16777216),
	CITY VARCHAR(16777216),
	REGION VARCHAR(16777216),
	ISO_COUNTRY_CODE VARCHAR(16777216),
	COUNTRY VARCHAR(16777216)
);

--> location
COPY INTO nike_po_prod.raw_pos.location
FROM @nike_po_prod.public.nike_data_stage/raw_pos/location/location.csv
file_format = (format_name = 'nike_po_prod.public.csv_ff');

--> order_header
CREATE OR REPLACE TABLE nike_po_prod.raw_pos.order_header
(
    order_id NUMBER(38,0),
    truck_id NUMBER(38,0),
    location_id FLOAT,
    customer_id NUMBER(38,0),
    discount_id VARCHAR(16777216),
    shift_id NUMBER(38,0),
    shift_start_time TIME(9),
    shift_end_time TIME(9),
    order_channel VARCHAR(16777216),
    order_ts TIMESTAMP_NTZ(9),
    served_ts VARCHAR(16777216),
    order_currency VARCHAR(3),
    order_amount NUMBER(38,4),
    order_tax_amount VARCHAR(16777216),
    order_discount_amount VARCHAR(16777216),
    order_total NUMBER(38,4)
);

COPY INTO nike_po_prod.raw_pos.order_header
FROM @nike_po_prod.public.nike_data_stage/raw_pos/order_header
file_format = (format_name = 'nike_po_prod.public.csv_ff');


--> order_detail
CREATE OR REPLACE TABLE nike_po_prod.raw_pos.order_detail
(
	ORDER_DETAIL_ID NUMBER(38,0),
	ORDER_ID NUMBER(38,0),
	MENU_ITEM_ID NUMBER(38,0),
	DISCOUNT_ID VARCHAR(16777216),
	LINE_NUMBER NUMBER(38,0),
	QUANTITY NUMBER(5,0),
	UNIT_PRICE NUMBER(38,4),
	PRICE NUMBER(38,4),
	ORDER_ITEM_DISCOUNT_AMOUNT VARCHAR(16777216)
);

--> order_detail
COPY INTO nike_po_prod.raw_pos.order_detail
FROM @nike_po_prod.public.nike_data_stage/raw_pos/order_detail
file_format = (format_name = 'nike_po_prod.public.csv_ff');

/*---------------------------*/
-- create raw_customer table
/*---------------------------*/

--> customer_loyalty
CREATE OR REPLACE TABLE nike_po_prod.raw_customer.customer_loyalty
(
	CUSTOMER_ID NUMBER(38,0),
	FIRST_NAME VARCHAR(16777216),
	LAST_NAME VARCHAR(16777216),
	CITY VARCHAR(16777216),
	COUNTRY VARCHAR(16777216),
	POSTAL_CODE VARCHAR(16777216),
	PREFERRED_LANGUAGE VARCHAR(16777216),
	GENDER VARCHAR(16777216),
	FAVOURITE_BRAND VARCHAR(16777216),
	MARITAL_STATUS VARCHAR(16777216),
	CHILDREN_COUNT VARCHAR(16777216),
	SIGN_UP_DATE DATE,
	BIRTHDAY_DATE DATE,
	E_MAIL VARCHAR(16777216),
	PHONE_NUMBER VARCHAR(16777216)
);

-- --> customer_loyalty
-- NOTE: No raw_customer data available in Nike dataset
-- COPY INTO nike_po_prod.raw_customer.customer_loyalty
-- FROM @nike_po_prod.public.nike_data_stage/csv/raw_customer/customer_loyalty
-- file_format = (format_name = 'nike_po_prod.public.csv_ff');

/*---------------------------*/
-- create raw_supply_chain tables
/*---------------------------*/

--> item
CREATE OR REPLACE TABLE nike_po_prod.raw_supply_chain.item
(
	ITEM_ID NUMBER(38,0),
	NAME VARCHAR(16777216),
	CATEGORY VARCHAR(16777216),
	UNIT VARCHAR(16777216),
	UNIT_PRICE NUMBER(38,9),
	UNIT_CURRENCY VARCHAR(16777216),
	SHELF_LIFE_DAYS NUMBER(38,0),
	VENDOR_ID NUMBER(38,0),
	IMAGE_URL VARCHAR(16777216)
);

--> item
COPY INTO nike_po_prod.raw_supply_chain.item 
FROM @nike_po_prod.public.nike_data_stage/csv/raw_supply_chain/item/item.csv
file_format = (format_name = 'nike_po_prod.public.csv_ff');


--> recipe
CREATE OR REPLACE TABLE nike_po_prod.raw_supply_chain.recipe
(
	RECIPE_ID NUMBER(38,0),
	MENU_ITEM_ID NUMBER(38,0),
	MENU_ITEM_LINE_ITEM NUMBER(38,0),
	ITEM_ID NUMBER(38,0),
	UNIT_QUANTITY NUMBER(38,9)
);

--> recipe
COPY INTO nike_po_prod.raw_supply_chain.recipe 
FROM @nike_po_prod.public.nike_data_stage/csv/raw_supply_chain/recipe/recipe.csv
file_format = (format_name = 'nike_po_prod.public.csv_ff');

--> item_prices
CREATE OR REPLACE TABLE nike_po_prod.raw_supply_chain.item_prices
(
	ITEM_ID NUMBER(38,0),
	UNIT_PRICE NUMBER(38,2),
	START_DATE DATE,
	END_DATE DATE
);

--> item_prices
COPY INTO nike_po_prod.raw_supply_chain.item_prices 
FROM @nike_po_prod.public.nike_data_stage/csv/raw_supply_chain/item_prices/item_prices.csv
file_format = (format_name = 'nike_po_prod.public.csv_ff');

--> price_elasticity
CREATE OR REPLACE TABLE nike_po_prod.raw_supply_chain.price_elasticity
(
	PE_ID NUMBER(11,0),
	MENU_ITEM_ID NUMBER(38,0),
	PRICE NUMBER(38,2),
	CURRENCY VARCHAR(3),
	FROM_DATE DATE,
	THROUGH_DATE DATE,
	DAY_OF_WEEK NUMBER(2,0)
);

--> price_elasticity
COPY INTO nike_po_prod.raw_supply_chain.price_elasticity 
FROM @nike_po_prod.public.nike_data_stage/csv/raw_supply_chain/price_elasticity/price_elasticity.csv
file_format = (format_name = 'nike_po_prod.public.csv_ff');

--> menu_prices
CREATE OR REPLACE TABLE nike_po_prod.raw_supply_chain.menu_prices
(
	MENU_ITEM_ID NUMBER(38,0),
	SALES_PRICE_USD NUMBER(38,2),
	START_DATE DATE,
	END_DATE DATE
);

--> menu_prices
COPY INTO nike_po_prod.raw_supply_chain.menu_prices 
FROM @nike_po_prod.public.nike_data_stage/csv/raw_supply_chain/menu_prices/menu_prices.csv
file_format = (format_name = 'nike_po_prod.public.csv_ff');

/*---------------------------*/
-- create raw_safegraph table
/*---------------------------*/

create or replace TABLE nike_po_prod.raw_safegraph.core_poi_geometry (
	PLACEKEY VARCHAR(16777216),
	PARENT_PLACEKEY VARCHAR(16777216),
	SAFEGRAPH_BRAND_IDS VARCHAR(16777216),
	LOCATION_NAME VARCHAR(16777216),
	BRANDS VARCHAR(16777216),
	STORE_ID VARCHAR(16777216),
	TOP_CATEGORY VARCHAR(16777216),
	SUB_CATEGORY VARCHAR(16777216),
	NAICS_CODE NUMBER(38,0),
	LATITUDE FLOAT,
	LONGITUDE FLOAT,
	STREET_ADDRESS VARCHAR(16777216),
	CITY VARCHAR(16777216),
	REGION VARCHAR(16777216),
	POSTAL_CODE VARCHAR(16777216),
	OPEN_HOURS VARIANT,
	CATEGORY_TAGS VARCHAR(16777216),
	OPENED_ON VARCHAR(16777216),
	CLOSED_ON VARCHAR(16777216),
	TRACKING_CLOSED_SINCE VARCHAR(16777216),
	GEOMETRY_TYPE VARCHAR(16777216),
	POLYGON_WKT VARCHAR(16777216),
	POLYGON_CLASS VARCHAR(16777216),
	ENCLOSED BOOLEAN,
	PHONE_NUMBER VARCHAR(16777216),
	IS_SYNTHETIC BOOLEAN,
	INCLUDES_PARKING_LOT BOOLEAN,
	ISO_COUNTRY_CODE VARCHAR(16777216),
	WKT_AREA_SQ_METERS FLOAT,
	COUNTRY VARCHAR(16777216)
);

--> core_poi_geometry
COPY INTO nike_po_prod.raw_safegraph.core_poi_geometry
FROM @nike_po_prod.public.nike_data_stage/csv/raw_safegraph/core_poi_geometry.csv
file_format = (format_name = 'nike_po_prod.public.csv_ff');

/*---------------------------*/
-- harmonized views
/*---------------------------*/

--> harmonized orders_v
create or replace view NIKE_PO_PROD.HARMONIZED.ORDERS_V(
	ORDER_ID,
	TRUCK_ID,
	ORDER_TS,
	ORDER_DETAIL_ID,
	LINE_NUMBER,
	TRUCK_BRAND_NAME,
	MENU_TYPE,
	PRIMARY_CITY,
	REGION,
	COUNTRY,
	FRANCHISE_FLAG,
	FRANCHISE_ID,
	FRANCHISEE_FIRST_NAME,
	FRANCHISEE_LAST_NAME,
	LOCATION_ID,
	PLACEKEY,
	LOCATION_NAME,
	TOP_CATEGORY,
	SUB_CATEGORY,
	LATITUDE,
	LONGITUDE,
	CUSTOMER_ID,
	FIRST_NAME,
	LAST_NAME,
	E_MAIL,
	PHONE_NUMBER,
	CHILDREN_COUNT,
	GENDER,
	MARITAL_STATUS,
	MENU_ITEM_ID,
	MENU_ITEM_NAME,
	QUANTITY,
	UNIT_PRICE,
	PRICE,
	ORDER_AMOUNT,
	ORDER_TAX_AMOUNT,
	ORDER_DISCOUNT_AMOUNT,
	ORDER_TOTAL
) as (


SELECT
    oh.order_id,
    oh.truck_id,
    oh.order_ts,
    od.order_detail_id,
    od.line_number,
    m.truck_brand_name,
    m.menu_type,
    t.primary_city,
    t.region,
    t.country,
    t.franchise_flag,
    t.franchise_id,
    f.first_name AS franchisee_first_name,
    f.last_name AS franchisee_last_name,
    l.location_id,
    cpg.placekey,
    cpg.location_name,
    cpg.top_category,
    cpg.sub_category,
    cpg.latitude,
    cpg.longitude,
    cl.customer_id,
    cl.first_name,
    cl.last_name,
    cl.e_mail,
    cl.phone_number,
    cl.children_count,
    cl.gender,
    cl.marital_status,
    od.menu_item_id,
    m.menu_item_name,
    od.quantity,
    od.unit_price,
    od.price,
    oh.order_amount,
    oh.order_tax_amount,
    oh.order_discount_amount,
    oh.order_total
FROM NIKE_PO_PROD.raw_pos.ORDER_DETAIL od
JOIN NIKE_PO_PROD.raw_pos.ORDER_HEADER oh
    ON od.order_id = oh.order_id
JOIN NIKE_PO_PROD.raw_pos.TRUCK t
    ON oh.truck_id = t.truck_id
JOIN NIKE_PO_PROD.raw_pos.MENU m
    ON od.menu_item_id = m.menu_item_id
JOIN NIKE_PO_PROD.raw_pos.FRANCHISE f
    ON t.franchise_id = f.franchise_id
JOIN NIKE_PO_PROD.raw_pos.LOCATION l
    ON oh.location_id = l.location_id
JOIN NIKE_PO_PROD.raw_safegraph.CORE_POI_GEOMETRY cpg
    ON cpg.placekey = l.placekey
LEFT JOIN NIKE_PO_PROD.raw_customer.CUSTOMER_LOYALTY cl
    ON oh.customer_id = cl.customer_id
  );

--> menu_item_cogs_and_price_v
CREATE OR REPLACE VIEW nike_po_prod.harmonized.menu_item_cogs_and_price_v
	AS
SELECT DISTINCT
    r.menu_item_id,
    ip.start_date,
    ip.end_date,
    SUM(ip.unit_price * r.unit_quantity)
        OVER (PARTITION BY r.menu_item_id, ip.start_date, ip.end_date)
            AS cost_of_menu_item_usd,
    mp.sales_price_usd
FROM nike_po_prod.raw_supply_chain.ITEM i
JOIN nike_po_prod.raw_supply_chain.RECIPE r
    ON i.item_id = r.item_id
JOIN nike_po_prod.raw_supply_chain.ITEM_PRICES ip
    ON ip.item_id = r.item_id
JOIN nike_po_prod.raw_supply_chain.MENU_PRICES mp
    ON mp.menu_item_id = r.menu_item_id
    AND mp.start_date = ip.start_date
ORDER BY r.menu_item_id, ip.start_date
  ;

--> order_item_cost_v
CREATE OR REPLACE VIEW nike_po_prod.harmonized.order_item_cost_v
	AS
WITH menu_item_cogs_and_price_v AS
(
    SELECT DISTINCT
        r.menu_item_id,
        ip.start_date,
        ip.end_date,
        SUM(ip.unit_price * r.unit_quantity) OVER (PARTITION BY r.menu_item_id, ip.start_date, ip.end_date) AS cost_of_goods_usd,
        mp.sales_price_usd AS base_price
    FROM nike_po_prod.raw_supply_chain.item i
    JOIN nike_po_prod.raw_supply_chain.recipe r
        ON i.item_id = r.item_id
    JOIN nike_po_prod.raw_supply_chain.item_prices ip
        ON ip.item_id = r.item_id
    JOIN nike_po_prod.raw_supply_chain.menu_prices mp
        ON mp.menu_item_id = r.menu_item_id
        AND mp.start_date = ip.start_date
    JOIN nike_po_prod.raw_pos.menu m
        ON m.menu_item_id = mp.menu_item_id
    WHERE m.item_category <> 'Extra'
),
order_item_total AS
(
    SELECT
        oh.order_id,
        oh.order_ts,
        od.menu_item_id,
        od.quantity,
        m.base_price AS price,
        m.cost_of_goods_usd,
        m.base_price * od.quantity AS order_item_tot,
        oh.order_amount,
        m.cost_of_goods_usd * od.quantity AS order_item_cog,
        SUM(order_item_cog) OVER (PARTITION BY oh.order_id) AS order_cog
    FROM nike_po_prod.raw_pos.order_header oh
    JOIN nike_po_prod.raw_pos.order_detail od
        ON oh.order_id = od.order_id
    JOIN menu_item_cogs_and_price_v m
        ON od.menu_item_id = m.menu_item_id
        AND DATE(oh.order_ts) BETWEEN m.start_date AND m.end_date
)
SELECT
        oi.order_id,
        DATE(oi.order_ts) AS date,
        oi.menu_item_id,
        oi.quantity,
        oi.price,
        oi.cost_of_goods_usd,
        oi.order_item_tot,
        oi.order_item_cog,
        oi.order_amount,
        oi.order_cog,
        oi.order_amount - oi.order_item_tot AS order_amt_wo_item,
        oi.order_cog - oi.order_item_cog AS order_cog_wo_item
FROM order_item_total oi
  ;

--> menu_item_aggregate_dt
CREATE OR REPLACE TABLE NIKE_PO_PROD.HARMONIZED.MENU_ITEM_AGGREGATE_DT (
	DATE DATE,
	DAY_OF_WEEK NUMBER(2,0),
	MENU_TYPE_ID NUMBER(38,0),
	TRUCK_BRAND_NAME VARCHAR(16777216),
	MENU_ITEM_ID NUMBER(38,0),
	MENU_ITEM_NAME VARCHAR(16777216),
	SALE_PRICE NUMBER(38,2),
	BASE_PRICE NUMBER(38,2),
	COST_OF_GOODS_USD NUMBER(38,2),
	COUNT_ORDERS NUMBER(18,0),
	TOTAL_QUANTITY_SOLD NUMBER(17,0),
	COMPETITOR_PRICE VARCHAR(16777216)
);

--> menu_item_aggregate_dt
COPY INTO nike_po_prod.harmonized.menu_item_aggregate_dt
FROM @nike_po_prod.public.nike_data_stage/csv/harmonized/menu_item_aggregate_dt/menu_item_aggregate_dt.csv
file_format = (format_name = 'nike_po_prod.public.csv_ff');

/*---------------------------*/
-- analytics views
/*---------------------------*/

--> orders_v
create or replace view NIKE_PO_PROD.ANALYTICS.ORDERS_V(
	DATE,
	ORDER_ID,
	TRUCK_ID,
	ORDER_TS,
	ORDER_DETAIL_ID,
	LINE_NUMBER,
	TRUCK_BRAND_NAME,
	MENU_TYPE,
	PRIMARY_CITY,
	REGION,
	COUNTRY,
	FRANCHISE_FLAG,
	FRANCHISE_ID,
	FRANCHISEE_FIRST_NAME,
	FRANCHISEE_LAST_NAME,
	LOCATION_ID,
	PLACEKEY,
	LOCATION_NAME,
	TOP_CATEGORY,
	SUB_CATEGORY,
	LATITUDE,
	LONGITUDE,
	CUSTOMER_ID,
	FIRST_NAME,
	LAST_NAME,
	E_MAIL,
	PHONE_NUMBER,
	CHILDREN_COUNT,
	GENDER,
	MARITAL_STATUS,
	MENU_ITEM_ID,
	MENU_ITEM_NAME,
	QUANTITY,
	UNIT_PRICE,
	PRICE,
	ORDER_AMOUNT,
	ORDER_TAX_AMOUNT,
	ORDER_DISCOUNT_AMOUNT,
	ORDER_TOTAL
) as (


SELECT DATE(o.order_ts) AS date, * FROM NIKE_PO_PROD.harmonized.ORDERS_V o
  );

--> menu_item_aggregate_v
CREATE OR REPLACE VIEW nike_po_prod.analytics.menu_item_aggregate_v
	AS
SELECT * RENAME sale_price AS price
FROM nike_po_prod.harmonized.menu_item_aggregate_dt; -- should be menu_item_aggregate_dt



--> menu_item_cogs_and_price_v
CREATE OR REPLACE VIEW nike_po_prod.analytics.menu_item_cogs_and_price_v
	AS
SELECT * FROM nike_po_prod.harmonized.menu_item_cogs_and_price_v;

--> order_item_cost_agg_v
CREATE OR REPLACE VIEW nike_po_prod.analytics.order_item_cost_agg_v
	AS
SELECT
    year,
    month,
    menu_item_id,
	avg_revenue_wo_item,
    avg_cost_wo_item,
    avg_profit_wo_item,
	LAG(avg_revenue_wo_item,1) OVER (PARTITION BY menu_item_id ORDER BY year,month) AS prev_avg_revenue_wo_item,
    LAG(avg_cost_wo_item,1) OVER (PARTITION BY menu_item_id ORDER BY year,month) AS prev_avg_cost_wo_item,
    LAG(avg_profit_wo_item,1) OVER (PARTITION BY menu_item_id ORDER BY year,month) AS prev_avg_profit_wo_item
FROM
(SELECT * FROM (
    (
        SELECT
            oic1.menu_item_id,
            YEAR(oic1.date) AS year,
            MONTH(oic1.date) AS month,
            SUM(oic1.order_amt_wo_item) / SUM(oic1.quantity) AS avg_revenue_wo_item,
            SUM(oic1.order_cog_wo_item) / SUM(oic1.quantity) AS avg_cost_wo_item,
            (SUM(oic1.order_amt_wo_item) - SUM(oic1.order_cog_wo_item)) /SUM(oic1.quantity) AS avg_profit_wo_item
        FROM nike_po_prod.harmonized.order_item_cost_v oic1
        GROUP BY oic1.menu_item_id, YEAR(oic1.date), MONTH(oic1.date)
    )
UNION
    (
    SELECT
            oic2.menu_item_id,
            CASE
                WHEN max_date.max_month = 12 THEN max_date.max_year + 1
            ELSE max_date.max_year
            END AS year,
            CASE
                WHEN max_date.max_month = 12 THEN 1
            ELSE max_date.max_month + 1
            END AS month,
            0 AS avg_revenue_wo_item,
            0 AS avg_cost_wo_item,
            0 AS avg_profit_wo_item
    FROM (
            SELECT DISTINCT
                oh.menu_item_id,
                DATE(oh.order_ts) AS date
            FROM nike_po_prod.harmonized.orders_v oh
        ) oic2
    JOIN
        (
        SELECT
            MONTH(MAX(DATE(oh.order_ts))) AS max_month,
            YEAR(MAX(DATE(oh.order_ts))) AS max_year
        FROM nike_po_prod.harmonized.orders_v oh
        ) max_date
ON YEAR(oic2.date) = max_date.max_year AND MONTH(oic2.date) = max_date.max_month
    )
) oic
ORDER BY oic.menu_item_id, oic.year, oic.month)avg_r_c_wo_item;


/*---------------------------*/
-- scale down warehouse after load
/*---------------------------*/
ALTER WAREHOUSE nike_po_ds_wh SET WAREHOUSE_SIZE = 'Large';


/*---------------------------*/
-- NIKE REVIEWS DATABASE SETUP
/*---------------------------*/
-- This section creates the Nike reviews database for customer sentiment analysis
-- using Snowflake Cortex LLM functions

USE ROLE sysadmin;

/*--
 • nike reviews database, schema and warehouse creation
--*/

-- create nike_reviews database
CREATE OR REPLACE DATABASE nike_reviews;

-- create raw_pos schema  
CREATE OR REPLACE SCHEMA nike_reviews.raw_pos;

-- create raw_customer schema
CREATE OR REPLACE SCHEMA nike_reviews.raw_support;

-- create harmonized schema
CREATE OR REPLACE SCHEMA nike_reviews.harmonized;

-- create analytics schema
CREATE OR REPLACE SCHEMA nike_reviews.analytics;

-- create nike_ds_wh warehouse
CREATE OR REPLACE WAREHOUSE nike_ds_wh
    WAREHOUSE_SIZE = 'large'
    WAREHOUSE_TYPE = 'standard'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
COMMENT = 'data science warehouse for nike reviews';

USE WAREHOUSE nike_ds_wh;

/*--
 • file format creation for reviews
--*/

CREATE OR REPLACE FILE FORMAT nike_reviews.public.csv_ff 
type = 'csv';

/*--
 • raw zone table build for reviews
--*/

-- products table build
CREATE OR REPLACE TABLE nike_reviews.raw_pos.products
(
    product_id NUMBER(19,0),
    product_name VARCHAR(16777216),
    brand_name VARCHAR(16777216),
    category VARCHAR(16777216),
    subcategory VARCHAR(16777216),
    cost_usd NUMBER(38,4),
    price_usd NUMBER(38,4),
    product_image_url VARCHAR(16777216),
    product_specs VARIANT
);

-- stores table build 
CREATE OR REPLACE TABLE nike_reviews.raw_pos.stores
(
    store_id NUMBER(38,0),
    store_name VARCHAR(16777216),
    city VARCHAR(16777216),
    region VARCHAR(16777216),
    country VARCHAR(16777216),
    store_type VARCHAR(16777216), -- retail, outlet, flagship
    opening_date DATE
);

-- orders table build
CREATE OR REPLACE TABLE nike_reviews.raw_pos.orders
(
    order_id NUMBER(38,0),
    store_id NUMBER(38,0),
    customer_id NUMBER(38,0),
    product_id NUMBER(38,0),
    order_date DATE,
    quantity NUMBER(38,0),
    unit_price NUMBER(38,4),
    total_amount NUMBER(38,4),
    order_channel VARCHAR(16777216) -- online, in-store, mobile
);

-- product_reviews table build
CREATE OR REPLACE TABLE nike_reviews.raw_support.product_reviews
(
    review_id NUMBER(18,0),
    order_id NUMBER(38,0),
    product_id NUMBER(38,0),
    customer_id NUMBER(38,0),
    language VARCHAR(16777216),
    source VARCHAR(16777216), -- website, app, email, social
    review_text VARCHAR(16777216),
    rating NUMBER(2,1), -- 1.0 to 5.0
    review_date DATE,
    verified_purchase BOOLEAN DEFAULT TRUE
);

/*--
 • harmonized view creation for reviews
--*/

-- product_reviews_v view
CREATE OR REPLACE VIEW nike_reviews.harmonized.product_reviews_v
    AS
SELECT DISTINCT
    r.review_id,
    r.order_id,
    r.product_id,
    r.customer_id,
    r.language,
    r.source,
    r.review_text,
    r.rating,
    r.review_date,
    r.verified_purchase,
    p.product_name,
    p.brand_name,
    p.category,
    p.subcategory,
    p.price_usd,
    p.product_image_url,
    s.store_name,
    s.city,
    s.region,
    s.country,
    o.order_channel
FROM nike_reviews.raw_support.product_reviews r
JOIN nike_reviews.raw_pos.products p
    ON p.product_id = r.product_id
LEFT JOIN nike_reviews.raw_pos.orders o
    ON o.order_id = r.order_id
LEFT JOIN nike_reviews.raw_pos.stores s
    ON s.store_id = o.store_id;

/*--
 • analytics view creation for reviews
--*/

-- product_reviews_v view for analytics
CREATE OR REPLACE VIEW nike_reviews.analytics.product_reviews_v
    AS
SELECT * FROM harmonized.product_reviews_v;

-- sentiment analytics view
CREATE OR REPLACE VIEW nike_reviews.analytics.product_sentiment_v
    AS
SELECT 
    product_id,
    product_name,
    brand_name,
    category,
    COUNT(*) as total_reviews,
    AVG(rating) as avg_rating,
    ROUND(AVG(rating), 2) as avg_rating_rounded,
    COUNT(CASE WHEN rating >= 4.0 THEN 1 END) as positive_reviews,
    COUNT(CASE WHEN rating <= 2.0 THEN 1 END) as negative_reviews,
    COUNT(CASE WHEN rating > 2.0 AND rating < 4.0 THEN 1 END) as neutral_reviews
FROM nike_reviews.harmonized.product_reviews_v
GROUP BY product_id, product_name, brand_name, category;

/*--
 • sample data insertion for reviews demo
--*/

-- Insert sample products
INSERT INTO nike_reviews.raw_pos.products VALUES
(1, 'Air Force 1 07', 'Nike Sportswear', 'Footwear', 'Lifestyle', 45.00, 110.00, 'https://static.nike.com/a/images/t_PDP_1280_v1/air-force-1.png', '{"material": "leather", "color": "white"}'),
(2, 'Air Max 90', 'Nike Sportswear', 'Footwear', 'Lifestyle', 55.00, 135.00, 'https://static.nike.com/a/images/t_PDP_1280_v1/air-max-90.png', '{"material": "mesh", "color": "white"}'),
(3, 'Air Zoom Pegasus 40', 'Nike Running', 'Footwear', 'Running', 60.00, 140.00, 'https://static.nike.com/a/images/t_PDP_1280_v1/pegasus-40.png', '{"material": "flyknit", "color": "black"}'),
(4, 'Metcon 9', 'Nike Training', 'Footwear', 'Training', 65.00, 150.00, 'https://static.nike.com/a/images/t_PDP_1280_v1/metcon-9.png', '{"material": "synthetic", "color": "gray"}'),
(5, 'Air Jordan 1 Low', 'Nike Jordan', 'Footwear', 'Basketball', 50.00, 120.00, 'https://static.nike.com/a/images/t_PDP_1280_v1/jordan-1-low.png', '{"material": "leather", "color": "bred"}'),
(6, 'Tech Fleece Hoodie', 'Nike Tech', 'Apparel', 'Hoodies', 40.00, 100.00, 'https://static.nike.com/a/images/t_PDP_1280_v1/tech-fleece.png', '{"material": "fleece", "color": "black"}'),
(7, 'Dunk Low', 'Nike SB', 'Footwear', 'Lifestyle', 45.00, 130.00, 'https://static.nike.com/a/images/t_PDP_1280_v1/dunk-low.png', '{"material": "leather", "color": "panda"}');

-- Insert sample stores
INSERT INTO nike_reviews.raw_pos.stores VALUES
(1, 'Nike Store Manhattan', 'New York', 'NY', 'USA', 'flagship', '2020-01-01'),
(2, 'Nike Outlet Los Angeles', 'Los Angeles', 'CA', 'USA', 'outlet', '2019-06-15'),
(3, 'Nike Store Chicago', 'Chicago', 'IL', 'USA', 'retail', '2021-03-10');

-- Insert sample orders
INSERT INTO nike_reviews.raw_pos.orders VALUES
(1001, 1, 1001, 1, '2024-01-15', 1, 110.00, 110.00, 'in-store'),
(1002, 2, 1002, 2, '2024-01-16', 1, 135.00, 135.00, 'online'),
(1003, 1, 1003, 3, '2024-01-17', 1, 140.00, 140.00, 'mobile'),
(1004, 3, 1004, 4, '2024-01-18', 1, 150.00, 150.00, 'in-store'),
(1005, 1, 1005, 5, '2024-01-19', 1, 120.00, 120.00, 'online');

-- Insert initial sample reviews
INSERT INTO nike_reviews.raw_support.product_reviews VALUES
(1, 1001, 1, 1001, 'en', 'website', 'Love these Air Force 1s! Classic design, great comfort, and they go with everything. Definitely recommend!', 5.0, '2024-01-20', TRUE),
(2, 1002, 2, 1002, 'en', 'app', 'Air Max 90s are comfortable but sizing runs a bit large. Quality is good overall.', 4.0, '2024-01-21', TRUE),
(3, 1003, 3, 1003, 'en', 'website', 'Best running shoes ever! Pegasus 40 has amazing cushioning and perfect for daily runs.', 5.0, '2024-01-22', TRUE),
(4, 1004, 4, 1004, 'en', 'email', 'Metcon 9 is solid for cross-training. Good stability but break-in period was tough.', 4.0, '2024-01-23', TRUE),
(5, 1005, 5, 1005, 'en', 'social', 'Jordan 1 Low quality disappointing. Leather feels cheap for the price point.', 2.0, '2024-01-24', TRUE),
(6, NULL, 6, 1006, 'es', 'website', 'La sudadera Tech Fleece es muy cómoda y cálida. Excelente calidad.', 5.0, '2024-01-25', FALSE),
(7, NULL, 7, 1007, 'fr', 'app', 'Les Dunk Low sont parfaites. Style incroyable et très confortables.', 4.5, '2024-01-26', FALSE);

/*--
 • extended sample review data (150+ reviews for comprehensive testing)
--*/

-- Additional generated Nike product reviews (continuing from review_id 8)
INSERT INTO nike_reviews.raw_support.product_reviews VALUES 
(8, NULL, 6, 1008, 'en', 'app', 'Decent Tech Fleece Hoodie. Nothing special but they''re fine.', 2.6, '2024-05-03', TRUE),
(9, NULL, 6, 1009, 'en', 'app', 'Average Tech Fleece Hoodie. They''re alright for the price.', 3.7, '2024-09-26', FALSE),
(10, NULL, 7, 1010, 'es', 'email', '¡Fantásticas Dunk Low! Súper cómodas y se ven geniales.', 5.0, '2024-04-09', FALSE),
(11, 1227, 6, 1011, 'en', 'app', 'Excellent Tech Fleece Hoodie! Great value for money and superior comfort.', 4.7, '2024-10-08', TRUE),
(12, NULL, 1, 1012, 'en', 'website', 'Perfect Air Force 1 ''07! Exactly what I was looking for. Great design and comfort.', 4.6, '2024-10-17', TRUE),
(13, NULL, 4, 1013, 'es', 'website', 'Perfectas Metcon 9! Justo lo que buscaba. Gran diseño.', 4.8, '2024-12-23', TRUE),
(14, 1913, 1, 1014, 'en', 'website', 'Fantastic Air Force 1 ''07! Comfortable, stylish, and well-made. Love them!', 4.4, '2024-02-22', FALSE),
(15, NULL, 6, 1015, 'en', 'app', 'Bad Tech Fleece Hoodie. Sizing is off and comfort is lacking.', 2.2, '2024-09-21', TRUE),
(16, NULL, 1, 1016, 'en', 'email', 'Terrible Air Force 1 ''07! Overpriced and uncomfortable to wear.', 1.9, '2024-04-18', TRUE),
(17, 1114, 5, 1017, 'en', 'app', 'Excellent Air Jordan 1 Low! Great value for money and superior comfort.', 5.0, '2024-04-17', TRUE),
(18, NULL, 2, 1018, 'fr', 'social', 'Parfaites Air Max 90! Qualité exceptionnelle et bon ajustement.', 4.8, '2024-10-19', FALSE),
(19, 1412, 4, 1019, 'en', 'website', 'These Metcon 9 are fine. Not great, not terrible.', 3.8, '2024-11-02', TRUE),
(20, 1511, 5, 1020, 'es', 'email', 'Terribles Air Jordan 1 Low. Mal ajuste y materiales baratos.', 2.0, '2024-04-08', TRUE),
(21, 1444, 6, 1021, 'fr', 'social', 'Incroyables Tech Fleece Hoodie! Exactement ce que je cherchais.', 4.2, '2024-11-07', FALSE),
(22, NULL, 1, 1022, 'en', 'email', 'Okay Air Force 1 ''07. Could be better but acceptable.', 2.6, '2024-08-15', TRUE),
(23, NULL, 5, 1023, 'en', 'social', 'Beautiful Air Jordan 1 Low! Perfect for daily wear and very comfortable.', 4.2, '2024-03-01', TRUE),
(24, 1324, 1, 1024, 'es', 'social', 'Perfectas Air Force 1 ''07! Justo lo que buscaba. Gran diseño.', 4.3, '2024-06-14', FALSE),
(25, 1945, 7, 1025, 'es', 'social', 'Estas Dunk Low están bien. Calidad y comodidad promedio.', 3.2, '2024-03-16', TRUE),
(26, 1744, 6, 1026, 'es', 'app', '¡Fantásticas Tech Fleece Hoodie! Súper cómodas y se ven geniales.', 5.0, '2024-04-23', TRUE),
(27, NULL, 4, 1027, 'en', 'email', 'Okay Metcon 9. Could be better but acceptable.', 3.5, '2024-10-03', TRUE),
(28, NULL, 7, 1028, 'en', 'website', 'Average Dunk Low. They''re alright for the price.', 3.6, '2024-09-10', TRUE),
(29, 1223, 4, 1029, 'en', 'email', 'Excellent Metcon 9! Great value for money and superior comfort.', 4.8, '2024-08-05', TRUE),
(30, 1540, 7, 1030, 'en', 'email', 'Amazing Dunk Low! Great quality and perfect fit. Worth every penny.', 4.0, '2024-12-28', TRUE),
(31, NULL, 3, 1031, 'es', 'app', 'Excelente Air Zoom Pegasus 40! Calidad superior y ajuste perfecto.', 4.5, '2024-06-16', FALSE),
(32, 1263, 1, 1032, 'es', 'app', 'Terribles Air Force 1 ''07. Mal ajuste y materiales baratos.', 2.2, '2024-01-16', TRUE),
(33, 1132, 2, 1033, 'en', 'app', 'These Air Max 90 are okay. Average quality and comfort.', 3.8, '2024-06-14', TRUE),
(34, NULL, 6, 1034, 'en', 'website', 'Poor quality Tech Fleece Hoodie. Expected much better for this price.', 2.0, '2024-08-10', TRUE),
(35, 1060, 5, 1035, 'en', 'social', 'Poor quality Air Jordan 1 Low. Expected much better for this price.', 1.1, '2024-08-18', TRUE),
(36, 1563, 3, 1036, 'en', 'website', 'Incredible Air Zoom Pegasus 40! Best purchase I''ve made in a while. Top quality!', 4.4, '2024-09-16', TRUE),
(37, 1366, 3, 1037, 'en', 'app', 'Average Air Zoom Pegasus 40. They''re alright for the price.', 3.4, '2024-05-19', TRUE),
(38, NULL, 4, 1038, 'fr', 'app', 'Incroyables Metcon 9! Exactement ce que je cherchais.', 4.9, '2024-03-24', FALSE),
(39, NULL, 5, 1039, 'es', 'social', '¡Increíbles Air Jordan 1 Low! Muy cómodas y con estilo perfecto.', 4.8, '2024-05-21', FALSE),
(40, NULL, 7, 1040, 'fr', 'website', 'Incroyables Dunk Low! Exactement ce que je cherchais.', 4.3, '2024-02-02', FALSE),
(41, NULL, 1, 1041, 'en', 'email', 'Incredible Air Force 1 ''07! Best purchase I''ve made in a while. Top quality!', 5.0, '2024-12-07', TRUE),
(42, 1048, 5, 1042, 'en', 'social', 'Perfect Air Jordan 1 Low! Exactly what I was looking for. Great design and comfort.', 4.6, '2024-12-25', TRUE),
(43, 1319, 7, 1043, 'es', 'app', '¡Fantásticas Dunk Low! Súper cómodas y se ven geniales.', 5.0, '2024-02-25', TRUE),
(44, 1118, 1, 1044, 'en', 'social', 'Disappointing Air Force 1 ''07. Materials feel cheap and sizing is wrong.', 1.2, '2024-09-26', FALSE),
(45, 1794, 5, 1045, 'en', 'website', 'Amazing Air Jordan 1 Low! Great quality and perfect fit. Worth every penny.', 4.5, '2024-01-19', FALSE),
(46, NULL, 7, 1046, 'es', 'website', '¡Increíbles Dunk Low! Muy cómodas y con estilo perfecto.', 4.4, '2024-11-09', FALSE),
(47, NULL, 7, 1047, 'es', 'website', '¡Increíbles Dunk Low! Muy cómodas y con estilo perfecto.', 4.9, '2024-09-06', FALSE),
(48, 1490, 4, 1048, 'en', 'website', 'Incredible Metcon 9! Best purchase I''ve made in a while. Top quality!', 4.3, '2024-02-19', TRUE),
(49, NULL, 3, 1049, 'en', 'social', 'Love these Air Zoom Pegasus 40! Excellent comfort and style. Highly recommend!', 4.1, '2024-05-21', FALSE),
(50, NULL, 6, 1050, 'es', 'social', '¡Fantásticas Tech Fleece Hoodie! Súper cómodas y se ven geniales.', 4.1, '2024-02-29', TRUE),
(51, NULL, 2, 1051, 'es', 'social', 'Excelente Air Max 90! Calidad superior y ajuste perfecto.', 4.7, '2024-01-30', TRUE),
(52, NULL, 7, 1052, 'en', 'app', 'Amazing Dunk Low! Great quality and perfect fit. Worth every penny.', 4.7, '2024-09-09', FALSE),
(53, NULL, 7, 1053, 'en', 'website', 'Beautiful Dunk Low! Perfect for daily wear and very comfortable.', 4.3, '2024-04-07', TRUE),
(54, 1575, 5, 1054, 'es', 'email', '¡Increíbles Air Jordan 1 Low! Muy cómodas y con estilo perfecto.', 4.3, '2024-05-02', FALSE),
(55, NULL, 4, 1055, 'en', 'email', 'Beautiful Metcon 9! Perfect for daily wear and very comfortable.', 4.0, '2024-06-23', TRUE);

-- scale wh to medium
ALTER WAREHOUSE nike_ds_wh SET WAREHOUSE_SIZE = 'Medium';

/*---------------------------*/
-- sql completion note
/*---------------------------*/
SELECT 'Nike Analytics Platform setup is now complete! Both price optimization and customer reviews databases are ready.' AS note;
