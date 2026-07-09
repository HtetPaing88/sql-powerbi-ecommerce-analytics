-- ===================================================================================================
-- PILLAR 1: ENTITY INTEGRITY & TEXT VALIDATION
-- Objective: Verify Primary Key uniqueness, check for NULL identifiers, and identify string data padding issues.
-- ===================================================================================================

-- 1.1 [INTERACTION INFO] Profiling Primary Key Integrity & Text Padding Variations
SELECT * FROM Bronze.interaction_info;

SELECT interaction_id, COUNT(*)
FROM Bronze.interaction_info
GROUP BY interaction_id
HAVING COUNT(*) > 1 OR interaction_id IS NULL;

SELECT interaction_type
FROM Bronze.interaction_info
WHERE interaction_type != TRIM(interaction_type);


-- 1.2 [PRODUCT INFO] Profiling Primary Key Integrity & Text Padding Variations
SELECT * FROM Bronze.product_info;

SELECT product_id, COUNT(*)
FROM Bronze.product_info
GROUP BY product_id
HAVING COUNT(*) > 1 OR product_id IS NULL;

SELECT product_name FROM Bronze.product_info WHERE product_name != TRIM(product_name);
SELECT product_description FROM Bronze.product_info WHERE product_description != TRIM(product_description);
SELECT category FROM Bronze.product_info WHERE category != TRIM(category);
SELECT sub_category FROM Bronze.product_info WHERE sub_category != TRIM(sub_category);
SELECT brand FROM Bronze.product_info WHERE brand != TRIM(brand);


-- 1.3 [PURCHASE INFO] Profiling Primary Key Integrity & Financial Math Constraints
SELECT * FROM Bronze.purchase_info;

SELECT purchase_id, COUNT(*)
FROM Bronze.purchase_info
GROUP BY purchase_id
HAVING COUNT(*) > 1 OR purchase_id IS NULL;

-- Auditing Financial Subtotals: Validating if Total Amount perfectly reconciles (Quantity * Unit Price)
SELECT DISTINCT total_amount, quantity, unit_price
FROM Bronze.purchase_info
WHERE total_amount != quantity * unit_price
   OR total_amount IS NULL OR quantity IS NULL OR unit_price IS NULL
   OR total_amount <= 0 OR quantity <= 0 OR unit_price <= 0;


-- 1.4 [REVIEW INFO] Profiling Primary Key Integrity & Text Padding Variations
SELECT * FROM Bronze.review_info;

SELECT review_id, COUNT(*)
FROM Bronze.review_info
GROUP BY review_id
HAVING COUNT(*) > 1 OR review_id IS NULL;

SELECT title FROM Bronze.review_info WHERE title != TRIM(title);
SELECT review_text FROM Bronze.review_info WHERE review_text != TRIM(review_text);


-- 1.5 [SESSION INFO] Profiling Primary Key Integrity & Text Padding Variations
SELECT * FROM Bronze.session_info;

SELECT session_id, COUNT(*)
FROM Bronze.session_info
GROUP BY session_id
HAVING COUNT(*) > 1 OR session_id IS NULL;

SELECT device_type FROM Bronze.session_info WHERE device_type != TRIM(device_type);
SELECT referrer_source FROM Bronze.session_info WHERE referrer_source != TRIM(referrer_source);
SELECT is_converted FROM Bronze.session_info WHERE is_converted != TRIM(is_converted);


-- 1.6 [USER INFO] Profiling Primary Key Integrity & Text Padding Variations
SELECT * FROM Bronze.user_info;

SELECT user_id, COUNT(*)
FROM Bronze.user_info
GROUP BY user_id
HAVING COUNT(*) > 1 OR user_id IS NULL;

SELECT gender FROM Bronze.user_info WHERE gender != TRIM(gender);
SELECT country FROM Bronze.user_info WHERE country != TRIM(country);
SELECT city FROM Bronze.user_info WHERE city != TRIM(city);
SELECT income_level FROM Bronze.user_info WHERE income_level != TRIM(income_level);
SELECT preferred_category FROM Bronze.user_info WHERE preferred_category != TRIM(preferred_category);
SELECT loyalty_tier FROM Bronze.user_info WHERE loyalty_tier != TRIM(loyalty_tier);


