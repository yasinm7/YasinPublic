select * from cleanedcustomerorders 

-- KEY METRICS


-- Total Revenue
SELECT ROUND(SUM(revenue), 2) AS total_revenue
FROM cleanedcustomerorders;


-- Total Profit
SELECT ROUND(SUM(profit), 2) AS total_profit
FROM cleanedcustomerorders;


-- Total Orders
SELECT COUNT(order_id) AS total_orders
FROM cleanedcustomerorders;


-- Average Order Value (AOV)
SELECT ROUND(AVG(revenue),2) AS average_order_value
FROM cleanedcustomerorders;


-- Total Quantity Sold
SELECT SUM(clean_quantity) AS total_quantity_sold
FROM cleanedcustomerorders;


-- Total COGS
SELECT ROUND(SUM(total_cogs), 2) AS total_all_cogs
FROM cleanedcustomerorders;


-- Orders By Status
SELECT clean_order_status, COUNT(*) AS orders_count
FROM cleanedcustomerorders
GROUP BY clean_order_status
ORDER BY orders_count DESC;


-- Top 5 Products By Revenue X
SELECT 
  clean_product_name,
  ROUND(SUM(revenue), 2) AS total_revenue,
  ROUND(SUM(profit), 2) AS total_profit,
  COUNT(order_id) AS total_orders,
  SUM(clean_quantity) AS total_quantity_sold
FROM cleanedcustomerorders
GROUP BY clean_product_name
ORDER BY total_revenue DESC
LIMIT 5;


-- Top 5 Customers by Revenue X
SELECT 
  clean_customer_name,
  clean_email,
  ROUND(SUM(revenue), 2) AS total_revenue,
  ROUND(SUM(profit), 2) AS total_profit,
  COUNT(order_id) AS total_orders,
  SUM(clean_quantity) AS total_quantity_sold
FROM cleanedcustomerorders
GROUP BY clean_customer_name, clean_email
ORDER BY total_revenue DESC
LIMIT 5;


-- Top 5 Countries By Revenue X
SELECT 
  clean_country,
  ROUND(SUM(revenue), 2) AS total_revenue,
  ROUND(SUM(profit), 2) AS total_profit,
  COUNT(order_id) AS total_orders,
  SUM(clean_quantity) AS total_quantity_sold
FROM cleanedcustomerorders
GROUP BY clean_country
ORDER BY total_revenue DESC
LIMIT 5;


-- Top 10 Products by Profitability
SELECT 
  clean_product_name,
  ROUND((SUM(profit) / SUM(revenue)) * 100, 2) AS profit_margin_percent,
  ROUND(SUM(profit), 2) AS total_profit,
  ROUND(SUM(revenue), 2) AS total_revenue
FROM cleanedcustomerorders
GROUP BY clean_product_name
ORDER BY profit_margin_percent DESC
LIMIT 10;


-- Profit By Product Category
SELECT 
  clean_product_category,
  ROUND(SUM(profit), 2) AS total_profit,
  ROUND(SUM(revenue), 2) AS total_revenue,
  COUNT(order_id) AS total_orders,
  SUM(clean_quantity) AS total_quantity_sold
FROM cleanedcustomerorders
GROUP BY clean_product_category
ORDER BY total_profit DESC;


-- Profit Margin % (Overall)
SELECT 
  ROUND((SUM(profit) / SUM(revenue)) * 100, 2) AS profit_margin_percent
FROM cleanedcustomerorders;


-- Profit Margin % by Product Category
SELECT 
  clean_product_category,
  ROUND((SUM(profit) / SUM(revenue)) * 100, 2) AS profit_margin_percent,
  ROUND(SUM(profit), 2) AS total_profit,
  ROUND(SUM(revenue), 2) AS total_revenue
FROM cleanedcustomerorders
GROUP BY clean_product_category
ORDER BY profit_margin_percent DESC;


