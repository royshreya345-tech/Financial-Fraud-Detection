USE finance;

/* ================================================================
   ENHANCED FRAUD ANALYSIS
   ================================================================ */

-- A. Executive KPIs
SELECT
    COUNT(*) AS total_transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND(100 * SUM(is_fraud) / COUNT(*), 4) AS fraud_rate_pct,
    ROUND(SUM(amt), 2) AS total_spend,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END), 2) AS fraud_amount,
    ROUND(AVG(amt), 2) AS avg_transaction_amount,
    ROUND(AVG(CASE WHEN is_fraud = 1 THEN amt END), 2) AS avg_fraud_amount
FROM vw_transaction_features;

-- B. Category risk: use fraud rate, not fraud count alone
SELECT
    category,
    COUNT(*) AS transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND(SUM(is_fraud) / COUNT(*), 6) AS fraud_rate,
    ROUND(SUM(amt), 2) AS total_spend,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END), 2) AS fraud_amount
FROM vw_transaction_features
GROUP BY category
ORDER BY fraud_rate DESC;

-- C. Monthly trend
SELECT
    DATE_FORMAT(transaction_datetime, '%Y-%m-01') AS month_start,
    COUNT(*) AS transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND(SUM(is_fraud) / COUNT(*), 6) AS fraud_rate,
    ROUND(SUM(amt), 2) AS total_spend,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END), 2) AS fraud_amount
FROM vw_transaction_features
GROUP BY month_start
ORDER BY month_start;

-- D. Advanced window-function analysis per card
WITH tx AS (
    SELECT
        cc_num,
        transaction_datetime AS tx_time,
        amt,
        is_fraud,
        LAG(amt) OVER (PARTITION BY cc_num ORDER BY transaction_datetime) AS previous_amt,
        LAG(transaction_datetime) OVER (PARTITION BY cc_num ORDER BY transaction_datetime) AS previous_tx_time,
        ROW_NUMBER() OVER (PARTITION BY cc_num ORDER BY transaction_datetime) AS transaction_sequence
    FROM vw_transaction_features
)
SELECT
    *,
    ROUND(amt - previous_amt, 2) AS amount_change,
    TIMESTAMPDIFF(MINUTE, previous_tx_time, tx_time) AS minutes_since_previous_tx
FROM tx;


-- E. Card-level behavioral summary
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

-- F. Hour-of-day analysis
SELECT
    transaction_hour,
    COUNT(*) AS transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND(SUM(is_fraud) / COUNT(*), 6) AS fraud_rate
FROM vw_transaction_features
GROUP BY transaction_hour
ORDER BY transaction_hour;
