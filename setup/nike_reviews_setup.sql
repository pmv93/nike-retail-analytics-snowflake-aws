/***************************************************************************************************
  _   _ _ _         ____       _        _ _   ____            _                   
 | \ | (_) | _____|  _ \ ___ | |_ __ _(_) | |  _ \ _____   _(_) _____      _____ 
 |  \| | | |/ / _ \ |_) / _ \| __/ _` | | | | |_) / _ \ \ / / |/ _ \ \ /\ / / __|
 | |\  | |   <  __/  _ <  __/ || (_| | | | |  _ <  __/\ V /| |  __/\ V  V /\__ \
 |_| \_|_|_|\_\___|_| \_\___|\__\__,_|_|_| |_| \_\___| \_/ |_|\___| \_/\_/ |___/
                                                                               
Quickstart:   Nike Product Reviews Analytics using Snowflake Cortex
Version:      v1  
Script:       nike_reviews_setup.sql         
Create Date:  2025-01-15
Author:       AI Assistant
Copyright(c): 2025 Snowflake Inc. All rights reserved.
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2025-01-15          AI Assistant        Initial Release - Nike Product Reviews Analytics
***************************************************************************************************/

USE ROLE sysadmin;

/*--
 • database, schema and warehouse creation
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
 • file format and stage creation
--*/

CREATE OR REPLACE FILE FORMAT nike_reviews.public.csv_ff 
type = 'csv';

CREATE OR REPLACE STAGE nike_reviews.public.s3load
COMMENT = 'Nike Reviews S3 Stage Connection'
url = 's3://nike-reviews-data/'
file_format = nike_reviews.public.csv_ff;

/*--
 raw zone table build 
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
 • harmonized view creation
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
 • analytics view creation
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
 • sample data insertion for demo
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

-- Insert sample reviews
INSERT INTO nike_reviews.raw_support.product_reviews VALUES
(1, 1001, 1, 1001, 'en', 'website', 'Love these Air Force 1s! Classic design, great comfort, and they go with everything. Definitely recommend!', 5.0, '2024-01-20', TRUE),
(2, 1002, 2, 1002, 'en', 'app', 'Air Max 90s are comfortable but sizing runs a bit large. Quality is good overall.', 4.0, '2024-01-21', TRUE),
(3, 1003, 3, 1003, 'en', 'website', 'Best running shoes ever! Pegasus 40 has amazing cushioning and perfect for daily runs.', 5.0, '2024-01-22', TRUE),
(4, 1004, 4, 1004, 'en', 'email', 'Metcon 9 is solid for cross-training. Good stability but break-in period was tough.', 4.0, '2024-01-23', TRUE),
(5, 1005, 5, 1005, 'en', 'social', 'Jordan 1 Low quality disappointing. Leather feels cheap for the price point.', 2.0, '2024-01-24', TRUE),
(6, NULL, 6, 1006, 'es', 'website', 'La sudadera Tech Fleece es muy cómoda y cálida. Excelente calidad.', 5.0, '2024-01-25', FALSE),
(7, NULL, 7, 1007, 'fr', 'app', 'Les Dunk Low sont parfaites. Style incroyable et très confortables.', 4.5, '2024-01-26', FALSE);

-- scale wh to medium
ALTER WAREHOUSE nike_ds_wh SET WAREHOUSE_SIZE = 'Medium';

-- setup completion note
SELECT 'Nike Reviews setup is now complete' AS note; 