-- =============================================================================
-- 05_feature_engineering.sql
-- -----------------------------------------------------------------------------
-- Purpose : Add the calendar and demographic features that are cheap to
--           derive in SQL directly from fact_transactions. Behavioral and
--           geographic features that need more than date arithmetic
--           (transaction velocity, cardholder-merchant distance) are built
--           in the Python layer — see python/02_feature_engineering.ipynb —
--           and joined back in before modeling.
-- =============================================================================

DROP TABLE IF EXISTS fraud_features;

CREATE TABLE fraud_features AS
SELECT
    *,

    CASE day_of_week
        WHEN 1 THEN 'Sunday'    
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'   
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'  
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END AS day_name,
    
    CASE
        WHEN age < 25 THEN 'Under 25'
        WHEN age < 40 THEN '25-39'
        WHEN age < 55 THEN '40-54'
        WHEN age < 70 THEN '55-69'
        ELSE '70+'
    END AS age_bucket

FROM vw_transaction_features;

CREATE INDEX IF NOT EXISTS idx_features_hour ON fraud_features(transaction_hour);
CREATE INDEX IF NOT EXISTS idx_features_cc_num ON fraud_features(cc_num);

SELECT COUNT(*) AS fraud_features_row_count FROM fraud_features;