-- ===================================================================================================
-- PILLAR 2: REFERENTIAL INTEGRITY (ORPHAN RECORD VALIDATION)
-- Objective: Detect broken relationships across tables before pipeline enforcement.
-- ===================================================================================================

-- 2.1 Auditing Interaction Links for Orphan Master Keys (Product, Session, and User)
SELECT COUNT(*) AS orphan_interaction_products
FROM Bronze.interaction_info 
WHERE product_id NOT IN (SELECT product_id FROM Bronze.product_info);

SELECT COUNT(*) AS orphan_interaction_sessions
FROM Bronze.interaction_info 
WHERE session_id NOT IN (SELECT session_id FROM Bronze.session_info);

SELECT COUNT(*) AS orphan_interaction_users
FROM Bronze.interaction_info 
WHERE user_id NOT IN (SELECT user_id FROM Bronze.user_info);


-- 2.2 Auditing Transactional Purchases for Orphan Master Keys (Product, Session, and User)
SELECT COUNT(*) AS orphan_purchase_products 
FROM Bronze.purchase_info 
WHERE product_id NOT IN (SELECT product_id FROM Bronze.product_info);

SELECT COUNT(*) AS orphan_purchase_sessions 
FROM Bronze.purchase_info 
WHERE session_id NOT IN (SELECT session_id FROM Bronze.session_info);

SELECT COUNT(*) AS orphan_purchase_users
FROM Bronze.purchase_info 
WHERE user_id NOT IN (SELECT user_id FROM Bronze.user_info);


-- 2.3 Auditing Sentiment Reviews for Orphan Master Keys (Product and User)
SELECT COUNT(*) AS orphan_review_products
FROM Bronze.review_info 
WHERE product_id NOT IN (SELECT product_id FROM Bronze.product_info);

SELECT COUNT(*) AS orphan_review_users
FROM Bronze.review_info 
WHERE user_id NOT IN (SELECT user_id FROM Bronze.user_info);


-- ===================================================================================================
-- PILLAR 3: BUSINESS CONSTRAINTS & CHRONOLOGICAL LOGIC
-- Objective: Enforce real-world workflow logic constraints on time-series records.
-- ===================================================================================================

-- 3.1 Chronological Sequencing Check: Ensuring Transactions do not antedate Account Signups
SELECT p.purchase_id, p.order_date, u.signup_date 
FROM Bronze.purchase_info p
JOIN Bronze.user_info u ON p.user_id = u.user_id
WHERE p.order_date < u.signup_date;


-- 3.2 Chronological Sequencing Check: Ensuring Product Reviews do not antedate Purchase Dates
SELECT r.review_id, r.review_date, p.order_date
FROM Bronze.review_info r
JOIN Bronze.purchase_info p ON r.purchase_id = p.purchase_id
WHERE r.review_date < p.order_date;


-- ===================================================================================================
-- PILLAR 4: DOMAIN COHERENCE & BOUNDARY ATTRIBUTES
-- Objective: Restrict categorical variances to valid definitions and isolate structural outliers.
-- ===================================================================================================

-- 4.1 Categorical Scope Validation: Isolating out-of-bounds Device and Interaction types
SELECT DISTINCT device_type 
FROM Bronze.session_info 
WHERE device_type NOT IN ('desktop', 'mobile', 'tablet');

SELECT DISTINCT interaction_type 
FROM Bronze.interaction_info 
WHERE interaction_type NOT IN ('view', 'click', 'add_to_cart', 'remove_from_cart', 'add_to_wishlist', 'remove_from_wishlist');


-- 4.2 Numerical Boundary Validation: Checking Demographics and Sentiment Scores for Range Outliers
SELECT user_id, age 
FROM Bronze.user_info 
WHERE age < 18 OR age > 100;

SELECT review_id, rating 
FROM Bronze.review_info 
WHERE rating < 1 OR rating > 5;