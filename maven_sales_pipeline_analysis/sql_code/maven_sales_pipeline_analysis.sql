-- ================================================================================
-- MAVEN SALES PIPELINE ANALYSIS
-- ================================================================================
-- Author: Osinusi Ayodeji 
-- Description: Comprehensive analysis of sales pipeline data including opportunity
--              tracking, agent performance, product analysis, and account management
-- ================================================================================

-- ================================================================================
-- SECTION 1: SALES OPPORTUNITIES ANALYSIS
-- ================================================================================

-- Query 1.1: Monthly Sales Opportunities Trend
-- Purpose: Track opportunity creation patterns and identify peak months
-- Business Impact: Helps with resource planning and seasonal trend analysis
SELECT 
    YEAR(engage_date) AS engage_year,
    MONTHNAME(engage_date) AS engage_month,
    COUNT(*) AS opportunity_count
FROM sales_pipeline
WHERE engage_date IS NOT NULL
GROUP BY YEAR(engage_date), MONTH(engage_date), MONTHNAME(engage_date)
ORDER BY engage_year, MONTH(engage_date);

-- Query 1.2: Peak Opportunity Month Identification
-- Purpose: Find the single month with highest opportunity creation
SELECT 
    YEAR(engage_date) AS engage_year,
    MONTHNAME(engage_date) AS engage_month,
    COUNT(*) AS opportunity_count
FROM sales_pipeline
WHERE engage_date IS NOT NULL
GROUP BY YEAR(engage_date), MONTHNAME(engage_date)
ORDER BY opportunity_count DESC
LIMIT 1;

-- Query 1.3: Sales Cycle Analysis by Deal Stage
-- Purpose: Compare average deal duration between won and lost deals
-- Business Impact: Identifies bottlenecks in sales process
SELECT 
    deal_stage,
    COUNT(*) AS deal_count,
    AVG(DATEDIFF(close_date, engage_date)) AS avg_days_open,
    MIN(DATEDIFF(close_date, engage_date)) AS min_days_open,
    MAX(DATEDIFF(close_date, engage_date)) AS max_days_open
FROM sales_pipeline
WHERE engage_date IS NOT NULL 
    AND close_date IS NOT NULL
    AND deal_stage IN ('Won', 'Lost')
GROUP BY deal_stage
ORDER BY avg_days_open;

-- Query 1.4: Overall Pipeline Health Metrics
-- Purpose: Calculate key performance indicators for pipeline management
SELECT 
    COUNT(*) AS total_opportunities,
    SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) AS won_deals,
    SUM(CASE WHEN deal_stage = 'Lost' THEN 1 ELSE 0 END) AS lost_deals,
    ROUND(AVG(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) * 100, 2) AS win_rate_percent,
    ROUND(AVG(CASE WHEN deal_stage = 'Lost' THEN 1 ELSE 0 END) * 100, 2) AS loss_rate_percent
FROM sales_pipeline;

-- ================================================================================
-- SECTION 2: SALES AGENT PERFORMANCE ANALYSIS
-- ================================================================================

-- Query 2.1: Individual Agent Performance Ranking
-- Purpose: Rank sales agents by win rate and identify top performers
-- Business Impact: Performance evaluation and coaching opportunities
SELECT 
    sales_agent,
    COUNT(*) AS total_opportunities,
    SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) AS won_deals,
    ROUND(AVG(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) * 100, 2) AS win_rate_percent,
    RANK() OVER (ORDER BY AVG(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) DESC) AS performance_rank
FROM sales_pipeline
WHERE sales_agent IS NOT NULL
GROUP BY sales_agent
HAVING COUNT(*) >= 5  -- Filter agents with at least 5 opportunities for statistical relevance
ORDER BY win_rate_percent DESC;

-- Query 2.2: Top Revenue Generating Agent
-- Purpose: Identify agent who generated the most revenue from won deals
SELECT
    sales_agent,
    COUNT(*) AS won_deals,
    SUM(close_value) AS total_revenue,
    ROUND(AVG(close_value), 2) AS avg_deal_value
FROM sales_pipeline
WHERE deal_stage = 'Won'
    AND close_value IS NOT NULL
GROUP BY sales_agent
ORDER BY total_revenue DESC
LIMIT 5;

