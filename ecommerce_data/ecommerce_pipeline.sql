-- This file builds the e-commerce data warehouse: staging, bronze, silver, gold.
-- Companion dataset/generator: ecommerce_data/  |  Architecture reference: the
-- published 'Medallion Architecture' diagram (staging -> bronze -> silver -> gold).

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'ecommerce_dw')
    CREATE DATABASE ecommerce_dw;
GO

USE ecommerce_dw;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'staging')
    EXEC('CREATE SCHEMA staging');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bronze')
    EXEC('CREATE SCHEMA bronze');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')
    EXEC('CREATE SCHEMA silver');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
    EXEC('CREATE SCHEMA gold');
GO

-- ============================================================
-- STAGING LAYER
-- ============================================================
-- 1:1 raw mirror of each source file. NVARCHAR(255), no constraints,
-- no cleaning. TRUNCATE + full reload every run (staging holds only
-- the current batch, never history).

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'staging' AND t.name = 'customers')
BEGIN
    CREATE TABLE staging.customers (
        customer_id NVARCHAR(255),
        first_name NVARCHAR(255),
        last_name NVARCHAR(255),
        email NVARCHAR(255),
        phone NVARCHAR(255),
        signup_date NVARCHAR(255),
        city NVARCHAR(255),
        state NVARCHAR(255),
        country NVARCHAR(255)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'staging' AND t.name = 'customer_profiles')
BEGIN
    CREATE TABLE staging.customer_profiles (
        profile_id NVARCHAR(255),
        customer_id NVARCHAR(255),
        email NVARCHAR(255),
        loyalty_tier NVARCHAR(255),
        marketing_opt_in NVARCHAR(255),
        preferred_channel NVARCHAR(255),
        birth_date NVARCHAR(255),
        gender NVARCHAR(255)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'staging' AND t.name = 'products')
BEGIN
    CREATE TABLE staging.products (
        product_id NVARCHAR(255),
        product_name NVARCHAR(255),
        category NVARCHAR(255),
        sub_category NVARCHAR(255),
        brand NVARCHAR(255),
        unit_price NVARCHAR(255),
        cost_price NVARCHAR(255)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'staging' AND t.name = 'product_inventory')
BEGIN
    CREATE TABLE staging.product_inventory (
        inventory_id NVARCHAR(255),
        product_id NVARCHAR(255),
        warehouse_location NVARCHAR(255),
        stock_quantity NVARCHAR(255),
        reorder_level NVARCHAR(255),
        supplier_name NVARCHAR(255),
        last_restock_date NVARCHAR(255)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'staging' AND t.name = 'orders')
BEGIN
    CREATE TABLE staging.orders (
        order_id NVARCHAR(255),
        customer_id NVARCHAR(255),
        order_date NVARCHAR(255),
        order_status NVARCHAR(255),
        channel NVARCHAR(255),
        shipping_city NVARCHAR(255),
        shipping_state NVARCHAR(255)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'staging' AND t.name = 'order_items')
BEGIN
    CREATE TABLE staging.order_items (
        order_item_id NVARCHAR(255),
        order_id NVARCHAR(255),
        product_id NVARCHAR(255),
        quantity NVARCHAR(255),
        unit_price NVARCHAR(255),
        discount_pct NVARCHAR(255)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'staging' AND t.name = 'payments')
BEGIN
    CREATE TABLE staging.payments (
        payment_id NVARCHAR(255),
        order_id NVARCHAR(255),
        payment_method NVARCHAR(255),
        amount NVARCHAR(255),
        payment_date NVARCHAR(255),
        payment_status NVARCHAR(255)
    );
END;
GO

-- Truncate + reload every staging table from its current batch file.
TRUNCATE TABLE staging.customers;

BULK INSERT staging.customers
FROM 'C:\Users\waleed\Documents\data_warehouse_project\ecommerce_data\batches\customers_batch1.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    CODEPAGE = '65001',
    MAXERRORS = 0,
    ERRORFILE = 'C:\Users\waleed\Documents\data_warehouse_project\ecommerce_data\batches\customers_err.log'
);
GO

TRUNCATE TABLE staging.customer_profiles;

BULK INSERT staging.customer_profiles
FROM 'C:\Users\waleed\Documents\data_warehouse_project\ecommerce_data\batches\customer_profiles_batch1.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    CODEPAGE = '65001',
    MAXERRORS = 0,
    ERRORFILE = 'C:\Users\waleed\Documents\data_warehouse_project\ecommerce_data\batches\customer_profiles_err.log'
);
GO

TRUNCATE TABLE staging.products;

BULK INSERT staging.products
FROM 'C:\Users\waleed\Documents\data_warehouse_project\ecommerce_data\batches\products_batch1.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    CODEPAGE = '65001',
    MAXERRORS = 0,
    ERRORFILE = 'C:\Users\waleed\Documents\data_warehouse_project\ecommerce_data\batches\products_err.log'
);
GO

TRUNCATE TABLE staging.product_inventory;

BULK INSERT staging.product_inventory
FROM 'C:\Users\waleed\Documents\data_warehouse_project\ecommerce_data\batches\product_inventory_batch1.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    CODEPAGE = '65001',
    MAXERRORS = 0,
    ERRORFILE = 'C:\Users\waleed\Documents\data_warehouse_project\ecommerce_data\batches\product_inventory_err.log'
);
GO

TRUNCATE TABLE staging.orders;

BULK INSERT staging.orders
FROM 'C:\Users\waleed\Documents\data_warehouse_project\ecommerce_data\batches\orders_batch1.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    CODEPAGE = '65001',
    MAXERRORS = 0,
    ERRORFILE = 'C:\Users\waleed\Documents\data_warehouse_project\ecommerce_data\batches\orders_err.log'
);
GO

TRUNCATE TABLE staging.order_items;

BULK INSERT staging.order_items
FROM 'C:\Users\waleed\Documents\data_warehouse_project\ecommerce_data\batches\order_items_batch1.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    CODEPAGE = '65001',
    MAXERRORS = 0,
    ERRORFILE = 'C:\Users\waleed\Documents\data_warehouse_project\ecommerce_data\batches\order_items_err.log'
);
GO

TRUNCATE TABLE staging.payments;

BULK INSERT staging.payments
FROM 'C:\Users\waleed\Documents\data_warehouse_project\ecommerce_data\batches\payments_batch1.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    CODEPAGE = '65001',
    MAXERRORS = 0,
    ERRORFILE = 'C:\Users\waleed\Documents\data_warehouse_project\ecommerce_data\batches\payments_err.log'
);
GO

-- ============================================================
-- BRONZE LAYER
-- ============================================================
-- Incremental + append-only (never truncated). Deduplication is on
-- the FULL ROW (EXCEPT), not just the business key: an unchanged
-- reload is skipped; a row with any changed column becomes a new
-- version instead of overwriting or being silently dropped.
-- bronze_id marks version order -- silver picks MAX(bronze_id) per
-- business key as the current version. Still 7 per-source tables;
-- no cross-source integration happens here.

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'bronze' AND t.name = 'customers')
BEGIN
    CREATE TABLE bronze.customers (
        bronze_id INT IDENTITY(1,1) PRIMARY KEY,
        customer_id NVARCHAR(255),
        first_name NVARCHAR(255),
        last_name NVARCHAR(255),
        email NVARCHAR(255),
        phone NVARCHAR(255),
        signup_date NVARCHAR(255),
        city NVARCHAR(255),
        state NVARCHAR(255),
        country NVARCHAR(255)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'bronze' AND t.name = 'customer_profiles')
