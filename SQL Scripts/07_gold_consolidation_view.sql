
-- ===================================================================================================
-- ANALYTICAL GOLD LAYER: MASTER SEMANTIC VIEW CREATION
-- Objective: Denormalize the core transactional and telemetry schemas into a flattened star-schema view.
-- This serves as a highly optimized semantic layer tailored for seamless Power BI consumption.
-- ===================================================================================================

CREATE OR ALTER VIEW gold.vw_ecommerce_behavior_analytics AS
SELECT 
    -- ===============================================================================================
    -- 1. CLICKSTREAM TELEMETRY FACT DATA
    -- Core event vectors capturing customer interaction behaviors and dwell telemetry granularities.
    -- ===============================================================================================
    i.interaction_id AS Interaction_ID,
    i.interaction_type AS Interaction_Type,
    i.timestamp AS Interaction_Time,
    i.dwell_time_ms AS Dwell_Time_MS,

    -- ===============================================================================================
    -- 2. WEB SESSION CONTEXTUAL DIMENSIONS
    -- Tracks the navigational pathways, entry point attribution, and device platform fingerprints.
    -- ===============================================================================================
    s.session_id AS Session_ID,
    s.device_type AS Device_Type,
    s.referrer_source AS Referrer_Source,

    -- ===============================================================================================
    -- 3. USER/CUSTOMER DEMOGRAPHIC DIMENSIONS
    -- Evaluates behavioral trends against geographic locations and historical loyalty groupings.
    -- ===============================================================================================
    u.user_id AS User_ID,
    u.country AS Country,
    u.loyalty_tier AS Loyalty_Tier,

    -- ===============================================================================================
    -- 4. INVENTORY PRODUCT DIMENSIONS
    -- Maps user interaction metrics directly to catalog taxonomies and specific items.
    -- ===============================================================================================
    p.product_id AS Product_ID,
    p.product_name AS Product_Name,
    p.category AS Product_Category,-- Adjusted from product_category to category

    -- ===============================================================================================
    -- 5. CONVERSION & REVENUE OUTCOMES (DOWNSTREAM FACT DECOUPLING)
    -- Joins financial transactions. Mapping directly via interaction_id ensures structural integrity
    -- and completely eliminates the risk of Cartesian row duplication.
    -- ===============================================================================================
    pr.purchase_id AS Purchase_ID,
    pr.quantity AS Quantity,
    pr.unit_price AS Unit_Price,
    pr.total_amount AS Purchase_Amount,

    -- ===============================================================================================
    -- 6. SENTIMENT ANALYSIS OUTCOMES
    -- Incorporates post-purchase customer feedback and qualitative rating thresholds.
    -- ===============================================================================================
    r.Review_ID AS Review_ID,
    r.Review_Rating AS Review_Rating

FROM Silver.interaction_info i
LEFT JOIN Silver.session_info s 
    ON i.session_id = s.session_id
LEFT JOIN Silver.user_info u
    ON i.user_id = u.user_id
LEFT JOIN Silver.product_info p
    ON i.product_id = p.product_id
LEFT JOIN Silver.purchase_info pr
    ON i.interaction_id = pr.interaction_id

-- ===================================================================================================
-- OPTIMIZATION SUBQUERY: PRE-AGGREGATED SENTIMENT RESOLUTION
-- Tactic: Rather than joining the raw reviews table directly, this subquery pre-aggregates evaluations
-- to safely isolate anomalies and calculate clean average rating indexes per user/product pair.
-- ===================================================================================================
LEFT JOIN (
    SELECT 
        user_id, 
        product_id, 
        MAX(review_id) AS Review_ID,        -- Selects the absolute unique identifier if multiples exist
        AVG(CAST(rating AS DECIMAL(3,2))) AS Review_Rating    -- Casted to decimal for clean averages
    FROM Silver.review_info
    GROUP BY user_id, product_id
) r
    ON i.user_id = r.user_id
    AND i.product_id = r.product_id;

GO