-- Query 2.3: Manager Performance Analysis
-- Purpose: Evaluate team performance by manager to identify coaching needs
-- Business Impact: Management effectiveness and team development insights
SELECT 
    st.manager,
    COUNT(sp.opportunity_id) AS total_opportunities,
    SUM(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END) AS won_deals,
    ROUND(AVG(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END) * 100, 2) AS team_win_rate,
    SUM(CASE WHEN sp.deal_stage = 'Won' THEN sp.close_value ELSE 0 END) AS total_revenue
FROM sales_teams st 
LEFT JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
WHERE sp.opportunity_id IS NOT NULL
GROUP BY st.manager
ORDER BY team_win_rate DESC;

-- Query 2.4: Regional Office Performance for GTX Plus Pro
-- Purpose: Analyze regional sales performance for specific high-value product
SELECT
    st.regional_office,
    COUNT(*) AS units_sold,
    SUM(sp.close_value) AS total_revenue,
    ROUND(AVG(sp.close_value), 2) AS avg_deal_value
FROM sales_teams st
LEFT JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
WHERE sp.deal_stage = 'Won' 
    AND sp.product = 'GTX Plus Pro'
GROUP BY st.regional_office
ORDER BY units_sold DESC;

-- ================================================================================
-- SECTION 3: PRODUCT PERFORMANCE ANALYSIS
-- ================================================================================

-- Query 3.1: Product Win Rate Analysis
-- Purpose: Compare success rates across product portfolio
-- Business Impact: Product positioning and portfolio optimization insights
SELECT 
    product,
    COUNT(*) AS total_opportunities,
    SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) AS won_deals,
    ROUND(AVG(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) * 100, 2) AS win_rate_percent,
    SUM(CASE WHEN deal_stage = 'Won' THEN close_value ELSE 0 END) AS total_revenue
FROM sales_pipeline
WHERE product IS NOT NULL
GROUP BY product
ORDER BY win_rate_percent DESC;

-- Query 3.2: March Sales Performance Analysis
-- Purpose: Analyze March performance by both revenue and unit volume
-- Business Impact: Monthly performance tracking and seasonal analysis
SELECT 
    product,
    COUNT(*) AS units_sold,
    SUM(close_value) AS total_revenue,
    ROUND(AVG(close_value), 2) AS avg_deal_value,
    RANK() OVER (ORDER BY SUM(close_value) DESC) AS revenue_rank,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS volume_rank
FROM sales_pipeline
WHERE MONTH(close_date) = 3 
    AND deal_stage = 'Won'
    AND close_date IS NOT NULL
GROUP BY product 
ORDER BY total_revenue DESC;

-- Query 3.3: Pricing Analysis - Sales Price vs Close Value
-- Purpose: Analyze discount patterns and pricing strategy effectiveness
-- Business Impact: Pricing optimization and margin analysis
SELECT 
    sp.product,
    COUNT(*) AS won_deals,
    ROUND(AVG(p.sales_price), 2) AS avg_list_price,
    ROUND(AVG(sp.close_value), 2) AS avg_close_value,
    ROUND(AVG(p.sales_price - sp.close_value), 2) AS avg_discount_amount,
    ROUND(AVG(sp.close_value / p.sales_price) * 100, 2) AS avg_price_realization_percent
FROM sales_pipeline sp
LEFT JOIN products p USING (product)
WHERE sp.deal_stage = 'Won'
    AND p.sales_price IS NOT NULL
    AND sp.close_value IS NOT NULL
GROUP BY sp.product
ORDER BY avg_discount_amount DESC;

-- Query 3.4: Product Series Revenue Analysis
-- Purpose: Evaluate performance at product line level
SELECT 
    p.series,
    COUNT(sp.opportunity_id) AS total_opportunities,
    SUM(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END) AS won_deals,
    SUM(CASE WHEN sp.deal_stage = 'Won' THEN sp.close_value ELSE 0 END) AS total_revenue,
    ROUND(AVG(CASE WHEN sp.deal_stage = 'Won' THEN sp.close_value END), 2) AS avg_won_deal_value