-- Average Discount % by Product Category
SELECT 
  clean_product_category,
  ROUND(AVG(discount_percent), 2) AS average_discount_percent,
  COUNT(order_id) AS total_orders
FROM cleanedcustomerorders
GROUP BY clean_product_category
ORDER BY average_discount_percent DESC;


-- Revenue per Country
SELECT 
  clean_country,
  ROUND(SUM(revenue), 2) AS total_revenue,
  ROUND(SUM(profit), 2) AS total_profit,
  COUNT(order_id) AS total_orders
FROM cleanedcustomerorders
GROUP BY clean_country
ORDER BY total_revenue DESC;


-- Profit Margin % per Country
SELECT 
  clean_country,
  ROUND((SUM(profit)/SUM(revenue)) * 100, 2) AS profit_margin_percent,
  ROUND(SUM(profit), 2) AS total_profit,
  ROUND(SUM(revenue), 2) AS total_revenue
FROM cleanedcustomerorders
GROUP BY clean_country
ORDER BY profit_margin_percent DESC;


-- Average Order Value by Country
SELECT 
  clean_country,
  ROUND(AVG(revenue), 2) AS average_order_value,
  COUNT(order_id) AS total_orders
FROM cleanedcustomerorders
GROUP BY clean_country
ORDER BY average_order_value DESC;


-- Percentage of Orders Delivered, Pending, etc
SELECT 
  clean_order_status,
  COUNT(order_id) AS orders_count,
  ROUND((COUNT(order_id) * 100.0 / (SELECT COUNT(*) FROM cleanedcustomerorders)), 2) AS percent_of_total_orders
FROM cleanedcustomerorders
GROUP BY clean_order_status
ORDER BY percent_of_total_orders DESC;


-- Order Count and Revenue By Month X
SELECT 
  EXTRACT(YEAR FROM clean_order_date) AS order_year,
  EXTRACT(MONTH FROM clean_order_date) AS order_month,
  COUNT(order_id) AS total_orders,
  ROUND(SUM(revenue), 2) AS total_revenue,
  ROUND(SUM(profit), 2) AS total_profit
FROM cleanedcustomerorders
GROUP BY order_year, order_month
ORDER BY order_year, order_month;


-- Revenue & Profit per Payment Method
SELECT 
  clean_payment_method,
  ROUND(SUM(revenue), 2) AS total_revenue,
  ROUND(SUM(profit), 2) AS total_profit,
  COUNT(order_id) AS total_orders,
  ROUND(AVG(revenue), 2) AS avg_order_value
FROM cleanedcustomerorders
GROUP BY clean_payment_method
ORDER BY total_revenue DESC;


-- Sales Performance by Month
SELECT
    EXTRACT(MONTH FROM clean_order_date) AS order_month,
    ROUND(SUM(revenue), 2) AS monthly_revenue,
    ROUND(SUM(profit), 2) AS monthly_profit,
    COUNT(order_id) AS total_orders,
    SUM(clean_quantity) AS total_quantity_sold,
    ROUND(SUM(profit)/SUM(revenue) * 100, 2) AS profit_margin_percent
FROM cleanedcustomerorders
GROUP BY order_month
ORDER BY order_month;



-- Categorizing Customers Into 'VIP', 'Regular', and 'New'
WITH customer_revenue AS (
  SELECT 
    clean_customer_name,
    clean_email,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(order_id) AS total_orders
  FROM cleanedcustomerorders
  GROUP BY clean_customer_name, clean_email
)

SELECT
    clean_customer_name,
    clean_email,
    total_revenue,
    total_profit,
    total_orders,
    CASE 
        WHEN total_revenue >= 5000 THEN 'VIP'
        WHEN total_revenue <= 5000 AND total_revenue > 1500 THEN 'Regular'
        ELSE 'New'
    END AS customer_category
FROM customer_revenue
ORDER BY total_revenue DESC;