BEGIN
    CREATE TABLE bronze.customer_profiles (
        bronze_id INT IDENTITY(1,1) PRIMARY KEY,
        profile_id NVARCHAR(255),
        customer_id NVARCHAR(255),
        email NVARCHAR(255),
        loyalty_tier NVARCHAR(255),
        marketing_opt_in NVARCHAR(255),
        preferred_channel NVARCHAR(255),
        birth_date NVARCHAR(255),
        gender NVARCHAR(255)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'bronze' AND t.name = 'products')
BEGIN
    CREATE TABLE bronze.products (
        bronze_id INT IDENTITY(1,1) PRIMARY KEY,
        product_id NVARCHAR(255),
        product_name NVARCHAR(255),
        category NVARCHAR(255),
        sub_category NVARCHAR(255),
        brand NVARCHAR(255),
        unit_price NVARCHAR(255),
        cost_price NVARCHAR(255)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'bronze' AND t.name = 'product_inventory')
BEGIN
    CREATE TABLE bronze.product_inventory (
        bronze_id INT IDENTITY(1,1) PRIMARY KEY,
        inventory_id NVARCHAR(255),
        product_id NVARCHAR(255),
        warehouse_location NVARCHAR(255),
        stock_quantity NVARCHAR(255),
        reorder_level NVARCHAR(255),
        supplier_name NVARCHAR(255),
        last_restock_date NVARCHAR(255)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'bronze' AND t.name = 'orders')
BEGIN
    CREATE TABLE bronze.orders (
        bronze_id INT IDENTITY(1,1) PRIMARY KEY,
        order_id NVARCHAR(255),
        customer_id NVARCHAR(255),
        order_date NVARCHAR(255),
        order_status NVARCHAR(255),
        channel NVARCHAR(255),
        shipping_city NVARCHAR(255),
        shipping_state NVARCHAR(255)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'bronze' AND t.name = 'order_items')
BEGIN
    CREATE TABLE bronze.order_items (
        bronze_id INT IDENTITY(1,1) PRIMARY KEY,
        order_item_id NVARCHAR(255),
        order_id NVARCHAR(255),
        product_id NVARCHAR(255),
        quantity NVARCHAR(255),
        unit_price NVARCHAR(255),
        discount_pct NVARCHAR(255)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'bronze' AND t.name = 'payments')
BEGIN
    CREATE TABLE bronze.payments (
        bronze_id INT IDENTITY(1,1) PRIMARY KEY,
        payment_id NVARCHAR(255),
        order_id NVARCHAR(255),
        payment_method NVARCHAR(255),
        amount NVARCHAR(255),
        payment_date NVARCHAR(255),
        payment_status NVARCHAR(255)
    );
END;
GO

-- bronze.customers: full-row anti-join against staging.customers
INSERT INTO bronze.customers (
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    signup_date,
    city,
    state,
    country
)
SELECT customer_id, first_name, last_name, email, phone, signup_date, city, state, country
FROM staging.customers
EXCEPT
SELECT customer_id, first_name, last_name, email, phone, signup_date, city, state, country
FROM bronze.customers;
GO

-- bronze.customer_profiles: full-row anti-join against staging.customer_profiles
INSERT INTO bronze.customer_profiles (
    profile_id,
    customer_id,
    email,
    loyalty_tier,
    marketing_opt_in,
    preferred_channel,
    birth_date,
    gender
)
SELECT profile_id, customer_id, email, loyalty_tier, marketing_opt_in, preferred_channel, birth_date, gender
FROM staging.customer_profiles
EXCEPT
SELECT profile_id, customer_id, email, loyalty_tier, marketing_opt_in, preferred_channel, birth_date, gender
FROM bronze.customer_profiles;
GO

-- bronze.products: full-row anti-join against staging.products
INSERT INTO bronze.products (
    product_id,
    product_name,
    category,
    sub_category,
    brand,
    unit_price,
    cost_price
)
SELECT product_id, product_name, category, sub_category, brand, unit_price, cost_price
FROM staging.products
EXCEPT
SELECT product_id, product_name, category, sub_category, brand, unit_price, cost_price
FROM bronze.products;
GO

-- bronze.product_inventory: full-row anti-join against staging.product_inventory
INSERT INTO bronze.product_inventory (
    inventory_id,
    product_id,
    warehouse_location,
    stock_quantity,
    reorder_level,
    supplier_name,
    last_restock_date
)
SELECT inventory_id, product_id, warehouse_location, stock_quantity, reorder_level, supplier_name, last_restock_date
FROM staging.product_inventory
EXCEPT
SELECT inventory_id, product_id, warehouse_location, stock_quantity, reorder_level, supplier_name, last_restock_date
FROM bronze.product_inventory;
GO

-- bronze.orders: full-row anti-join against staging.orders
INSERT INTO bronze.orders (
    order_id,
    customer_id,
    order_date,
    order_status,
    channel,
    shipping_city,
    shipping_state
)
SELECT order_id, customer_id, order_date, order_status, channel, shipping_city, shipping_state
FROM staging.orders
EXCEPT
SELECT order_id, customer_id, order_date, order_status, channel, shipping_city, shipping_state
FROM bronze.orders;
GO

-- bronze.order_items: full-row anti-join against staging.order_items
INSERT INTO bronze.order_items (
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_pct
)
SELECT order_item_id, order_id, product_id, quantity, unit_price, discount_pct
FROM staging.order_items
EXCEPT
SELECT order_item_id, order_id, product_id, quantity, unit_price, discount_pct
FROM bronze.order_items;
GO

-- bronze.payments: full-row anti-join against staging.payments
INSERT INTO bronze.payments (
    payment_id,
    order_id,
    payment_method,
    amount,
    payment_date,
    payment_status
)
SELECT payment_id, order_id, payment_method, amount, payment_date, payment_status
FROM staging.payments
EXCEPT
SELECT payment_id, order_id, payment_method, amount, payment_date, payment_status
FROM bronze.payments;
GO

-- ============================================================
-- SILVER LAYER
-- ============================================================
-- 5 tables (customer_profiles and product_inventory are absorbed
-- into customers/products here -- this is where integration happens).
-- Per table: take the latest bronze version per business key, TRY_CAST
-- every column to its real type, clean (trim/blank->NULL), flag
-- missing/invalid/outlier values (flagged, never dropped or nulled),
-- then MERGE upsert on the business key so silver always holds exactly
-- one current row per entity.

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'silver' AND t.name = 'customers')
BEGIN
    CREATE TABLE silver.customers (
        customer_id NVARCHAR(20) NOT NULL,
        first_name NVARCHAR(50),
        last_name NVARCHAR(50),
        email NVARCHAR(100),
        phone NVARCHAR(20),
        signup_date DATE,
        city NVARCHAR(50),
        state NVARCHAR(5),
        country NVARCHAR(30),
        profile_id NVARCHAR(20),
        loyalty_tier NVARCHAR(20),
        marketing_opt_in BIT,
        preferred_channel NVARCHAR(20),
        birth_date DATE,
        gender NVARCHAR(20),
        has_missing_value BIT NOT NULL DEFAULT 0,
        has_invalid_value BIT NOT NULL DEFAULT 0,
        has_outlier_value BIT NOT NULL DEFAULT 0,
        CONSTRAINT PK_silver_customers PRIMARY KEY (customer_id)
    );
END;
GO


