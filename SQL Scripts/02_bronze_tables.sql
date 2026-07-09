
-- ===================================================================================================
-- DATABASE ENVIRONMENT TARGETING
-- ===================================================================================================
USE ECommerce;
GO

-- ===================================================================================================
-- STEP 1: SCHEMATIC DEPENDENCY DECOUPLING (TEARDOWN)
-- Objective: Safely drop existing Bronze entities in reverse order of relational dependency 
-- to maintain a clean execution state.
-- ===================================================================================================

PRINT '>> Tearing down existing Bronze landing tables if they exist...';
DROP TABLE IF EXISTS bronze.review_info;
DROP TABLE IF EXISTS bronze.purchase_info;
DROP TABLE IF EXISTS bronze.interaction_info;
DROP TABLE IF EXISTS bronze.session_info;
DROP TABLE IF EXISTS bronze.product_info;
DROP TABLE IF EXISTS bronze.user_info;
GO

-- ===================================================================================================
-- STEP 2: RAW LANDING STAGING DEFINITIONS (BRONZE DDL)
-- Objective: Provision structural schemas optimized for initial raw data ingestion. 
-- Data constraints are intentionally relaxed to ensure bulk loads do not experience structural failures.
-- ===================================================================================================

-- 2.1 [USER INFO] Raw Demographics Landing Schema
-- Captures static global account traits, geographical dimensions, and economic profile classes.
CREATE TABLE bronze.user_info (
    user_id            UNIQUEIDENTIFIER PRIMARY KEY,
    age                INT,
    gender             NVARCHAR(20),
    country            NVARCHAR(150),
    city               NVARCHAR(100),
    signup_date        DATE,
    income_level       NVARCHAR(12),
    preferred_category NVARCHAR(50),
    loyalty_tier       NVARCHAR(15)
);

-- 2.2 [PRODUCT INFO] Catalog Inventory Staging Schema
-- Stores product specifications and pricing configurations. 'date_added' is kept as an NVARCHAR 
-- to safely accept varied unformatted source text variations before cleaning.
CREATE TABLE bronze.product_info (
    product_id          UNIQUEIDENTIFIER PRIMARY KEY,
    product_name        NVARCHAR(150),
    product_description NVARCHAR(MAX),
    category            NVARCHAR(100),
    sub_category        NVARCHAR(100),
    brand               NVARCHAR(100),
    price               DECIMAL(10, 2) NOT NULL,
    rating_avg          DECIMAL(2, 1) DEFAULT 0.0,
    review_count        INT,
    stock_quantity      INT,
    date_added          NVARCHAR(20)
);

-- 2.3 [SESSION INFO] Web Traffic Telemetry Landing Schema
-- Collects initial session-level tracking paths. 'is_converted' uses a string data format 
-- to accommodate loose boolean string indicators ('True'/'False') directly from web logs.
CREATE TABLE bronze.session_info (
    session_id      UNIQUEIDENTIFIER PRIMARY KEY,
    user_id         UNIQUEIDENTIFIER,
    start_time      DATETIME2 DEFAULT SYSDATETIME() NOT NULL,
    device_type     NVARCHAR(50),
    referrer_source NVARCHAR(50),
    is_converted    NVARCHAR(10) NOT NULL
);

-- 2.4 [INTERACTION INFO] High-Velocity Clickstream Event Schema
-- Designed as a heavy event-logging structure to track atomic clickstreams, interface interactions, 
-- and detailed navigation dwell-time tracking.
CREATE TABLE bronze.interaction_info (
    interaction_id   UNIQUEIDENTIFIER PRIMARY KEY,
    user_id          UNIQUEIDENTIFIER,
    product_id       UNIQUEIDENTIFIER,
    session_id       UNIQUEIDENTIFIER,
    interaction_type NVARCHAR(50),
    timestamp        DATETIME2 DEFAULT SYSDATETIME() NOT NULL,
    dwell_time_ms    INT NOT NULL
);

-- 2.5 [PURCHASE INFO] Transactional Sales Ledger Schema
-- Captures precise checkout information, tying conversions back to their original 
-- web session paths and interaction triggers.
CREATE TABLE bronze.purchase_info (
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

-- 2.6 [REVIEW INFO] User Sentiment & Feedback Staging Schema
-- Captures qualitative buyer evaluation strings along with atomic star ratings. 
-- Text blocks leverage large storage capacities (`NVARCHAR(MAX)`) to eliminate truncation risks.
CREATE TABLE bronze.review_info (
    review_id     UNIQUEIDENTIFIER PRIMARY KEY,
    user_id       UNIQUEIDENTIFIER,
    product_id    UNIQUEIDENTIFIER,
    purchase_id   UNIQUEIDENTIFIER,
    rating        TINYINT NOT NULL,
    title         NVARCHAR(150) NULL,
    review_text   NVARCHAR(MAX) NULL,
    review_date   DATETIME2 DEFAULT SYSDATETIME() NOT NULL
);