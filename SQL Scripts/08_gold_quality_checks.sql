
-- ===================================================================================================
-- PILLAR 5: GOLD SEMANTIC LAYER SIGN-OFF & RECONCILIATION
-- Objective: Conduct complete technical auditing across the consolidated presentation view 
-- to guarantee exact dimensional lineage, financial accuracy, and grain integrity.
-- ===================================================================================================

-- 5.1 Presentation Grain Integrity Audit
-- Validates that the primary key grain remains unique and that joins did not cause a fan-out explosion.
SELECT
    Interaction_ID,
    COUNT(*) AS Row_Count
FROM gold.vw_ecommerce_behavior_analytics
GROUP BY Interaction_ID
HAVING COUNT(*) > 1;


-- 5.2 Row Lineage & Data Retention Audit
-- Verifies complete data preservation by reconciling the base Bronze source rows directly against the Gold view.
SELECT 
    (SELECT COUNT(*) FROM bronze.interaction_info) AS Raw_Bronze_Rows,    
    (SELECT COUNT(*) FROM gold.vw_ecommerce_behavior_analytics) AS Final_Gold_Rows,
    CASE 
        WHEN (SELECT COUNT(*) FROM bronze.interaction_info) = (SELECT COUNT(*) FROM gold.vw_ecommerce_behavior_analytics) 
        THEN 'PASSED: No rows dropped or inflated.'
        ELSE 'FAILED: Row mismatch detected!'
    END AS Data_Retention_Status;


-- 5.3 Financial Ledger Balancing & Revenue Reconciliation
-- Ensures absolute balance sheet alignment by matching downstream aggregated sales revenue directly back to source transactions.
SELECT 
    (SELECT SUM(total_amount) FROM bronze.purchase_info) AS Source_Purchase_Total,    
    (SELECT SUM(Purchase_Amount) FROM gold.vw_ecommerce_behavior_analytics) AS Gold_Consolidated_Total,
    CASE 
        WHEN (SELECT SUM(total_amount) FROM bronze.purchase_info) = (SELECT SUM(Purchase_Amount) FROM gold.vw_ecommerce_behavior_analytics)
        THEN 'PASSED: Revenue completely matches.'
        ELSE 'FAILED: Financial discrepancy found!'
    END AS Revenue_Sync_Status;


-- 5.4 Relational Funnel Logic Validation
-- Flags broken funnels or impossible state events, such as tracking a financial conversion completely decoupled from a session footprint.
SELECT COUNT(*) AS Corrupted_Purchase_Rows
FROM gold.vw_ecommerce_behavior_analytics
WHERE Purchase_ID IS NOT NULL 
  AND Session_ID IS NULL;
