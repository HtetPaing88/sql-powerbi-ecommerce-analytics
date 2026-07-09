
USE ECommerce;
GO

-- ===================================================================================================
-- STEP 1: SILVER SCHEMA TEARDOWN
-- Objective: Safely clear old Silver entities in reverse order of relational dependency 
-- to maintain a clean execution state.
-- ===================================================================================================
PRINT '>> Tearing down existing Silver tables if they exist...';
DROP TABLE IF EXISTS silver.user_info;
DROP TABLE IF EXISTS silver.session_info;
DROP TABLE IF EXISTS silver.review_info;
DROP TABLE IF EXISTS silver.purchase_info;
DROP TABLE IF EXISTS silver.product_info;
DROP TABLE IF EXISTS silver.interaction_info;
GO

-- ===================================================================================================
-- STEP 2: CONFORMED TRANSFORMED DEFINITIONS (SILVER DDL)
-- Objective: Provision structural schemas that map exactly 1:1 with your Bronze entities and 
-- match the exact execution sequence and snake_case naming conventions of the Silver load procedure.
-- ===================================================================================================

-- 2.1 [INTERACTION INFO] Cleansed High-Velocity Event Log Master
CREATE TABLE silver.interaction_info (
    interaction_id   UNIQUEIDENTIFIER PRIMARY KEY,
    user_id          UNIQUEIDENTIFIER,
    product_id       UNIQUEIDENTIFIER,
    session_id       UNIQUEIDENTIFIER,
    interaction_type NVARCHAR(50),
    timestamp        DATETIME2,
    dwell_time_ms    INT NOT NULL
);

-- 2.2 [PRODUCT INFO] Cleansed Catalog Inventory Master
CREATE TABLE silver.product_info (
    product_id          UNIQUEIDENTIFIER PRIMARY KEY,
    product_name        NVARCHAR(150),
    product_description NVARCHAR(MAX),
    category            NVARCHAR(100), -- Aligned to match your procedure's category mapping
    sub_category        NVARCHAR(100),
    brand               NVARCHAR(100),
    price               DECIMAL(10, 2) NOT NULL,
    rating_avg          DECIMAL(2, 1), -- Nullable to support your NULLIF(rating_avg, 0.0) cleaning
    review_count        INT,
    stock_quantity      INT,
    date_added          NVARCHAR(20)   -- Aligned to receive formatted string dates
);

-- 2.3 [PURCHASE INFO] Cleansed Transaction Ledger Master
CREATE TABLE silver.purchase_info (
    purchase_id    UNIQUEIDENTIFIER PRIMARY KEY,
    order_id       UNIQUEIDENTIFIER,
    user_id        UNIQUEIDENTIFIER,
    product_id     UNIQUEIDENTIFIER,
    session_id     UNIQUEIDENTIFIER,
    interaction_id UNIQUEIDENTIFIER,
    quantity       INT,
    unit_price     DECIMAL(10, 2) NOT NULL,
    total_amount   DECIMAL(10, 2) NOT NULL,
    order_date     DATE
);

-- 2.4 [REVIEW INFO] Cleansed Sentiment Feedback Master
CREATE TABLE silver.review_info (
    review_id     UNIQUEIDENTIFIER PRIMARY KEY,
    user_id       UNIQUEIDENTIFIER,
    product_id    UNIQUEIDENTIFIER,
    purchase_id   UNIQUEIDENTIFIER,
    rating        TINYINT NOT NULL,
    title         NVARCHAR(150) NULL,
    review_text   NVARCHAR(MAX) NULL,
    review_date   DATETIME2
);

-- 2.5 [SESSION INFO] Cleansed Web Traffic Telemetry Master
CREATE TABLE silver.session_info (
    session_id      UNIQUEIDENTIFIER PRIMARY KEY,
    user_id         UNIQUEIDENTIFIER,
    start_time      DATETIME2,
    device_type     NVARCHAR(50), -- Enforces proper capitalized title casing
    referrer_source NVARCHAR(50), -- Enforces proper capitalized title casing
    is_converted    INT           -- Upgraded from text string to numeric binary boolean (1 / 0)
);

-- 2.6 [USER INFO] Cleansed Demographics Master
CREATE TABLE silver.user_info (
    user_id            UNIQUEIDENTIFIER PRIMARY KEY,
    age                INT,
    gender             NVARCHAR(20),
    country            NVARCHAR(150), -- Holds fully expanded decoded country strings
    city               NVARCHAR(100),
    signup_date        DATE,
    income_level       NVARCHAR(12),
    preferred_category NVARCHAR(50),
    loyalty_tier       NVARCHAR(15)  -- Standardized to Uniform Case
);
GO