FROM products p
LEFT JOIN sales_pipeline sp USING (product)
WHERE sp.opportunity_id IS NOT NULL
GROUP BY p.series
ORDER BY total_revenue DESC;

-- ================================================================================
-- SECTION 4: ACCOUNT ANALYSIS
-- ================================================================================

-- Query 4.1: Office Location Revenue Analysis
-- Purpose: Identify underperforming locations for strategic review
SELECT 
    office_location,
    COUNT(*) AS account_count,
    SUM(revenue) AS total_revenue,
    ROUND(AVG(revenue), 2) AS avg_revenue_per_account
FROM accounts 
WHERE office_location IS NOT NULL
GROUP BY office_location
ORDER BY total_revenue ASC;

-- Query 4.2: Company Age Analysis
-- Purpose: Analyze customer base maturity and identify business vintage range
SELECT 
    MAX(year_established) - MIN(year_established) AS year_span,
    MIN(year_established) AS oldest_company_year,
    MAX(year_established) AS newest_company_year,
    COUNT(*) AS total_companies,
    ROUND(AVG(2024 - year_established), 1) AS avg_company_age
FROM accounts
WHERE year_established IS NOT NULL;

-- Query 4.3: Oldest and Newest Companies Identification
SELECT 
    account,
    year_established,
    office_location,
    CASE 
        WHEN year_established = (SELECT MIN(year_established) FROM accounts) THEN 'Oldest Company'
        WHEN year_established = (SELECT MAX(year_established) FROM accounts) THEN 'Newest Company'
    END AS company_category
FROM accounts
WHERE year_established IN (
    (SELECT MIN(year_established) FROM accounts),
    (SELECT MAX(year_established) FROM accounts)
)
ORDER BY year_established;

-- Query 4.4: Top Revenue Generating Accounts
-- Purpose: Identify key accounts for relationship management focus
SELECT 
    account,
    office_location,
    revenue,
    year_established,
    CASE WHEN subsidiary_of != '' THEN subsidiary_of ELSE 'Independent' END AS parent_company,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM accounts 
WHERE revenue IS NOT NULL
ORDER BY revenue DESC
LIMIT 10;

-- Query 4.5: Subsidiary Performance Analysis - Lost Opportunities
-- Purpose: Analyze subsidiary companies with high opportunity loss rates
SELECT 
    a.account,
    a.subsidiary_of AS parent_company,
    a.office_location,
    COUNT(sp.opportunity_id) AS lost_opportunities,
    SUM(sp.close_value) AS potential_lost_revenue
FROM accounts a 
LEFT JOIN sales_pipeline sp ON a.account = sp.account
WHERE a.subsidiary_of IS NOT NULL 
    AND a.subsidiary_of != '' 
    AND sp.deal_stage = 'Lost'
GROUP BY a.account, a.subsidiary_of, a.office_location
HAVING COUNT(sp.opportunity_id) > 0
ORDER BY lost_opportunities DESC;

-- Query 4.6: Parent Company Consolidated Revenue Analysis
-- Purpose: Group subsidiaries with parent companies for true revenue attribution
-- Business Impact: Strategic account management and relationship mapping
WITH company_hierarchy AS (
    SELECT 
        account, 
        CASE 
            WHEN subsidiary_of IS NULL OR subsidiary_of = '' THEN account 
            ELSE subsidiary_of 
        END AS parent_company
    FROM accounts
),
consolidated_revenue AS (
    SELECT 
        sp.account,
        sp.close_value
    FROM sales_pipeline sp
    WHERE sp.deal_stage = 'Won'
        AND sp.close_value IS NOT NULL
)
SELECT 
    ch.parent_company,
    COUNT(DISTINCT ch.account) AS total_entities,
    COUNT(cr.account) AS won_deals,
    SUM(cr.close_value) AS total_consolidated_revenue,
    ROUND(AVG(cr.close_value), 2) AS avg_deal_value
FROM company_hierarchy ch
LEFT JOIN consolidated_revenue cr ON cr.account = ch.account
WHERE cr.close_value IS NOT NULL
GROUP BY ch.parent_company
HAVING SUM(cr.close_value) > 0
ORDER BY total_consolidated_revenue DESC
LIMIT 15;

-- ================================================================================
-- END OF ANALYSIS
-- ================================================================================