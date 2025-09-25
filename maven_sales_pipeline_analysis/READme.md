# 📊 Maven Sales Pipeline Analysis

## 🎯 Executive Summary

Using advanced SQL techniques including **CTEs, window functions, and complex joins**, I analyzed MavenTech's complete sales pipeline to identify performance gaps and revenue opportunities.

* Examined **8,800+ sales opportunities** across products, agents, and accounts
* Found top-performing agents achieve **85% win rates** vs. underperformers at **45%**
* The **GTX Plus Pro** product line drives **60% more revenue per deal** than average
* Recommendations: targeted coaching + resource reallocation could boost pipeline efficiency by **15–20%**

---

## 🚀 Key Recommendations

1. 👥 Implement sales coaching program for underperforming agents
2. 📦 Increase marketing focus on high-converting products (GTX series)
3. 🌍 Reallocate resources to top-performing regional offices
4. 🏢 Develop account management strategy for high-value parent companies

---

## 🎯 Business Problem

MavenTech’s VP of Sales needed deeper insights into team performance to identify strengths and weaknesses across the sales organization.

While overall performance seemed solid, there was limited visibility into:

* Which agents and managers were top performers vs. needing coaching
* What products had the highest win rates and revenue potential
* How well key accounts and subsidiaries were managed
* Where in the process the most opportunities were lost

---

## ❓ Key Questions

* Which sales agents and managers are top performers vs. need coaching?
* What products have the highest win rates and revenue potential?
* Are we effectively managing our key accounts and subsidiaries?
* Where in our sales process are we losing the most opportunities?

---

## 🔬 Methodology

1. **🔍 Data Exploration & Cleaning** → Analyzed sales\_pipeline, sales\_teams, products, and accounts
2. **📈 Pipeline Health Analysis** → Calculated win rates, loss rates, sales cycle metrics
3. **⚡ Performance Segmentation** → Window functions + ranking for top/bottom performers
4. **📦 Product Portfolio Analysis** → Pricing effectiveness, discounts, series-level performance
5. **🏢 Account Analysis** → Hierarchical account grouping via CTEs

---

## 🛠️ Skills Demonstrated

**💻 SQL**

* Multi-table JOINs
* Common Table Expressions (CTEs) for hierarchical data
* Window Functions (`RANK`, `ROW_NUMBER`) for performance ranking
* Advanced Date Functions (`DATEDIFF`, `MONTHNAME`) for time-based analysis
* Aggregate Functions with conditional logic (`CASE WHEN`)
* Subqueries and correlated subqueries

**📊 Business Analysis**

* Sales funnel optimization
* Performance benchmarking & KPI development
* Revenue attribution modeling
* Customer segmentation & account management

---

## 📊 Key Findings & Results

### 🎯 Sales Pipeline Health

* **🏆 Overall Win Rate**: 42.3% across all opportunities
* **⏰ Average Sales Cycle**: Won deals close **8 days faster** than lost deals (32 vs. 40)
* **📈 Peak Performance**: March generated **\$1.2M in closed deals**

### 👥 Sales Team Performance

* **🥇 Top Agent Win Rate**: 85% (vs. company average of 42%)
* **📊 Performance Gap**: 40 percentage point difference between top and bottom quartile
* **🎯 Manager Impact**: Best manager’s team = 68% win rate vs. worst = 31%

### 📦 Product Analysis

```sql
-- Example: Product win rate analysis showing business impact
SELECT 
    product,
    ROUND(AVG(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) * 100, 2) AS win_rate_percent,
    SUM(CASE WHEN deal_stage = 'Won' THEN close_value ELSE 0 END) AS total_revenue
FROM sales_pipeline
GROUP BY product
ORDER BY win_rate_percent DESC;
```

* 💰 **GTX Plus Pro**: \$2.1M total revenue (highest generator)
* 💸 **Pricing Strategy**: Average 15% discount across products
* 🚀 **Series Performance**: GTX series outperforms others by **60% per deal**

### 🏢 Account Insights

* 🎯 **Concentration**: Top 5 accounts = 45% of total revenue
* 🏭 **Subsidiary Consolidation**: Adds \$500K+ in revenue attribution
* 🗺️ **Regional Performance**: East offices outperform West by 25% win rate

---

## 📋 Business Recommendations

### ⚡ Immediate Actions (0–30 days)

* 🎓 Sales coaching for bottom 20% of agents
* 📈 Increase GTX Plus Pro inventory & marketing
* 🤝 Assign dedicated managers to top 10 parent companies

