USE finance;

-- -------------------------------------------------------------------------
-- 1. Fraud Daily KPI -- trend layer for the executive dashboard
-- -------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_fraud_daily_kpi AS
SELECT
	transaction_date,
    COUNT(*) AS transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND(SUM(is_fraud) / COUNT(*), 6) AS fraud_rate,
    ROUND(SUM(amt), 2) AS total_spend,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END), 2) AS fraud_amount
FROM vw_transaction_features
GROUP BY transaction_date;
SELECT *
FROM vw_fraud_daily_kpi;


-- --------------------------------------------------------------------------
-- 2. Fraud Category KPI -- categories carrying the fraud risk
-- --------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_fraud_category_kpi AS
SELECT
    category,
    COUNT(*) AS transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND(SUM(is_fraud) / COUNT(*), 6) AS fraud_rate,
    ROUND(SUM(amt), 2) AS total_spend,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END), 2) AS fraud_amount
FROM vw_transaction_features
GROUP BY category;

SELECT *
FROM vw_fraud_category_kpi;

-- -------------------------------------------------------------------------- 
-- 3. Fraud Merchant KPI - merchant-level volume, value and fraud exposure
-- --------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_fraud_merchant_kpi AS
SELECT
    merchant,
    COUNT(*) AS transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND(SUM(is_fraud) / COUNT(*), 6) AS fraud_rate,
    ROUND(SUM(amt), 2) AS total_spend,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END), 2) AS fraud_amount
FROM vw_transaction_features
GROUP BY merchant;

SELECT *
FROM vw_fraud_merchant_kpi;

-- --------------------------------------------------------------------------
-- 4. Fraud State KPI
-- --------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_fraud_state_kpi AS
SELECT
    state,
    COUNT(*) AS transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND(SUM(is_fraud) / COUNT(*), 6) AS fraud_rate,
    ROUND(SUM(amt), 2) AS total_spend,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END), 2) AS fraud_amount
FROM cc_data
GROUP BY state;

SELECT *
FROM vw_fraud_state_kpi;


-- -------------------------------------------------------------------------
-- 5. Fraud Monthly KPI
-- -------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_fraud_monthly_kpi AS
SELECT
    DATE_FORMAT(transaction_datetime, '%Y-%m-01') AS month_start,
    COUNT(*) AS transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND(SUM(is_fraud) / COUNT(*), 6) AS fraud_rate,
    ROUND(SUM(amt), 2) AS total_spend,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END), 2) AS fraud_amount
FROM vw_transaction_features
GROUP BY month_start;

SELECT *
FROM vw_fraud_monthly_kpi;


-- ---------------------------------------------------------------------------
-- 6.Fraud_customer_risk — one row per cardholder
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_fraud_customer_risk AS
WITH tx AS (
    SELECT
        cc_num,
        amt,
        is_fraud,
        transaction_datetime AS tx_time
    FROM vw_transaction_features
)
SELECT
    cc_num,
    COUNT(*) AS transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND(SUM(is_fraud) / COUNT(*), 6) AS fraud_rate,
    ROUND(AVG(amt), 2) AS avg_amount,
    ROUND(MAX(amt), 2) AS max_amount,
    COUNT(DISTINCT DATE(tx_time)) AS active_days
FROM tx
GROUP BY cc_num
ORDER BY fraud_rate DESC, fraud_transactions DESC;

SELECT *
FROM vw_fraud_customer_risk;

-- ---------------------------------------------------------------------
-- 7. vw-risk
-- ---------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_fraud_risk AS
SELECT 'fraud_daily_kpi'   AS table_name, 
		COUNT(*) AS row_count FROM vw_fraud_daily_kpi
UNION ALL
SELECT 'fraud_category_kpi',              
		COUNT(*) FROM vw_fraud_category_kpi
UNION ALL
SELECT 'fraud_merchant_kpi',              
		COUNT(*) FROM vw_fraud_merchant_kpi
UNION ALL
SELECT 'fraud_customer_risk',             
		COUNT(*) FROM vw_fraud_customer_risk;
SELECT * 
FROM finance.vw_fraud_risk;
