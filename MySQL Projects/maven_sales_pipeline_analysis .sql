/* Calculate the number of sales opportunities created each month using "engage_date", and identify the month with the most opportunities
Count opportunities per month*/

-------------------------------------------

SELECT 
    YEAR(engage_date) AS engage_year,
    MONTHNAME(engage_date) AS engage_month,
    COUNT(*) AS opportunity_count
FROM sales_pipeline
GROUP BY YEAR(engage_date), MONTHNAME(engage_date)
ORDER BY opportunity_count DESC
LIMIT 1; -- for highest month

-------------------------------------------

-- Find the average time deals stayed open (from "engage_date" to "close_date"), and compare closed deals versus won deals
Average time deals stayed open

-------------------------------------------

SELECT 
    deal_stage,
    AVG(DATEDIFF(close_date, engage_date)) AS avg_days_open
FROM sales_pipeline
WHERE engage_date IS NOT NULL AND close_date IS NOT NULL
GROUP BY deal_stage
ORDER BY deal_stage DESC;

-------------------------------------------

-- Calculate the percentage of deals in each stage, and determine what share were lost

-------------------------------------------

SELECT 
	AVG(CASE
			WHEN deal_stage = 'Lost' THEN 1
            ELSE 0
		END) * 100 AS loss_rate 
FROM sales_pipeline;
-- for percentage win rate 
SELECT 
	(SELECT 100- AVG(CASE
			WHEN deal_stage = 'Lost' THEN 1
            ELSE 0
		END) * 100) AS win_rate 
FROM sales_pipeline;

-------------------------------------------

-- Compute the win rate for each product, and identify which one had the highest win rate
-- Win Rate per Product

-------------------------------------------

SELECT 
	product,
     AVG(CASE
			WHEN deal_stage = 'Won' THEN 1
            ELSE 0
		 END) * 100 AS win_rate 
FROM sales_pipeline
GROUP BY product
ORDER BY 2 DESC;

-------------------------------------------

-- Section 2 
-- Sales Agent Performance
-- Calculate the win rate for each sales agent, and find the top performer

-------------------------------------------

SELECT 
	sales_agent,
    AVG(CASE
			WHEN deal_stage = 'Won' THEN 1
            ELSE 0
		END) * 100 AS sales_agent_win_rate
FROM sales_pipeline
GROUP BY sales_agent
ORDER BY 2 DESC
-- for top performer 

-------------------------------------------
LIMIT 1;
-- Calculate the total revenue by agent, and see who generated the most
-------------------------------------------

SELECT
    sales_agent,
    SUM(close_value) AS total_revenue
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY sales_agent
ORDER BY total_revenue DESC
LIMIT 1;

-------------------------------------------
-- Calculate win rates by manager to determine which manager’s team performed best
-------------------------------------------

SELECT 
	st.manager,
    AVG(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) AS win_rate
FROM sales_teams st 
LEFT JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
GROUP BY st.manager
ORDER BY 2 DESC;
-- 
SELECT 
	st.manager,
    SUM(close_value) AS revenue
FROM sales_teams st 
LEFT JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
GROUP BY st.manager
ORDER BY 2 DESC;
-------------------------------------------

-- For the product GTX Plus Pro, find which regional office sold the most units
-------------------------------------------

SELECT
	st.regional_office,
    COUNT(*) AS  units_sold
FROM sales_teams st
LEFT JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
WHERE deal_stage = 'Won' and sp.product = 'GTX Plus Pro'
GROUP BY st.regional_office
ORDER BY 2 DESC;

-------------------------------------------
/*Objective 3
 Product analysis
Your third objective is to analyze the sales performance and quantity sold of the company's product portfolio
For March deals, identify the top product by revenue and compare it to the top by units sold
Which product was the top seller by revenue for deals that closed in March?
 Is there a difference from the winer by unit sold
Filter close_date for "March", use SUM(close_value) grouped by product, then compare with SUM(units_sold)*/
-------------------------------------------

SELECT 
	product, SUM(close_value) AS revenue,
	COUNT(*) AS units_sold
FROM sales_pipeline
WHERE MONTH(close_date) = 3 AND deal_stage = 'Won'
GROUP BY product 
ORDER BY 2 DESC;

-------------------------------------------
-- Questuion 2 Objective 3
-- What was the average difference between the sales_price and  close_value for each product in deals won?
-- Is there an issue with the data here?
-------------------------------------------

SELECT 
	sp.product,
   AVG(p.sales_price - sp.close_value) AS avg_difference,
   AVG(sp.close_value / p.sales_price) AS discount
FROM sales_pipeline sp
LEFT JOIN products p USING (product)
WHERE sp.deal_stage = 'Won'
GROUP BY 1
ORDER BY 2 DESC;

-------------------------------------------
SELECT * FROM products;
-- Question 3 Objectives 2
-- What's was the total revenue by product series?
-------------------------------------------

SELECT 
	p.series,
    SUM(sp.close_value) AS revenue
FROM products p
LEFT JOIN sales_pipeline sp USING (product)
WHERE deal_stage = 'Won'
GROUP BY p.series
ORDER BY 2 DESC;

-------------------------------------------
/*Final analysis
Objective 4
Account analysis
Your final objective is to analyze the company's accounts to get a better understanding of the team's customers
1. Which office location had the lowest revenue?*/
-------------------------------------------

SELECT 
	office_location,
    SUM(revenue) AS revenue
FROM accounts 
GROUP BY 1
ORDER BY 2
LIMIT 1;

-------------------------------------------
/*2. What is the gap, in years, between the oldest and newest company in the book of business?
What are those companies?*/
-------------------------------------------

SELECT MAX(year_established) - MIN(year_established) AS year_gap
FROM accounts;
-- max year_established
SELECT MAX(year_established)
FROM accounts;
-- ANS : 2017
-- min year_established
SELECT MIN(year_established)
FROM accounts;
-- ANS : 1979 
-- the companies are 
SELECT account, year_established
FROM accounts
WHERE year_established IN (1979, 2017);

-------------------------------------------
-- Which 5 accounts had the highest revenue
-------------------------------------------

SELECT 
	account,
    SUM(revenue) AS revenue
FROM accounts 
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-------------------------------------------
-- Which accounts that were subsidiaries had the most lost sales opportunities
-------------------------------------------

SELECT 
	a.account,
    COUNT(sp.opportunity_id) AS opportunities
FROM accounts a 
LEFT JOIN sales_pipeline sp ON a.account = sp.account
WHERE a.subsidiary_of != '' AND sp.deal_stage = 'Lost'
GROUP BY a.account 
ORDER BY 2;

-------------------------------------------
-- Join the company to thier subsidiaies. which one had the highest revenue?
-------------------------------------------
WITH company_parent AS (
SELECT 
	a.account, 
    CASE 
		WHEN subsidiary_of = '' THEN account 
		ELSE subsidiary_of 
	END AS parent_company
FROM accounts a),
won_deals AS (
SELECT 
	sp.account,
    sp.close_value
FROM sales_pipeline sp
WHERE sp.deal_stage = 'Won')

-- SELECT * FROM won_deals;
SELECT cp.parent_company, SUM(wd.close_value) AS total_revenue
FROM company_parent cp
LEFT JOIN won_deals wd ON wd.account = cp.account
GROUP BY cp.parent_company
-- HAVING total_revenue > 100000
ORDER BY total_revenue DESC

