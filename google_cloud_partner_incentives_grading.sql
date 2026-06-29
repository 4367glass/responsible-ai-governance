-- ====================================================================
-- ENTERPRISE BI ARCHITECTURE: GOOGLE CLOUD PARTNER INCENTIVES GRADING
-- DESIGNATION: AUTOMATED COMPLIANCE & REVENUE TIERING SCHEMA
-- CORE CAPABILITY: WINDOW FUNCTIONS & CONDITIONAL LOGIC ENFORCEMENT
-- ====================================================================

WITH partner_quarterly_performance AS (
    SELECT 
        partner_id,
        partner_name,
        global_region,
        current_quarter_gcp_spend,
        previous_quarter_gcp_spend,
        certified_cloud_engineers,
        
        -- POLICY ENFORCEMENT: Handle potential null records in financial fields
        NVL(current_quarter_gcp_spend, 0) AS baseline_spend,
        
        -- STRATEGIC METRIC: Calculate Quarter-over-Quarter (QoQ) revenue growth percentage
        CASE 
            WHEN NVL(previous_quarter_gcp_spend, 0) = 0 THEN 0
            ELSE ROUND(((current_quarter_gcp_spend - previous_quarter_gcp_spend) / previous_quarter_gcp_spend) * 100, 2)
        END AS qoq_growth_pct,
        
        -- GOVERNANCE CONTROL: Rank partners globally by revenue using a window function
        DENSE_RANK() OVER (ORDER BY current_quarter_gcp_spend DESC) AS global_revenue_rank

    FROM google_cloud_bi.partner_operations.partner_revenue_ledger
    WHERE contract_status = 'ACTIVE'
),

governed_tiering_engine AS (
    SELECT
        partner_id,
        partner_name,
        global_region,
        baseline_spend,
        qoq_growth_pct,
        certified_cloud_engineers,
        global_revenue_rank,
        
        -- AUTOMATED REVENUE GRADING SCHEMA:
        -- platinum: Top 50 global ranking OR > $5M spend AND at least 10 certified engineers.
        -- gold: Spend between $1M and $5M AND at least 5 certified engineers.
        -- silver: All other active partners making baseline contributions.
        CASE
            WHEN global_revenue_rank <= 50 OR (baseline_spend >= 5000000 AND certified_cloud_engineers >= 10) 
                THEN 'PLATINUM'
            WHEN baseline_spend >= 1000000 AND certified_cloud_engineers >= 5 
                THEN 'GOLD'
            ELSE 'SILVER'
        END AS earned_partner_tier
        
    FROM partner_quarterly_performance
)

-- Final presentation payload with built-in incentive multiplier calculations
SELECT 
    partner_id,
    partner_name,
    global_region,
    baseline_spend AS gcp_revenue_contribution,
    qoq_growth_pct,
    certified_cloud_engineers,
    global_revenue_rank,
    earned_partner_tier,
    
    -- FINANCIAL STRATEGY: Calculate dynamic incentive rebates based on earned tiers
    CASE earned_partner_tier
        WHEN 'PLATINUM' THEN ROUND(baseline_spend * 0.08, 2) -- 8% Rebate Multiplier
        WHEN 'GOLD'     THEN ROUND(baseline_spend * 0.05, 2) -- 5% Rebate Multiplier
        ELSE ROUND(baseline_spend * 0.02, 2)                 -- 2% Rebate Multiplier
    END AS quarterly_incentive_rebate_usd

FROM governed_tiering_engine
ORDER BY global_revenue_rank ASC;