-- CTE-001
WITH cust_latest AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY bronze_id DESC) AS rn
    FROM bronze.customers
    WHERE NULLIF(LTRIM(RTRIM(customer_id)), '') IS NOT NULL
),
-- CTE-002
cust_cleaned AS (
    SELECT
        LTRIM(RTRIM(customer_id)) AS customer_id,
        NULLIF(LTRIM(RTRIM(first_name)), '') AS first_name,
        NULLIF(LTRIM(RTRIM(last_name)), '') AS last_name,
        NULLIF(LTRIM(RTRIM(email)), '') AS email,
        NULLIF(LTRIM(RTRIM(phone)), '') AS phone,
        /*
            So, using the two null check configuration in the sign up date is mandatory
            the first try_cast will get null in both cases either the main value is missing
            or the raw value is invalid.
            So, we need to have the raw value beside the casted value to chekc if there is missing
            value or invalid value.
            This will happen also with all the other values that we need to check the missing and the invalid values.
        */
        TRY_CAST(NULLIF(LTRIM(RTRIM(signup_date)), '') AS DATE) AS signup_date,
        NULLIF(LTRIM(RTRIM(signup_date)), '') AS raw_signup_date,
        NULLIF(LTRIM(RTRIM(city)), '') AS city,
        NULLIF(LTRIM(RTRIM(state)), '') AS state,
        NULLIF(LTRIM(RTRIM(country)), '') AS country,
        cust_latest.rn
    FROM cust_latest
    -- Now, we only selected the first ranked customer with the latest update value
    WHERE cust_latest.rn = 1
),
-- CTE-003
prof_latest AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY profile_id ORDER BY bronze_id DESC) AS rn
    FROM bronze.customer_profiles
    WHERE NULLIF(LTRIM(RTRIM(profile_id)), '') IS NOT NULL
),
-- CTE-004
prof_cleaned AS (
    SELECT
        NULLIF(LTRIM(RTRIM(profile_id)), '') AS profile_id,
        NULLIF(LTRIM(RTRIM(loyalty_tier)), '') AS loyalty_tier,
        -- In this column we are going to convert the YES, NO into 0 and 1.
        -- I think we can stick to the original data from the table instead
        -- of converting into 0 and 1 because we are going to convert later on 
        -- in Power BI or Python.
        CASE
            WHEN UPPER(LTRIM(RTRIM(marketing_opt_in))) = 'YES' THEN CAST(1 AS BIT)
            WHEN UPPER(LTRIM(RTRIM(marketing_opt_in))) = 'NO' THEN CAST(0 AS BIT)
            ELSE NULL 
        END AS marketing_opt_in,
        NULLIF(LTRIM(RTRIM(marketing_opt_in)), '') AS raw_marketing_opt_in,
        NULLIF(LTRIM(RTRIM(preferred_channel)), '') AS preferred_channel,
        -- The same as the signup date, we need to have the raw value beside the casted value to chekc if there is missing
        TRY_CAST(NULLIF(LTRIM(RTRIM(birth_date)), '') AS DATE) AS birth_date,
        NULLIF(LTRIM(RTRIM(birth_date)), '') AS raw_birth_date,
        NULLIF(LTRIM(RTRIM(gender)), '') AS gender,
        CASE
            WHEN LTRIM(RTRIM(customer_id)) IS NULL OR LTRIM(RTRIM(customer_id)) = '' THEN NULL
            WHEN PATINDEX('%[0-9]%', LTRIM(RTRIM(customer_id))) = 0 THEN NULL
            ELSE 'CUST-' + RIGHT(REPLICATE('0', 6) +
                CASE
                    WHEN PATINDEX('%[0-9]%', LTRIM(RTRIM(customer_id))) = 0 THEN NULL
                    ELSE STUFF(LTRIM(RTRIM(customer_id)), 1, PATINDEX('%[0-9]%', LTRIM(RTRIM(customer_id))) - 1, '')
                END, 6)
            END AS matched_customer_id
    FROM prof_latest
    WHERE prof_latest.rn = 1
),
-- CTE-005
-- So, the purpose of this CTE is to rank the profiles based on the customer_id
-- coming after the cleaning of the customer_profiles
-- It seems we may have multiple profiles for the same customer
-- So, we need to rank them. 
prof_ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY matched_customer_id ORDER BY profile_id DESC) AS prn
    FROM prof_cleaned
    WHERE matched_customer_id IS NOT NULL
),
-- CTE-006
flagged AS (
    SELECT
        c.customer_id, c.first_name, c.last_name, c.email, c.phone, c.signup_date, c.city, c.state, c.country,
        p.profile_id, p.loyalty_tier, p.marketing_opt_in, p.preferred_channel, p.birth_date, p.gender,
        CASE WHEN
                    c.first_name IS NULL
                OR  c.last_name IS NULL
                OR  c.email IS NULL
                OR  c.signup_date IS NULL
            THEN 1 
            ELSE 0 
            END AS has_missing_value,
        
        CASE WHEN
                c.raw_signup_date IS NOT NULL 
            AND c.signup_date IS NULL
            OR  p.raw_marketing_opt_in IS NOT NULL
            AND p.marketing_opt_in IS NULL
            OR  p.raw_birth_date IS NOT NULL
            AND p.birth_date IS NULL
            OR (c.email IS NOT NULL AND c.email NOT LIKE '%_@__%.__%')
        THEN 1 
        ELSE 0 
        END AS has_invalid_value,
        CAST(0 AS BIT) AS has_outlier_value
    FROM cust_cleaned c
    LEFT JOIN prof_ranked p
        ON p.matched_customer_id = c.customer_id AND p.prn = 1
)
MERGE silver.customers AS tgt
USING flagged AS src
ON tgt.customer_id = src.customer_id
WHEN MATCHED THEN
    UPDATE SET
        tgt.first_name = src.first_name,
        tgt.last_name = src.last_name,
        tgt.email = src.email,
        tgt.phone = src.phone,
        tgt.signup_date = src.signup_date,
        tgt.city = src.city,
        tgt.state = src.state,
        tgt.country = src.country,
        tgt.profile_id = src.profile_id,
        tgt.loyalty_tier = src.loyalty_tier,
        tgt.marketing_opt_in = src.marketing_opt_in,
        tgt.preferred_channel = src.preferred_channel,
        tgt.birth_date = src.birth_date,
        tgt.gender = src.gender,
        tgt.has_missing_value = src.has_missing_value,
        tgt.has_invalid_value = src.has_invalid_value,
        tgt.has_outlier_value = src.has_outlier_value
WHEN NOT MATCHED THEN
    INSERT (customer_id, first_name, last_name, email, phone, signup_date, city, state, country, profile_id, loyalty_tier, marketing_opt_in, preferred_channel, birth_date, gender, has_missing_value, has_invalid_value, has_outlier_value)
    VALUES (src.customer_id, src.first_name, src.last_name, src.email, src.phone, src.signup_date, src.city, src.state, src.country, src.profile_id, src.loyalty_tier, src.marketing_opt_in, src.preferred_channel, src.birth_date, src.gender, src.has_missing_value, src.has_invalid_value, src.has_outlier_value);
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'silver' AND t.name = 'products')
BEGIN
    CREATE TABLE silver.products (
        product_id NVARCHAR(20) NOT NULL,
        product_name NVARCHAR(100),
        category NVARCHAR(30),
        sub_category NVARCHAR(30),
        brand NVARCHAR(30),
        unit_price DECIMAL(10,2),
        cost_price DECIMAL(10,2),
        inventory_id NVARCHAR(20),
        warehouse_location NVARCHAR(20),
        stock_quantity INT,
        reorder_level INT,
        supplier_name NVARCHAR(100),
        last_restock_date DATE,
        has_missing_value BIT NOT NULL DEFAULT 0,
        has_invalid_value BIT NOT NULL DEFAULT 0,
        has_outlier_value BIT NOT NULL DEFAULT 0,
        CONSTRAINT PK_silver_products PRIMARY KEY (product_id)
    );
END;
GO

