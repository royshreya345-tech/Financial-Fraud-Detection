USE finance;
-- clean dataset
CREATE OR REPLACE VIEW vw_clean_transactions AS

WITH converted AS (
    SELECT
        *,
        STR_TO_DATE(
            NULLIF(TRIM(trans_date_trans_time), ''),
            '%d-%m-%Y %H:%i'
        ) AS transaction_datetime,
        STR_TO_DATE(
            NULLIF(TRIM(dob), ''),
            '%d-%m-%Y'
        ) AS date_of_birth
    FROM cc_data
)

SELECT
    trans_num,
    trans_date_trans_time,
    transaction_datetime,

    CASE
        WHEN NULLIF(TRIM(trans_date_trans_time), '') IS NULL
            THEN 'MISSING'
        WHEN transaction_datetime IS NULL
            THEN 'INVALID'
        ELSE 'VALID'
    END AS datetime_quality,

    cc_num,
    merchant,
    category,
    amt,
    gender,
    (YEAR(transaction_datetime) - YEAR(date_of_birth)) AS age,
    state,
    job,
    is_fraud

FROM converted;
SELECT *
FROM vw_clean_transactions;

-- ============================================================
-- ENHANCED SECTION — FEATURE ENGINEERING
-- ============================================================

CREATE OR REPLACE VIEW vw_transaction_features AS
SELECT
    *,
    DATE(transaction_datetime) AS transaction_date,
    HOUR(transaction_datetime) AS transaction_hour,
    DAYOFWEEK(transaction_datetime) AS day_of_week,
    MONTH(transaction_datetime) AS transaction_month,
    YEAR(transaction_datetime) AS transaction_year,

    CASE
        WHEN DAYOFWEEK(transaction_datetime) IN (1, 7)
            THEN 1
        ELSE 0
    END AS is_weekend

FROM vw_clean_transactions;

SELECT *
FROM vw_transaction_features;

-- 1. Transaction-level uniqueness check
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT trans_num) AS distinct_transactions,
    COUNT(*) - COUNT(DISTINCT trans_num) AS duplicate_transaction_rows
FROM vw_transaction_features;

-- 2. Basic null checks
SELECT
    SUM(trans_num IS NULL) AS null_trans_num,
    SUM(amt IS NULL) AS null_amt,
    SUM(cc_num IS NULL) AS null_cc_num,
    SUM(category IS NULL) AS null_category,
    SUM(merchant IS NULL) AS null_merchant,
    SUM(age IS NULL) AS null_age,
    SUM(is_fraud IS NULL) AS null_is_fraud
FROM vw_transaction_features;

-- 3. Invalid or missing date check
SELECT
    datetime_quality,
    COUNT(*) AS transactions
FROM vw_transaction_features
GROUP BY datetime_quality;

-- 4. Invalid amount check
SELECT COUNT(*) AS invalid_amount_rows
FROM vw_transaction_features
WHERE amt <= 0;

-- 6. Biologically implausible ages at time of transaction
SELECT
    'implausible_age' AS check_name,
    COUNT(*) AS affected_rows
FROM vw_transaction_features
WHERE age NOT BETWEEN 13 AND 100;
  
  -- 7.
SELECT
    'location_cc_num_exact_match_rate_pct' AS check_name,
    ROUND(
        100.0 * COUNT(DISTINCT l.cc_num) / (SELECT COUNT(DISTINCT cc_num) FROM location_data),
        4
    ) AS match_rate_pct
FROM location_data l
JOIN cc_data c ON c.cc_num = l.cc_num;


-- 8. Location mapping integrity: repeated card numbers in location_data
SELECT cc_num, COUNT(*) AS location_rows
FROM location_data
GROUP BY cc_num
HAVING COUNT(*) > 1
ORDER BY location_rows DESC;

-- ----------------------------------------------------------------------------------
-- DID NOT blindly join location_data until the duplicate-card rule is understood.
-- ----------------------------------------------------------------------------------

				
        






