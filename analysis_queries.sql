-- Total Revenue
SELECT 
    ROUND(SUM(p.price * s.quantity * (1 - s.discount)), 2) AS total_revenue
FROM 
    sales s
JOIN 
    products p ON s.product_id = p.product_id;
    
    
-- Monthly Revenue
SELECT 
    DATE_FORMAT(s.sale_date, '%Y-%m') AS month,
    ROUND(SUM(p.price * s.quantity * (1 - s.discount)), 2) AS monthly_revenue
FROM 
    sales s
JOIN 
    products p ON s.product_id = p.product_id
GROUP BY 
    month
ORDER BY 
    month;
    
-- Calculate profit margin per product
-- Step1
ALTER TABLE products ADD COLUMN cost_price DECIMAL(10,2);

-- Step 2
UPDATE products SET cost_price = 
    CASE 
        WHEN product_id = 1 THEN 48000
        WHEN product_id = 2 THEN 20000
        WHEN product_id = 3 THEN 1200
        WHEN product_id = 4 THEN 6000
        WHEN product_id = 5 THEN 1000
    END;
    
-- Step 3
SELECT 
    p.product_name,
    ROUND(SUM((p.price - p.cost_price) * s.quantity * (1 - s.discount)), 2) AS total_profit
FROM 
    sales s
JOIN 
    products p ON s.product_id = p.product_id
GROUP BY 
    p.product_name
ORDER BY 
    total_profit DESC;
    
    
-- Returning VS New Customers
SELECT
    c.name,
    COUNT(DISTINCT DATE_FORMAT(s.sale_date, '%Y-%m')) AS months_active,
    COUNT(*) AS total_purchases
FROM 
    sales s
JOIN 
    customers c ON s.customer_id = c.customer_id
GROUP BY 
    s.customer_id
HAVING 
    months_active > 1;

--  Identify Low-Performing Products (Zero Sales or Low Revenue)
SELECT 
    p.product_name,
    IFNULL(SUM(s.quantity), 0) AS total_units_sold,
    IFNULL(ROUND(SUM(p.price * s.quantity * (1 - s.discount)), 2), 0) AS total_revenue
FROM 
    products p
LEFT JOIN 
    sales s ON p.product_id = s.product_id
GROUP BY 
    p.product_id
ORDER BY 
    total_revenue ASC
LIMIT 3;

-- Best-Selling Product in Each Region
SELECT 
    region,
    product_name,
    total_units
FROM (
    SELECT 
        c.region,
        p.product_name,
        SUM(s.quantity) AS total_units,
        RANK() OVER (PARTITION BY c.region ORDER BY SUM(s.quantity) DESC) AS rnk
    FROM 
        sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN products p ON s.product_id = p.product_id
    GROUP BY 
        c.region, p.product_name
) ranked
WHERE rnk = 1;

--  Average Order Value (AOV) per Month
SELECT 
    DATE_FORMAT(s.sale_date, '%Y-%m') AS month,
    ROUND(SUM(p.price * s.quantity * (1 - s.discount)) / COUNT(DISTINCT s.sale_id), 2) AS avg_order_value
FROM 
    sales s
JOIN 
    products p ON s.product_id = p.product_id
GROUP BY 
    month;

-- Region-wise Revenue Growth Comparison (Month-on-Month)
WITH monthly_revenue AS (
    SELECT 
        c.region,
        DATE_FORMAT(s.sale_date, '%Y-%m') AS month,
        SUM(p.price * s.quantity * (1 - s.discount)) AS revenue
    FROM 
        sales s
    JOIN 
        products p ON s.product_id = p.product_id
    JOIN 
        customers c ON s.customer_id = c.customer_id
    GROUP BY 
        c.region, month
)

SELECT 
    region,
    month,
    revenue,
    ROUND(revenue - LAG(revenue) OVER (PARTITION BY region ORDER BY month), 2) AS revenue_growth
FROM 
    monthly_revenue;