WITH prod_latest AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY bronze_id DESC) AS rn
    FROM bronze.products
    WHERE NULLIF(LTRIM(RTRIM(product_id)), '') IS NOT NULL
),
prod_cleaned AS (
    SELECT
        LTRIM(RTRIM(product_id)) AS product_id,
        NULLIF(LTRIM(RTRIM(product_name)), '') AS product_name,
        NULLIF(LTRIM(RTRIM(category)), '') AS category,
        NULLIF(LTRIM(RTRIM(sub_category)), '') AS sub_category,
        NULLIF(LTRIM(RTRIM(brand)), '') AS brand,
        TRY_CAST(NULLIF(LTRIM(RTRIM(unit_price)), '') AS DECIMAL(10,2)) AS unit_price,
        NULLIF(LTRIM(RTRIM(unit_price)), '') AS raw_unit_price,
        TRY_CAST(NULLIF(LTRIM(RTRIM(cost_price)), '') AS DECIMAL(10,2)) AS cost_price,
        NULLIF(LTRIM(RTRIM(cost_price)), '') AS raw_cost_price,
        prod_latest.rn
    FROM prod_latest
    WHERE prod_latest.rn = 1
),
inv_latest AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY inventory_id ORDER BY bronze_id DESC) AS rn
    FROM bronze.product_inventory
    WHERE NULLIF(LTRIM(RTRIM(inventory_id)), '') IS NOT NULL
),
inv_cleaned AS (
    SELECT
        NULLIF(LTRIM(RTRIM(inventory_id)), '') AS inventory_id,
        NULLIF(LTRIM(RTRIM(warehouse_location)), '') AS warehouse_location,
        TRY_CAST(NULLIF(LTRIM(RTRIM(stock_quantity)), '') AS INT) AS stock_quantity,
        NULLIF(LTRIM(RTRIM(stock_quantity)), '') AS raw_stock_quantity,
        TRY_CAST(NULLIF(LTRIM(RTRIM(reorder_level)), '') AS INT) AS reorder_level,
        NULLIF(LTRIM(RTRIM(reorder_level)), '') AS raw_reorder_level,
        NULLIF(LTRIM(RTRIM(supplier_name)), '') AS supplier_name,
        TRY_CAST(NULLIF(LTRIM(RTRIM(last_restock_date)), '') AS DATE) AS last_restock_date,
        NULLIF(LTRIM(RTRIM(last_restock_date)), '') AS raw_last_restock_date
        , CASE WHEN LTRIM(RTRIM(product_id)) IS NULL OR LTRIM(RTRIM(product_id)) = '' THEN NULL WHEN PATINDEX('%[0-9]%', LTRIM(RTRIM(product_id))) = 0 THEN NULL ELSE 'PROD-' + RIGHT(REPLICATE('0', 5) + CASE WHEN PATINDEX('%[0-9]%', LTRIM(RTRIM(product_id))) = 0 THEN NULL ELSE STUFF(LTRIM(RTRIM(product_id)), 1, PATINDEX('%[0-9]%', LTRIM(RTRIM(product_id))) - 1, '') END, 5) END AS matched_product_id
    FROM inv_latest
    WHERE inv_latest.rn = 1
),
inv_ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY matched_product_id ORDER BY inventory_id DESC) AS irn
    FROM inv_cleaned
    WHERE matched_product_id IS NOT NULL
),
iqr_bounds AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY unit_price) OVER () AS q1_unit_price,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY unit_price) OVER () AS q3_unit_price,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY cost_price) OVER () AS q1_cost_price,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY cost_price) OVER () AS q3_cost_price
    FROM prod_cleaned
),
flagged AS (
    SELECT
        p.product_id, p.product_name, p.category, p.sub_category, p.brand, p.unit_price, p.cost_price,
        i.inventory_id, i.warehouse_location, i.stock_quantity, i.reorder_level, i.supplier_name, i.last_restock_date,
        CASE WHEN
            p.product_name IS NULL
        OR p.category IS NULL
        OR p.unit_price IS NULL
        THEN 1 ELSE 0 END AS has_missing_value,
        CASE WHEN
            p.raw_unit_price IS NOT NULL AND p.unit_price IS NULL
        OR p.raw_cost_price IS NOT NULL AND p.cost_price IS NULL
        OR i.raw_stock_quantity IS NOT NULL AND i.stock_quantity IS NULL
        OR i.raw_reorder_level IS NOT NULL AND i.reorder_level IS NULL
        OR i.raw_last_restock_date IS NOT NULL AND i.last_restock_date IS NULL
        OR (p.unit_price IS NOT NULL AND p.unit_price <= 0)
        OR (p.cost_price IS NOT NULL AND p.cost_price <= 0)
        OR (i.stock_quantity IS NOT NULL AND i.stock_quantity < 0)
        THEN 1 ELSE 0 END AS has_invalid_value,
        CASE WHEN
            (p.unit_price IS NOT NULL AND (p.unit_price < q1_unit_price - 1.5*(q3_unit_price-q1_unit_price) OR p.unit_price > q3_unit_price + 1.5*(q3_unit_price-q1_unit_price)))
        OR (p.cost_price IS NOT NULL AND (p.cost_price < q1_cost_price - 1.5*(q3_cost_price-q1_cost_price) OR p.cost_price > q3_cost_price + 1.5*(q3_cost_price-q1_cost_price)))
        THEN 1 ELSE 0 END AS has_outlier_value
    FROM prod_cleaned p
    CROSS JOIN iqr_bounds b
    LEFT JOIN inv_ranked i
        ON i.matched_product_id = p.product_id AND i.irn = 1
)
MERGE silver.products AS tgt
USING flagged AS src
ON tgt.product_id = src.product_id
WHEN MATCHED THEN
    UPDATE SET
        tgt.product_name = src.product_name,
        tgt.category = src.category,
        tgt.sub_category = src.sub_category,
        tgt.brand = src.brand,
        tgt.unit_price = src.unit_price,
        tgt.cost_price = src.cost_price,
        tgt.inventory_id = src.inventory_id,
        tgt.warehouse_location = src.warehouse_location,
        tgt.stock_quantity = src.stock_quantity,
        tgt.reorder_level = src.reorder_level,
        tgt.supplier_name = src.supplier_name,
        tgt.last_restock_date = src.last_restock_date,
        tgt.has_missing_value = src.has_missing_value,
        tgt.has_invalid_value = src.has_invalid_value,
        tgt.has_outlier_value = src.has_outlier_value
WHEN NOT MATCHED THEN
    INSERT (product_id, product_name, category, sub_category, brand, unit_price, cost_price, inventory_id, warehouse_location, stock_quantity, reorder_level, supplier_name, last_restock_date, has_missing_value, has_invalid_value, has_outlier_value)
    VALUES (src.product_id, src.product_name, src.category, src.sub_category, src.brand, src.unit_price, src.cost_price, src.inventory_id, src.warehouse_location, src.stock_quantity, src.reorder_level, src.supplier_name, src.last_restock_date, src.has_missing_value, src.has_invalid_value, src.has_outlier_value);
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'silver' AND t.name = 'orders')
BEGIN
    CREATE TABLE silver.orders (
        order_id NVARCHAR(20) NOT NULL,
        customer_id NVARCHAR(20),
        order_date DATE,
        order_status NVARCHAR(20),
        channel NVARCHAR(20),
        shipping_city NVARCHAR(50),
        shipping_state NVARCHAR(5),
        has_missing_value BIT NOT NULL DEFAULT 0,
        has_invalid_value BIT NOT NULL DEFAULT 0,
        has_outlier_value BIT NOT NULL DEFAULT 0,
        CONSTRAINT PK_silver_orders PRIMARY KEY (order_id)
    );
END;
GO