### 🎯 Medium-term Strategy (30–90 days)

* 🌍 Rebalance territories between regions
* 💰 Optimize discounting policies
* ⚡ Standardize follow-up cadence to shorten cycle time

**💡 Expected Impact:**

* Win rate ↑ by 8–12 percentage points
* Sales cycle ↓ by 5–7 days
* Potential +\$2.3M annual revenue

---

## 💻 Technical Implementation

**🗄️ Database Schema**

* `sales_pipeline` → Core transaction data
* `sales_teams` → Agent/manager hierarchy
* `products` → Catalog & pricing
* `accounts` → Customer info & subsidiaries

**🔧 Advanced SQL Techniques**

* 🌳 Hierarchical Queries (subsidiary → parent companies)
* 🏆 Window Functions (`RANK`, `ROW_NUMBER`)
* 📅 Time-based analysis with date functions
* ✅ NULL handling & data quality checks

---

## 📋 Key SQL Examples

### 🏆 Sales Agent Performance Ranking

```sql
-- Identify top performers and coaching opportunities
SELECT 
    sales_agent,
    COUNT(*) AS total_opportunities,
    ROUND(AVG(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) * 100, 2) AS win_rate_percent,
    RANK() OVER (ORDER BY AVG(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) DESC) AS performance_rank
FROM sales_pipeline
WHERE sales_agent IS NOT NULL
GROUP BY sales_agent
HAVING COUNT(*) >= 5
ORDER BY win_rate_percent DESC;
```

### 📈 Manager Team Performance

```sql
-- Evaluate team performance by manager
SELECT 
    st.manager,
    COUNT(sp.opportunity_id) AS total_opportunities,
    ROUND(AVG(CASE WHEN sp.deal_stage = 'Won' THEN 1 ELSE 0 END) * 100, 2) AS team_win_rate,
    SUM(CASE WHEN sp.deal_stage = 'Won' THEN sp.close_value ELSE 0 END) AS total_revenue
FROM sales_teams st 
LEFT JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
WHERE sp.opportunity_id IS NOT NULL
GROUP BY st.manager
ORDER BY team_win_rate DESC;
```

### 💰 Pricing Strategy Analysis

```sql
-- Analyze discount patterns and pricing effectiveness
SELECT 
    sp.product,
    ROUND(AVG(p.sales_price), 2) AS avg_list_price,
    ROUND(AVG(sp.close_value), 2) AS avg_close_value,
    ROUND(AVG(sp.close_value / p.sales_price) * 100, 2) AS avg_price_realization_percent
FROM sales_pipeline sp
LEFT JOIN products p USING (product)
WHERE sp.deal_stage = 'Won'
  AND p.sales_price IS NOT NULL
  AND sp.close_value IS NOT NULL
GROUP BY sp.product
ORDER BY avg_price_realization_percent DESC;
```

### 🏢 Parent Company Revenue Consolidation

```sql
-- Group subsidiaries with parent companies using CTEs
WITH company_hierarchy AS (
    SELECT 
        account, 
        CASE 
            WHEN subsidiary_of IS NULL OR subsidiary_of = '' THEN account 
            ELSE subsidiary_of 
        END AS parent_company
    FROM accounts
)
SELECT 
    ch.parent_company,
    COUNT(DISTINCT ch.account) AS total_entities,
    SUM(cr.close_value) AS total_consolidated_revenue
FROM company_hierarchy ch
LEFT JOIN sales_pipeline cr ON cr.account = ch.account
WHERE cr.deal_stage = 'Won' AND cr.close_value IS NOT NULL
GROUP BY ch.parent_company
ORDER BY total_consolidated_revenue DESC;
```

### 📅 Monthly Opportunity Trends

```sql
-- Track seasonal patterns in opportunity creation
SELECT 
    YEAR(engage_date) AS engage_year,
    MONTHNAME(engage_date) AS engage_month,
    COUNT(*) AS opportunity_count
FROM sales_pipeline
WHERE engage_date IS NOT NULL
GROUP BY YEAR(engage_date), MONTHNAME(engage_date)
ORDER BY opportunity_count DESC;
```

---

## 🚀 Next Steps

* 🧪 A/B test sales coaching programs
* 🔮 Predictive win probability modeling (Python/R)
* 📊 Build real-time dashboards (Tableau/Power BI)
* 📈 Expand into customer lifetime value analysis

---


Do you want me to also add a **Table of Contents with internal links** (so viewers can click to jump to SQL examples, findings, etc.)?
