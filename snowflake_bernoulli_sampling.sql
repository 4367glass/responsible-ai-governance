-- ====================================================================
-- ENTERPRISE BI OPTIMIZATION: ACCELERATED DATA SAMPLING FOR RAPID QA
-- METHODOLOGY: ROW-LEVEL BERNOULLI PROBABILITY SAMPLING
-- ENVIRONMENT: SNOWFLAKE CLOUD DATA WAREHOUSE
-- TARGET COMPONENT: DOWNSTREAM PYTHON SVM MACHINE LEARNING INFERENCE
-- ====================================================================

WITH fast_data_sample AS (
    SELECT 
        age,
        -- Handle missing categorical text values using Snowflake's NVL function
        NVL(job, 'unknown') AS job,
        NVL(marital, 'unknown') AS marital,
        NVL(education, 'unknown') AS education,
        balance,
        housing_loan,
        personal_loan,
        subscription_target AS y
    FROM core_db.marketing_schema.bank_prospect_records
    WHERE is_active_record = TRUE
    
    -- DATA GOVERNANCE ENFORCEMENT: 
    -- 1. Explicitly dropped 'duration' (call length) to permanently eliminate Data Leakage risk.
    -- 2. Pulls a mathematically random 1% slice of total dataset rows for rapid QA testing.
    -- 3. SEED (42) locks the sampling logic so the exact same rows return every run for reproducibility.
    SAMPLE BERNOULLI (1) SEED (42)
)

-- Final extraction payload optimized for model scaling and predictions
SELECT 
    age,
    job,
    marital,
    education,
    balance,
    housing_loan,
    personal_loan,
    y
FROM fast_data_sample;