WITH ord_latest AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY bronze_id DESC) AS rn
    FROM bronze.orders
    WHERE NULLIF(LTRIM(RTRIM(order_id)), '') IS NOT NULL
),
cleaned AS (
    SELECT
        LTRIM(RTRIM(order_id)) AS order_id,
        NULLIF(LTRIM(RTRIM(customer_id)), '') AS customer_id,
        TRY_CAST(NULLIF(LTRIM(RTRIM(order_date)), '') AS DATE) AS order_date,
        NULLIF(LTRIM(RTRIM(order_date)), '') AS raw_order_date,
        NULLIF(LTRIM(RTRIM(order_status)), '') AS order_status,
        NULLIF(LTRIM(RTRIM(channel)), '') AS channel,
        NULLIF(LTRIM(RTRIM(shipping_city)), '') AS shipping_city,
        NULLIF(LTRIM(RTRIM(shipping_state)), '') AS shipping_state
    FROM ord_latest
    WHERE ord_latest.rn = 1
),
flagged AS (
    SELECT
        order_id, customer_id, order_date, order_status, channel, shipping_city, shipping_state,
        CASE WHEN
            customer_id IS NULL
        OR order_date IS NULL
        OR order_status IS NULL
        THEN 1 ELSE 0 END AS has_missing_value,
        CASE WHEN
            raw_order_date IS NOT NULL AND order_date IS NULL
        OR (customer_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM silver.customers sc WHERE sc.customer_id = cleaned.customer_id))
        THEN 1 ELSE 0 END AS has_invalid_value,
        CAST(0 AS BIT) AS has_outlier_value
    FROM cleaned
)
MERGE silver.orders AS tgt
USING flagged AS src
ON tgt.order_id = src.order_id
WHEN MATCHED THEN
    UPDATE SET
        tgt.customer_id = src.customer_id,
        tgt.order_date = src.order_date,
        tgt.order_status = src.order_status,
        tgt.channel = src.channel,
        tgt.shipping_city = src.shipping_city,
        tgt.shipping_state = src.shipping_state,
        tgt.has_missing_value = src.has_missing_value,
        tgt.has_invalid_value = src.has_invalid_value,
        tgt.has_outlier_value = src.has_outlier_value
WHEN NOT MATCHED THEN
    INSERT (order_id, customer_id, order_date, order_status, channel, shipping_city, shipping_state, has_missing_value, has_invalid_value, has_outlier_value)
    VALUES (src.order_id, src.customer_id, src.order_date, src.order_status, src.channel, src.shipping_city, src.shipping_state, src.has_missing_value, src.has_invalid_value, src.has_outlier_value);
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'silver' AND t.name = 'order_items')
BEGIN
    CREATE TABLE silver.order_items (
        order_item_id NVARCHAR(20) NOT NULL,
        order_id NVARCHAR(20),
        product_id NVARCHAR(20),
        quantity INT,
        unit_price DECIMAL(10,2),
        discount_pct DECIMAL(5,3),
        has_missing_value BIT NOT NULL DEFAULT 0,
        has_invalid_value BIT NOT NULL DEFAULT 0,
        has_outlier_value BIT NOT NULL DEFAULT 0,
        CONSTRAINT PK_silver_order_items PRIMARY KEY (order_item_id)
    );
END;
GO

WITH item_latest AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY order_item_id ORDER BY bronze_id DESC) AS rn
    FROM bronze.order_items
    WHERE NULLIF(LTRIM(RTRIM(order_item_id)), '') IS NOT NULL
),
cleaned AS (
    SELECT
        LTRIM(RTRIM(order_item_id)) AS order_item_id,
        NULLIF(LTRIM(RTRIM(order_id)), '') AS order_id,
        NULLIF(LTRIM(RTRIM(product_id)), '') AS product_id,
        TRY_CAST(NULLIF(LTRIM(RTRIM(quantity)), '') AS INT) AS quantity,
        NULLIF(LTRIM(RTRIM(quantity)), '') AS raw_quantity,
        TRY_CAST(NULLIF(LTRIM(RTRIM(unit_price)), '') AS DECIMAL(10,2)) AS unit_price,
        NULLIF(LTRIM(RTRIM(unit_price)), '') AS raw_unit_price,
        TRY_CAST(NULLIF(LTRIM(RTRIM(discount_pct)), '') AS DECIMAL(5,3)) AS discount_pct,
        NULLIF(LTRIM(RTRIM(discount_pct)), '') AS raw_discount_pct
    FROM item_latest
    WHERE item_latest.rn = 1
),
iqr_bounds AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY unit_price) OVER () AS q1_unit_price,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY unit_price) OVER () AS q3_unit_price,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY quantity) OVER () AS q1_quantity,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY quantity) OVER () AS q3_quantity
    FROM cleaned
),
flagged AS (
    SELECT
        c.order_item_id, c.order_id, c.product_id, c.quantity, c.unit_price, c.discount_pct,
        CASE WHEN
            c.order_id IS NULL
        OR c.product_id IS NULL
        OR c.quantity IS NULL
        OR c.unit_price IS NULL
        THEN 1 ELSE 0 END AS has_missing_value,
        CASE WHEN
            c.raw_quantity IS NOT NULL AND c.quantity IS NULL
        OR c.raw_unit_price IS NOT NULL AND c.unit_price IS NULL
        OR c.raw_discount_pct IS NOT NULL AND c.discount_pct IS NULL
        OR (c.quantity IS NOT NULL AND c.quantity <= 0)
        OR (c.unit_price IS NOT NULL AND c.unit_price <= 0)
        OR (c.discount_pct IS NOT NULL AND (c.discount_pct < 0 OR c.discount_pct > 1))
        OR (c.order_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM silver.orders so WHERE so.order_id = c.order_id))
        OR (c.product_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM silver.products sp WHERE sp.product_id = c.product_id))
        THEN 1 ELSE 0 END AS has_invalid_value,
        CASE WHEN
            (c.unit_price IS NOT NULL AND (c.unit_price < q1_unit_price - 1.5*(q3_unit_price-q1_unit_price) OR c.unit_price > q3_unit_price + 1.5*(q3_unit_price-q1_unit_price)))
        OR (c.quantity IS NOT NULL AND (c.quantity < q1_quantity - 1.5*(q3_quantity-q1_quantity) OR c.quantity > q3_quantity + 1.5*(q3_quantity-q1_quantity)))
        THEN 1 ELSE 0 END AS has_outlier_value
    FROM cleaned c
    CROSS JOIN iqr_bounds b
)
MERGE silver.order_items AS tgt
USING flagged AS src
ON tgt.order_item_id = src.order_item_id
WHEN MATCHED THEN
    UPDATE SET
        tgt.order_id = src.order_id,
        tgt.product_id = src.product_id,
        tgt.quantity = src.quantity,
        tgt.unit_price = src.unit_price,
        tgt.discount_pct = src.discount_pct,
        tgt.has_missing_value = src.has_missing_value,
        tgt.has_invalid_value = src.has_invalid_value,
        tgt.has_outlier_value = src.has_outlier_value
WHEN NOT MATCHED THEN
    INSERT (order_item_id, order_id, product_id, quantity, unit_price, discount_pct, has_missing_value, has_invalid_value, has_outlier_value)
    VALUES (src.order_item_id, src.order_id, src.product_id, src.quantity, src.unit_price, src.discount_pct, src.has_missing_value, src.has_invalid_value, src.has_outlier_value);
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'silver' AND t.name = 'payments')
BEGIN
    CREATE TABLE silver.payments (
        payment_id NVARCHAR(20) NOT NULL,
        order_id NVARCHAR(20),
        payment_method NVARCHAR(20),
        amount DECIMAL(12,2),
        payment_date DATE,
        payment_status NVARCHAR(20),
        has_missing_value BIT NOT NULL DEFAULT 0,
        has_invalid_value BIT NOT NULL DEFAULT 0,
        has_outlier_value BIT NOT NULL DEFAULT 0,
        CONSTRAINT PK_silver_payments PRIMARY KEY (payment_id)
    );
END;
GO

