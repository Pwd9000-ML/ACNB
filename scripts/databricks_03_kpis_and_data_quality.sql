-- Purpose: Produce business KPIs and perform lightweight data quality checks.
-- Usage: Replace fact_orders with your source table if names differ.

USE CATALOG main;
USE analytics;

-- Example expected fact table columns:
-- order_id, customer_id, order_ts, order_amount, order_status

-- 1) Daily KPI summary (last 30 days).
WITH daily AS (
  SELECT
    DATE(order_ts) AS order_date,
    COUNT(*) AS orders,
    COUNT(DISTINCT customer_id) AS active_customers,
    SUM(order_amount) AS revenue,
    AVG(order_amount) AS avg_order_value
  FROM fact_orders
  WHERE order_ts >= date_sub(current_date(), 30)
    AND order_status = 'COMPLETED'
  GROUP BY DATE(order_ts)
)
SELECT
  order_date,
  orders,
  active_customers,
  ROUND(revenue, 2) AS revenue,
  ROUND(avg_order_value, 2) AS avg_order_value,
  ROUND(
    (revenue - LAG(revenue) OVER (ORDER BY order_date))
    / NULLIF(LAG(revenue) OVER (ORDER BY order_date), 0) * 100,
    2
  ) AS revenue_growth_pct_day_over_day
FROM daily
ORDER BY order_date DESC;

-- 2) Data quality checks.
SELECT 'null_order_id' AS check_name, COUNT(*) AS issue_count
FROM fact_orders
WHERE order_id IS NULL
UNION ALL
SELECT 'null_customer_id', COUNT(*)
FROM fact_orders
WHERE customer_id IS NULL
UNION ALL
SELECT 'negative_order_amount', COUNT(*)
FROM fact_orders
WHERE order_amount < 0
UNION ALL
SELECT 'duplicate_order_id', COUNT(*)
FROM (
  SELECT order_id
  FROM fact_orders
  GROUP BY order_id
  HAVING COUNT(*) > 1
) d;
