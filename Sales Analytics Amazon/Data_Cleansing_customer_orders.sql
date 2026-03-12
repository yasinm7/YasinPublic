SELECT * FROM `project-b94826b8-87de-42c2-b5a.SQLPRACTICE.messy_orders_dataset` LIMIT 100;

  -- 1) Standardizing order_status Column

SELECT order_status,
  CASE 
   WHEN LOWER(order_status) LIKE '%deliver%' THEN 'Delivered'
   WHEN LOWER(order_status) LIKE '%return%' THEN 'Returned' 
   WHEN LOWER(order_status) LIKE '%refund%' THEN 'Refunded' 
   WHEN LOWER(order_status) LIKE '%pend%' THEN 'Pending' 
   WHEN LOWER(order_status) LIKE '%ship%' THEN 'Shipped' 
   ELSE 'Other'
  END AS clean_order_status
FROM `project-b94826b8-87de-42c2-b5a.SQLPRACTICE.messy_orders_dataset`; 

-- 2) Standardizing product_name Column

SELECT 
    UPPER(product_name) AS clean_products
FROM `project-b94826b8-87de-42c2-b5a.SQLPRACTICE.messy_orders_dataset`; 

-- 3) Cleaning Quantity Field

SELECT *,
  CASE
   WHEN LOWER(quantity) = 'three' THEN 3
   ELSE CAST(quantity AS INT64)
  END AS clean_quantity
 FROM `project-b94826b8-87de-42c2-b5a.SQLPRACTICE.messy_orders_dataset`; 

 -- 4) Cleaning customer_name Field

SELECT customer_name,
INITCAP(customer_name) AS customer_name
FROM `project-b94826b8-87de-42c2-b5a.SQLPRACTICE.messy_orders_dataset`
WHERE customer_name IS NOT NULL; 

-- 5) Removing Duplicated Orders

SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY email, product_name ORDER BY order_id) AS rn
    FROM `project-b94826b8-87de-42c2-b5a.SQLPRACTICE.messy_orders_dataset`
)
WHERE rn = 1;


-- Final Cleaned Dataset

WITH cleaned_data AS (
  SELECT 
    order_id,

    -- Clean customer name
    INITCAP(customer_name) AS clean_customer_name,

    -- Clean email
    LOWER(TRIM(email)) AS clean_email,

    -- Standardize order status
    CASE 
      WHEN LOWER(order_status) LIKE '%deliver%' THEN 'Delivered'
      WHEN LOWER(order_status) LIKE '%return%' THEN 'Returned'
      WHEN LOWER(order_status) LIKE '%refund%' THEN 'Refunded'
      WHEN LOWER(order_status) LIKE '%pend%' THEN 'Pending'
      WHEN LOWER(order_status) LIKE '%ship%' THEN 'Shipped'
      ELSE 'Other'
    END AS clean_order_status,

    -- Standardize product names
    UPPER(TRIM(product_name)) AS clean_product_name,

    -- Clean quantity
    CASE
      WHEN LOWER(CAST(quantity AS STRING)) = 'one' THEN 1
      WHEN LOWER(CAST(quantity AS STRING)) = 'two' THEN 2
      WHEN LOWER(CAST(quantity AS STRING)) = 'three' THEN 3
      ELSE SAFE_CAST(quantity AS INT64)
    END AS clean_quantity,

    -- Clean order date
    COALESCE(
      SAFE.PARSE_DATE('%Y-%m-%d', CAST(order_date AS STRING)),
      SAFE.PARSE_DATE('%d/%m/%Y', CAST(order_date AS STRING)),
      SAFE.PARSE_DATE('%m/%d/%Y', CAST(order_date AS STRING))
    ) AS clean_order_date,

    -- Clean additional columns
    SAFE_CAST(price AS INT64) AS clean_price,
    INITCAP(TRIM(product_category)) AS clean_product_category,
    INITCAP(TRIM(payment_method)) AS clean_payment_method,
    INITCAP(TRIM(country)) AS clean_country,

    cogs,
    discount_percent

  FROM `project-b94826b8-87de-42c2-b5a.SQLPRACTICE.messy_orders_dataset`
  WHERE customer_name IS NOT NULL
),

deduplicated_data AS (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY clean_email, clean_product_name
           ORDER BY order_id
         ) AS rn
  FROM cleaned_data
),

final_table AS (
  SELECT *,
         -- Total COGS
         ROUND(cogs * clean_quantity, 2) AS total_cogs,

         -- Revenue considering discount
         ROUND(clean_price * clean_quantity * (1 - COALESCE(discount_percent,0)/100), 2) AS revenue,

         -- Profit considering discount
         ROUND((clean_price * clean_quantity * (1 - COALESCE(discount_percent,0)/100) - (cogs * clean_quantity)), 2) AS profit
  FROM deduplicated_data
  WHERE rn = 1
)

SELECT *
FROM final_table;