WITH pay_latest AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY payment_id ORDER BY bronze_id DESC) AS rn
    FROM bronze.payments
    WHERE NULLIF(LTRIM(RTRIM(payment_id)), '') IS NOT NULL
),
cleaned AS (
    SELECT
        LTRIM(RTRIM(payment_id)) AS payment_id,
        NULLIF(LTRIM(RTRIM(order_id)), '') AS order_id,
        NULLIF(LTRIM(RTRIM(payment_method)), '') AS payment_method,
        TRY_CAST(NULLIF(LTRIM(RTRIM(amount)), '') AS DECIMAL(12,2)) AS amount,
        NULLIF(LTRIM(RTRIM(amount)), '') AS raw_amount,
        TRY_CAST(NULLIF(LTRIM(RTRIM(payment_date)), '') AS DATE) AS payment_date,
        NULLIF(LTRIM(RTRIM(payment_date)), '') AS raw_payment_date,
        NULLIF(LTRIM(RTRIM(payment_status)), '') AS payment_status
    FROM pay_latest
    WHERE pay_latest.rn = 1
),
iqr_bounds AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY amount) OVER () AS q1_amount,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY amount) OVER () AS q3_amount
    FROM cleaned
),
flagged AS (
    SELECT
        c.payment_id, c.order_id, c.payment_method, c.amount, c.payment_date, c.payment_status,
        CASE WHEN
            c.order_id IS NULL
        OR c.amount IS NULL
        OR c.payment_date IS NULL
        OR c.payment_status IS NULL
        THEN 1 ELSE 0 END AS has_missing_value,
        CASE WHEN
            c.raw_amount IS NOT NULL AND c.amount IS NULL
        OR c.raw_payment_date IS NOT NULL AND c.payment_date IS NULL
        OR (c.amount IS NOT NULL AND c.amount < 0)
        OR (c.order_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM silver.orders so WHERE so.order_id = c.order_id))
        THEN 1 ELSE 0 END AS has_invalid_value,
        CASE WHEN
            (c.amount IS NOT NULL AND (c.amount < q1_amount - 1.5*(q3_amount-q1_amount) OR c.amount > q3_amount + 1.5*(q3_amount-q1_amount)))
        THEN 1 ELSE 0 END AS has_outlier_value
    FROM cleaned c
    CROSS JOIN iqr_bounds b
)
MERGE silver.payments AS tgt
USING flagged AS src
ON tgt.payment_id = src.payment_id
WHEN MATCHED THEN
    UPDATE SET
        tgt.order_id = src.order_id,
        tgt.payment_method = src.payment_method,
        tgt.amount = src.amount,
        tgt.payment_date = src.payment_date,
        tgt.payment_status = src.payment_status,
        tgt.has_missing_value = src.has_missing_value,
        tgt.has_invalid_value = src.has_invalid_value,
        tgt.has_outlier_value = src.has_outlier_value
WHEN NOT MATCHED THEN
    INSERT (payment_id, order_id, payment_method, amount, payment_date, payment_status, has_missing_value, has_invalid_value, has_outlier_value)
    VALUES (src.payment_id, src.order_id, src.payment_method, src.amount, src.payment_date, src.payment_status, src.has_missing_value, src.has_invalid_value, src.has_outlier_value);
GO


-- ============================================================
-- GOLD LAYER
-- ============================================================
-- Star schema (fact constellation: two facts share conformed dimensions).
-- This is the first layer with real PRIMARY KEY / FOREIGN KEY constraints --
-- staging/bronze/silver stay constraint-free on purpose; gold is the
-- trusted layer, so referential integrity is finally enforced here.
--
-- Every dimension carries a surrogate IDENTITY key (Type 1: attributes are
-- overwritten to the latest value, no history) plus a -1 "Unknown" member
-- row. A fact row whose natural key can't be resolved to a real dimension
-- member (an unfixable orphan FK from the source systems) still loads,
-- pointed at -1 / 1900-01-01, instead of being silently dropped -- so
-- gold's totals still match reality, and the gap is visible as "Unknown"
-- in any report that groups by that dimension.
--
--   dim_customer         dim_product          dim_date        dim_payment_method
--         \                    |                  |                  /
--          \                   |                  |                 /
--       fact_order_items ------+------------------+
--       fact_payments   -------+------------------+-----------------+
--
-- fact_order_items: grain = one row per order line (customer, product, date)
-- fact_payments:    grain = one row per payment    (customer, date, method)

-- ----------------------------------------------------------------
-- dim_customer
-- ----------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'gold' AND t.name = 'dim_customer')
BEGIN
    CREATE TABLE gold.dim_customer (
        customer_key INT IDENTITY(1,1) PRIMARY KEY,
        customer_id NVARCHAR(20) NOT NULL,
        first_name NVARCHAR(50),
        last_name NVARCHAR(50),
        email NVARCHAR(100),
        phone NVARCHAR(20),
        city NVARCHAR(50),
        state NVARCHAR(5),
        country NVARCHAR(30),
        signup_date DATE,
        loyalty_tier NVARCHAR(20),
        marketing_opt_in BIT,
        preferred_channel NVARCHAR(20),
        birth_date DATE,
        gender NVARCHAR(20),
        CONSTRAINT UQ_dim_customer_customer_id UNIQUE (customer_id)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM gold.dim_customer WHERE customer_key = -1)
BEGIN
    SET IDENTITY_INSERT gold.dim_customer ON;
    INSERT INTO gold.dim_customer (customer_key, customer_id, first_name, last_name, email, phone, city, state, country, signup_date, loyalty_tier, marketing_opt_in, preferred_channel, birth_date, gender)
    VALUES (-1, 'UNKNOWN', 'Unknown', 'Unknown', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
    SET IDENTITY_INSERT gold.dim_customer OFF;
END;
GO

MERGE gold.dim_customer AS tgt
USING silver.customers AS src
ON tgt.customer_id = src.customer_id
WHEN MATCHED THEN
    UPDATE SET
        tgt.first_name = src.first_name,
        tgt.last_name = src.last_name,
        tgt.email = src.email,
        tgt.phone = src.phone,
        tgt.city = src.city,
        tgt.state = src.state,
        tgt.country = src.country,
        tgt.signup_date = src.signup_date,
        tgt.loyalty_tier = src.loyalty_tier,
        tgt.marketing_opt_in = src.marketing_opt_in,
        tgt.preferred_channel = src.preferred_channel,
        tgt.birth_date = src.birth_date,
        tgt.gender = src.gender
WHEN NOT MATCHED THEN
    INSERT (customer_id, first_name, last_name, email, phone, city, state, country, signup_date, loyalty_tier, marketing_opt_in, preferred_channel, birth_date, gender)
    VALUES (src.customer_id, src.first_name, src.last_name, src.email, src.phone, src.city, src.state, src.country, src.signup_date, src.loyalty_tier, src.marketing_opt_in, src.preferred_channel, src.birth_date, src.gender);
GO

-- ----------------------------------------------------------------
-- dim_product
-- ----------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'gold' AND t.name = 'dim_product')
BEGIN
    CREATE TABLE gold.dim_product (
        product_key INT IDENTITY(1,1) PRIMARY KEY,
        product_id NVARCHAR(20) NOT NULL,
        product_name NVARCHAR(100),
        category NVARCHAR(30),
        sub_category NVARCHAR(30),
        brand NVARCHAR(30),
        unit_price DECIMAL(10,2),
        cost_price DECIMAL(10,2),
        warehouse_location NVARCHAR(20),
        stock_quantity INT,
        reorder_level INT,
        supplier_name NVARCHAR(100),
        CONSTRAINT UQ_dim_product_product_id UNIQUE (product_id)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM gold.dim_product WHERE product_key = -1)
