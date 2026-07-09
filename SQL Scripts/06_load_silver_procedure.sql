CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    
    BEGIN TRY
        -- ===================================================================================================
        -- 1. [INTERACTION INFO] Direct Silver Load & Telemetry Schema Mapping
        -- Processing: Structuring user telemetry, removing whitespace padding, and mapping clickstream markers.
        -- ===================================================================================================
        TRUNCATE TABLE silver.interaction_info;
        
        INSERT INTO silver.interaction_info (
            interaction_id, user_id, product_id, session_id, interaction_type, timestamp, dwell_time_ms
        )
        SELECT 
            interaction_id,
            user_id, 
            product_id, 
            session_id, 
            TRIM(interaction_type) AS interaction_type, 
            timestamp, 
            dwell_time_ms 
        FROM bronze.interaction_info;

        -- ===================================================================================================
        -- 2. [PRODUCT INFO] Product Master Transformation & Date Standardization
        -- Processing: Converting zero-value rating outliers to NULL, trimming catalog strings, and handling 
        -- multiple date formats conditionally.
        -- ===================================================================================================
        TRUNCATE TABLE silver.product_info;
        
        INSERT INTO silver.product_info (
            product_id, product_name, product_description, category, sub_category, brand, price, rating_avg, review_count, stock_quantity, date_added
        )
        SELECT 
            product_id,
            TRIM(product_name) AS product_name,
            TRIM(product_description) AS product_description,
            TRIM(category) AS category, -- Kept aligned with bronze structure
            TRIM(sub_category) AS sub_category,
            TRIM(brand) AS brand,
            price, 
            NULLIF(rating_avg, 0.0) AS rating_avg,
            review_count,
            stock_quantity,
            COALESCE(
                TRY_CONVERT(DATE, TRIM(date_added), 120), -- yyyy-mm-dd
                TRY_CONVERT(DATE, TRIM(date_added), 105), -- dd-mm-yyyy
                TRY_CONVERT(DATE, TRIM(date_added), 1)    -- mm/dd/yy
            ) AS date_added
        FROM bronze.product_info;

        -- ===================================================================================================
        -- 3. [PURCHASE INFO] Transaction Consolidation & Financial Grain Ingestion
        -- Processing: Enforcing strong relational schemas on ledger data for quantities, unit prices, and revenues.
        -- ===================================================================================================
        TRUNCATE TABLE silver.purchase_info;
        
        INSERT INTO silver.purchase_info (
            purchase_id, order_id, user_id, product_id, session_id, interaction_id, quantity, unit_price, total_amount, order_date
        )
        SELECT 
            purchase_id,
            order_id,
            user_id,
            product_id,
            session_id,
            interaction_id,
            quantity,
            unit_price,
            total_amount,
            order_date
        FROM bronze.purchase_info;

        -- ===================================================================================================
        -- 4. [REVIEW INFO] Customer Review Sentiment & Text Ledger Normalization
        -- Processing: Cleansing text attributes and standardizing qualitative evaluation fields.
        -- ===================================================================================================
        TRUNCATE TABLE silver.review_info;
        
        INSERT INTO silver.review_info (
            review_id, user_id, product_id, purchase_id, rating, title, review_text, review_date
        )
        SELECT 
            review_id,
            user_id,
            product_id,
            purchase_id,
            rating,
            TRIM(title) AS title,
            TRIM(review_text) AS review_text,
            review_date
        FROM bronze.review_info;

        -- ===================================================================================================
        -- 5. [SESSION INFO] Web Session Cleansing, PascalCase Normalization, & Boolean Casts
        -- Processing: Formatting device/referrer strings into PascalCase and converting text flags into binary bits.
        -- ===================================================================================================
        TRUNCATE TABLE silver.session_info;
        
        INSERT INTO silver.session_info (
            session_id, user_id, start_time, device_type, referrer_source, is_converted
        )
        SELECT 
            session_id,
            user_id,
            start_time,
            CASE 
                WHEN device_type IS NULL THEN NULL
                ELSE CONCAT(UPPER(SUBSTRING(TRIM(device_type), 1, 1)), LOWER(SUBSTRING(TRIM(device_type), 2, LEN(device_type))))
            END AS device_type,
            CASE 
                WHEN referrer_source IS NULL THEN NULL
                ELSE CONCAT(UPPER(SUBSTRING(TRIM(referrer_source), 1, 1)), LOWER(SUBSTRING(TRIM(referrer_source), 2, LEN(referrer_source))))
            END AS referrer_source,
            CASE 
                WHEN LOWER(TRIM(is_converted)) = 'true' THEN 1
                WHEN LOWER(TRIM(is_converted)) = 'false' THEN 0
                ELSE NULL
            END AS is_converted
        FROM bronze.session_info;

        -- ===================================================================================================
        -- 6. [USER INFO] Demographics Standardization, ISO Decoding, & Tier Standardization
        -- Processing: Resolving ISO codes to country names, cleaning demographics, and normalizing loyalty tiers.
        -- ===================================================================================================
        TRUNCATE TABLE silver.user_info;
        
        INSERT INTO silver.user_info (
            user_id, age, gender, country, city, signup_date, income_level, preferred_category, loyalty_tier
        )
        SELECT 
            user_id,
            age,
            TRIM(gender) AS gender,
            CASE UPPER(TRIM(country))
                WHEN 'DE' THEN 'Germany'
                WHEN 'IN' THEN 'India'
                WHEN 'GB' THEN 'United Kingdom'
                WHEN 'SE' THEN 'Sweden'
                WHEN 'IT' THEN 'Italy'
                WHEN 'NL' THEN 'Netherlands'
                WHEN 'AU' THEN 'Australia'
                WHEN 'MX' THEN 'Mexico'
                WHEN 'CA' THEN 'Canada'
                WHEN 'DK' THEN 'Denmark'
                WHEN 'BR' THEN 'Brazil'
                WHEN 'CH' THEN 'Switzerland'
                WHEN 'FR' THEN 'France'
                WHEN 'US' THEN 'United States'
                WHEN 'AE' THEN 'United Arab Emirates'
                WHEN 'KR' THEN 'South Korea'
                WHEN 'JP' THEN 'Japan'
                WHEN 'ES' THEN 'Spain'
                WHEN 'NO' THEN 'Norway'
                WHEN 'SG' THEN 'Singapore'
                ELSE TRIM(country) -- Safe fallback if country is already written out full-text in raw data
            END AS country,
            TRIM(city) AS city,
            signup_date,
            TRIM(income_level) AS income_level,
            TRIM(preferred_category) AS preferred_category,
            CASE 
                WHEN loyalty_tier IS NULL THEN NULL
                ELSE CONCAT(UPPER(SUBSTRING(TRIM(loyalty_tier), 1, 1)), LOWER(SUBSTRING(TRIM(loyalty_tier), 2, LEN(loyalty_tier))))
            END AS loyalty_tier
        FROM bronze.user_info;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END


-- Execute the procedure to load everything
EXEC silver.load_silver;