BEGIN
    SET IDENTITY_INSERT gold.dim_product ON;
    INSERT INTO gold.dim_product (product_key, product_id, product_name, category, sub_category, brand, unit_price, cost_price, warehouse_location, stock_quantity, reorder_level, supplier_name)
    VALUES (-1, 'UNKNOWN', 'Unknown', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
    SET IDENTITY_INSERT gold.dim_product OFF;
END;
GO

MERGE gold.dim_product AS tgt
USING silver.products AS src
ON tgt.product_id = src.product_id
WHEN MATCHED THEN
    UPDATE SET
        tgt.product_name = src.product_name,
        tgt.category = src.category,
        tgt.sub_category = src.sub_category,
        tgt.brand = src.brand,
        tgt.unit_price = src.unit_price,
        tgt.cost_price = src.cost_price,
        tgt.warehouse_location = src.warehouse_location,
        tgt.stock_quantity = src.stock_quantity,
        tgt.reorder_level = src.reorder_level,
        tgt.supplier_name = src.supplier_name
WHEN NOT MATCHED THEN
    INSERT (product_id, product_name, category, sub_category, brand, unit_price, cost_price, warehouse_location, stock_quantity, reorder_level, supplier_name)
    VALUES (src.product_id, src.product_name, src.category, src.sub_category, src.brand, src.unit_price, src.cost_price, src.warehouse_location, src.stock_quantity, src.reorder_level, src.supplier_name);
GO

-- ----------------------------------------------------------------
-- dim_payment_method (small descriptive/junk dimension)
-- ----------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'gold' AND t.name = 'dim_payment_method')
BEGIN
    CREATE TABLE gold.dim_payment_method (
        payment_method_key INT IDENTITY(1,1) PRIMARY KEY,
        payment_method NVARCHAR(20) NOT NULL,
        CONSTRAINT UQ_dim_payment_method UNIQUE (payment_method)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM gold.dim_payment_method WHERE payment_method_key = -1)
BEGIN
    SET IDENTITY_INSERT gold.dim_payment_method ON;
    INSERT INTO gold.dim_payment_method (payment_method_key, payment_method) VALUES (-1, 'Unknown');
    SET IDENTITY_INSERT gold.dim_payment_method OFF;
END;
GO

MERGE gold.dim_payment_method AS tgt
USING (SELECT DISTINCT payment_method FROM silver.payments WHERE payment_method IS NOT NULL) AS src
ON tgt.payment_method = src.payment_method
WHEN NOT MATCHED THEN
    INSERT (payment_method) VALUES (src.payment_method);
GO

-- ----------------------------------------------------------------
-- dim_date (generated calendar spine, spans the data's own date range)
-- ----------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'gold' AND t.name = 'dim_date')
BEGIN
    CREATE TABLE gold.dim_date (
        date_key INT PRIMARY KEY,
        full_date DATE NOT NULL,
        [year] SMALLINT,
        [quarter] TINYINT,
        [month] TINYINT,
        month_name NVARCHAR(12),
        [day] TINYINT,
        day_of_week TINYINT,
        day_name NVARCHAR(12),
        is_weekend BIT,
        CONSTRAINT UQ_dim_date_full_date UNIQUE (full_date)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM gold.dim_date WHERE date_key = 19000101)
BEGIN
    INSERT INTO gold.dim_date (date_key, full_date, [year], [quarter], [month], month_name, [day], day_of_week, day_name, is_weekend)
    VALUES (19000101, '1900-01-01', 1900, 1, 1, 'Unknown', 1, 0, 'Unknown', 0);
END;
GO

DECLARE @start_date DATE, @end_date DATE;
SELECT @start_date = MIN(d), @end_date = MAX(d)
FROM (
    SELECT order_date AS d FROM silver.orders WHERE order_date IS NOT NULL
    UNION ALL
    SELECT payment_date FROM silver.payments WHERE payment_date IS NOT NULL
) x;

;WITH date_spine AS (
    SELECT @start_date AS d
    UNION ALL
    SELECT DATEADD(DAY, 1, d) FROM date_spine WHERE d < @end_date
)
INSERT INTO gold.dim_date (date_key, full_date, [year], [quarter], [month], month_name, [day], day_of_week, day_name, is_weekend)
SELECT
    CONVERT(INT, FORMAT(d, 'yyyyMMdd')),
    d,
    YEAR(d),
    DATEPART(QUARTER, d),
    MONTH(d),
    DATENAME(MONTH, d),
    DAY(d),
    DATEPART(WEEKDAY, d),
    DATENAME(WEEKDAY, d),
    CASE WHEN DATENAME(WEEKDAY, d) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END
FROM date_spine
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_date dd WHERE dd.date_key = CONVERT(INT, FORMAT(d, 'yyyyMMdd')))
OPTION (MAXRECURSION 0);
GO

-- ----------------------------------------------------------------
-- fact_order_items  (grain: one row per order line)
-- ----------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'gold' AND t.name = 'fact_order_items')
BEGIN
    CREATE TABLE gold.fact_order_items (
        order_item_id NVARCHAR(20) NOT NULL PRIMARY KEY,
        order_id NVARCHAR(20) NOT NULL,
        customer_key INT NOT NULL,
        product_key INT NOT NULL,
        order_date_key INT NOT NULL,
        quantity INT,
        unit_price DECIMAL(10,2),
        discount_pct DECIMAL(5,3),
        net_amount DECIMAL(12,2),
        CONSTRAINT FK_fact_order_items_customer FOREIGN KEY (customer_key) REFERENCES gold.dim_customer(customer_key),
        CONSTRAINT FK_fact_order_items_product FOREIGN KEY (product_key) REFERENCES gold.dim_product(product_key),
        CONSTRAINT FK_fact_order_items_date FOREIGN KEY (order_date_key) REFERENCES gold.dim_date(date_key)
    );
END;
GO

MERGE gold.fact_order_items AS tgt
USING (
    SELECT
        oi.order_item_id,
        oi.order_id,
        ISNULL(dc.customer_key, -1) AS customer_key,
        ISNULL(dp.product_key, -1) AS product_key,
        ISNULL(CONVERT(INT, FORMAT(o.order_date, 'yyyyMMdd')), 19000101) AS order_date_key,
        oi.quantity,
        oi.unit_price,
        oi.discount_pct,
        CAST(ISNULL(oi.quantity, 0) * ISNULL(oi.unit_price, 0) * (1 - ISNULL(oi.discount_pct, 0)) AS DECIMAL(12,2)) AS net_amount
    FROM silver.order_items oi
    LEFT JOIN silver.orders o ON o.order_id = oi.order_id
    LEFT JOIN gold.dim_customer dc ON dc.customer_id = o.customer_id
    LEFT JOIN gold.dim_product dp ON dp.product_id = oi.product_id
) AS src
ON tgt.order_item_id = src.order_item_id
WHEN MATCHED THEN
    UPDATE SET
        tgt.order_id = src.order_id,
        tgt.customer_key = src.customer_key,
        tgt.product_key = src.product_key,
        tgt.order_date_key = src.order_date_key,
        tgt.quantity = src.quantity,
        tgt.unit_price = src.unit_price,
        tgt.discount_pct = src.discount_pct,
        tgt.net_amount = src.net_amount
WHEN NOT MATCHED THEN
    INSERT (order_item_id, order_id, customer_key, product_key, order_date_key, quantity, unit_price, discount_pct, net_amount)
    VALUES (src.order_item_id, src.order_id, src.customer_key, src.product_key, src.order_date_key, src.quantity, src.unit_price, src.discount_pct, src.net_amount);
GO

-- ----------------------------------------------------------------
-- fact_payments  (grain: one row per payment)
-- ----------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'gold' AND t.name = 'fact_payments')
BEGIN
    CREATE TABLE gold.fact_payments (
        payment_id NVARCHAR(20) NOT NULL PRIMARY KEY,
        order_id NVARCHAR(20) NOT NULL,
        customer_key INT NOT NULL,
        payment_date_key INT NOT NULL,
        payment_method_key INT NOT NULL,
        amount DECIMAL(12,2),
        payment_status NVARCHAR(20),
        CONSTRAINT FK_fact_payments_customer FOREIGN KEY (customer_key) REFERENCES gold.dim_customer(customer_key),
        CONSTRAINT FK_fact_payments_date FOREIGN KEY (payment_date_key) REFERENCES gold.dim_date(date_key),
        CONSTRAINT FK_fact_payments_method FOREIGN KEY (payment_method_key) REFERENCES gold.dim_payment_method(payment_method_key)
    );
END;
GO

MERGE gold.fact_payments AS tgt
USING (
    SELECT
        p.payment_id,
        p.order_id,
        ISNULL(dc.customer_key, -1) AS customer_key,
        ISNULL(CONVERT(INT, FORMAT(p.payment_date, 'yyyyMMdd')), 19000101) AS payment_date_key,
        ISNULL(dpm.payment_method_key, -1) AS payment_method_key,
        p.amount,
        p.payment_status
    FROM silver.payments p
    LEFT JOIN silver.orders o ON o.order_id = p.order_id
    LEFT JOIN gold.dim_customer dc ON dc.customer_id = o.customer_id
    LEFT JOIN gold.dim_payment_method dpm ON dpm.payment_method = p.payment_method
) AS src
ON tgt.payment_id = src.payment_id
WHEN MATCHED THEN
    UPDATE SET
        tgt.order_id = src.order_id,
        tgt.customer_key = src.customer_key,
        tgt.payment_date_key = src.payment_date_key,
        tgt.payment_method_key = src.payment_method_key,
        tgt.amount = src.amount,
        tgt.payment_status = src.payment_status
WHEN NOT MATCHED THEN
    INSERT (payment_id, order_id, customer_key, payment_date_key, payment_method_key, amount, payment_status)
    VALUES (src.payment_id, src.order_id, src.customer_key, src.payment_date_key, src.payment_method_key, src.amount, src.payment_status);
GO

-- ============================================================
-- GOLD LAYER -- VIEWS (virtual alternative to the gold tables above)
-- ============================================================
-- The gold.dim_* / gold.fact_* TABLES above are left exactly as they were.
-- These views are a second, independent implementation of the same star
-- schema, computed live from silver on every query instead of being
-- loaded/materialized:
--   - No surrogate IDENTITY keys -- a view can't own one, so dimension
--     and fact views join on the natural business key directly
--     (customer_id, product_id, order_id) instead of an integer key.
--   - No separate load step and therefore never stale -- querying the
--     view re-reads silver at that moment.
--   - No FK/PK constraints -- SQL Server views cannot carry them, so
--     referential integrity here is a property of the join logic only,
--     not something the engine enforces.
--   - Same Unknown-member fallback in spirit: a fact row whose natural
--     key doesn't resolve gets 'UNKNOWN' instead of being dropped.
--   - vw_dim_date is the one real structural difference from its table
--     counterpart: the table is a gapless calendar spine built with a
--     recursive CTE, which SQL Server does not allow inside a view
--     (OPTION MAXRECURSION isn't permitted in a view body, and our date
--     range exceeds the default 100-row recursion limit). So vw_dim_date
--     instead lists only the dates that actually appear in silver.orders
--     / silver.payments -- every date a fact view needs will resolve,
--     it just isn't a continuous calendar.

IF OBJECT_ID('gold.vw_dim_customer', 'V') IS NOT NULL DROP VIEW gold.vw_dim_customer;
GO
CREATE VIEW gold.vw_dim_customer AS
SELECT
    customer_id, first_name, last_name, email, phone, city, state, country,
    signup_date, loyalty_tier, marketing_opt_in, preferred_channel, birth_date, gender
FROM silver.customers
UNION ALL
SELECT 'UNKNOWN', 'Unknown', 'Unknown', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL;
GO

IF OBJECT_ID('gold.vw_dim_product', 'V') IS NOT NULL DROP VIEW gold.vw_dim_product;
GO
CREATE VIEW gold.vw_dim_product AS
SELECT
    product_id, product_name, category, sub_category, brand, unit_price, cost_price,
    warehouse_location, stock_quantity, reorder_level, supplier_name
FROM silver.products
UNION ALL
SELECT 'UNKNOWN', 'Unknown', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL;
GO

IF OBJECT_ID('gold.vw_dim_payment_method', 'V') IS NOT NULL DROP VIEW gold.vw_dim_payment_method;
GO
CREATE VIEW gold.vw_dim_payment_method AS
SELECT payment_method FROM (
    SELECT DISTINCT payment_method FROM silver.payments WHERE payment_method IS NOT NULL
    UNION ALL
    SELECT 'Unknown'
) AS pm;
GO

IF OBJECT_ID('gold.vw_dim_date', 'V') IS NOT NULL DROP VIEW gold.vw_dim_date;
GO
CREATE VIEW gold.vw_dim_date AS
SELECT
    CONVERT(INT, FORMAT(d, 'yyyyMMdd')) AS date_key,
    d AS full_date,
    YEAR(d) AS [year],
    DATEPART(QUARTER, d) AS [quarter],
    MONTH(d) AS [month],
    DATENAME(MONTH, d) AS month_name,
    DAY(d) AS [day],
    DATEPART(WEEKDAY, d) AS day_of_week,
    DATENAME(WEEKDAY, d) AS day_name,
    CASE WHEN DATENAME(WEEKDAY, d) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END AS is_weekend
FROM (
    SELECT DISTINCT order_date AS d FROM silver.orders WHERE order_date IS NOT NULL
    UNION
    SELECT DISTINCT payment_date FROM silver.payments WHERE payment_date IS NOT NULL
) AS dates
UNION ALL
SELECT 19000101, '1900-01-01', 1900, 1, 1, 'Unknown', 1, 0, 'Unknown', 0;
GO

IF OBJECT_ID('gold.vw_fact_order_items', 'V') IS NOT NULL DROP VIEW gold.vw_fact_order_items;
GO
CREATE VIEW gold.vw_fact_order_items AS
SELECT
    oi.order_item_id,
    oi.order_id,
    ISNULL(dc.customer_id, 'UNKNOWN') AS customer_id,
    ISNULL(dp.product_id, 'UNKNOWN') AS product_id,
    ISNULL(dd.date_key, 19000101) AS order_date_key,
    oi.quantity,
    oi.unit_price,
    oi.discount_pct,
    CAST(ISNULL(oi.quantity, 0) * ISNULL(oi.unit_price, 0) * (1 - ISNULL(oi.discount_pct, 0)) AS DECIMAL(12,2)) AS net_amount
FROM silver.order_items oi
LEFT JOIN silver.orders o ON o.order_id = oi.order_id
LEFT JOIN silver.customers dc ON dc.customer_id = o.customer_id
LEFT JOIN silver.products dp ON dp.product_id = oi.product_id
LEFT JOIN gold.vw_dim_date dd ON dd.full_date = o.order_date;
GO

IF OBJECT_ID('gold.vw_fact_payments', 'V') IS NOT NULL DROP VIEW gold.vw_fact_payments;
GO
CREATE VIEW gold.vw_fact_payments AS
SELECT
    p.payment_id,
    p.order_id,
    ISNULL(dc.customer_id, 'UNKNOWN') AS customer_id,
    ISNULL(dd.date_key, 19000101) AS payment_date_key,
    ISNULL(p.payment_method, 'Unknown') AS payment_method,
    p.amount,
    p.payment_status
FROM silver.payments p
LEFT JOIN silver.orders o ON o.order_id = p.order_id
LEFT JOIN silver.customers dc ON dc.customer_id = o.customer_id
LEFT JOIN gold.vw_dim_date dd ON dd.full_date = p.payment_date;
GO
