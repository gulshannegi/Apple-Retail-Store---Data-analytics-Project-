-- =========================================================
**IMPROVING QUERY PERFORMANCE AND OPTIMIZATION**
-- =========================================================

EXPLAIN ANALYZE 
SELECT * 
FROM sales 
WHERE product_id = 'P-44';

-- BEFORE CREATING INDEX
-- Planning time =  0.154 ms
-- Execution time = 271.423 ms

CREATE INDEX sales_product_id ON sales(product_id);

-- AFTER CREATING INDEX
-- Planning time = 0.135 ms 
-- Execution time = 68.379 ms

EXPLAIN ANALYZE
SELECT * 
FROM sales
WHERE store_id = 'ST-30';

-- BEFORE CREATING INDEX
-- Planning Time: 0.112 ms
-- Execution Time: 291.858 ms

CREATE INDEX sales_store_id ON sales(store_id); 

-- AFTER CREATING INDEX 
-- Planning Time: 0.146 ms
-- Execution Time: 9.687 ms


-- =========================================================
 **BUSINESS PROBLEMS**
-- =========================================================

-- 1. For each store, identify the best-selling day based on highest quantity sold.
SELECT store_id, day_name, totalquant 
FROM (
    SELECT store_id,
           TO_CHAR(sale_date,'Day') AS day_name,
           SUM(quantity) AS totalquant,
           RANK() OVER (PARTITION BY store_id ORDER BY SUM(quantity) DESC) AS rank
    FROM sales
    GROUP BY sale_date, store_id
) AS tbl1
WHERE rank = 1 
ORDER BY totalquant DESC;

-- 2. Identify the least selling product in each country for each year based on total units sold.
WITH product_rank AS (
    SELECT st.country,
           EXTRACT(YEAR FROM sl.sale_date) AS sale_year,
           p.product_name, 
           SUM(sl.quantity) AS total_units,
           RANK() OVER (
               PARTITION BY st.country, EXTRACT(YEAR FROM sl.sale_date) 
               ORDER BY SUM(sl.quantity) ASC
           ) AS ranking
    FROM stores st
    JOIN sales sl ON sl.store_id = st.store_id
    JOIN products p ON p.product_id = sl.product_id
    GROUP BY st.country, EXTRACT(YEAR FROM sl.sale_date), p.product_name
)
SELECT *
FROM product_rank
WHERE ranking = 1;

-- 3. Calculate how many warranty claims were filed within 180 days of a product sale.
SELECT COUNT(*)
FROM warranty w
LEFT JOIN sales s ON w.sale_id = s.sale_id 
WHERE w.claim_date <= sale_date + INTERVAL '180 days';

-- 4. Determine how many warranty claims were filed for products launched in the last two years.
SELECT p.product_name, COUNT(w.claim_id)
FROM warranty w 
JOIN sales s ON w.sale_id = s.sale_id
JOIN products p ON s.product_id = p.product_id  
GROUP BY 1, p.launch_date
HAVING p.launch_date >= (
    SELECT MAX(p.launch_date) - INTERVAL '2 years' 
    FROM products 
    LIMIT 1
);

-- 5. List the months in the last three years where sales exceeded 20,000 units in the USA.
SELECT TO_CHAR(sale_date, 'MM-YYYY') AS month,
       SUM(quantity) AS total_sales 
FROM sales 
JOIN stores ON stores.store_id = sales.store_id 
WHERE country = 'United States' 
  AND sale_date >= (SELECT MAX(sale_date) - INTERVAL '3 years' FROM sales)
GROUP BY 1
HAVING SUM(quantity) > 20000
ORDER BY 1;

-- 6. Identify the product category with the most warranty claims filed in the last two years.
SELECT category_name, COUNT(claim_id) 
FROM warranty w
JOIN sales s ON s.sale_id = w.sale_id
JOIN products p ON p.product_id = s.product_id
JOIN category c ON c.category_id = p.category_id 
WHERE claim_date >= (
    SELECT MAX(claim_date) - INTERVAL '2 years' 
    FROM warranty
)
GROUP BY category_name
ORDER BY 2 DESC;


-- =========================================================
-- ADVANCED COMPLEXITY QUERIES
-- =========================================================

-- 1. Determine the percentage chance of receiving warranty claims after each purchase for each country.
SELECT country, units_sold, total_claims, 
       ROUND(COALESCE(total_claims::NUMERIC / units_sold::NUMERIC * 100, 0), 2)::TEXT || '%' AS claim_chances
FROM (
    SELECT st.country, 
           SUM(sl.quantity) AS units_sold, 
           COUNT(w.claim_id) AS total_claims
    FROM sales sl  
    JOIN stores st ON st.store_id = sl.store_id
    LEFT JOIN warranty w ON sl.sale_id = w.sale_id
    GROUP BY st.country
) AS tb1;

-- 2. Analyze the year-by-year growth ratio for each store.
WITH yearly_sales AS (
    SELECT sl.store_id, st.store_name,
           EXTRACT(YEAR FROM sale_date) AS year,
           SUM(sl.quantity * p.price) AS total_sales
    FROM sales sl 
    JOIN products p ON p.product_id = sl.product_id  
    JOIN stores st ON st.store_id = sl.store_id 
    GROUP BY 1,2,3
    ORDER BY 2,3 ASC
), growth_ratio AS (
    SELECT store_name, year, 
           total_sales AS current_year_sales, 
           LAG(total_sales, 1) OVER (PARTITION BY store_name ORDER BY year) AS lastyear_sales
    FROM yearly_sales
)
SELECT store_name,
       lastyear_sales, 
       current_year_sales,
       ROUND(
           (current_year_sales - lastyear_sales)::NUMERIC / lastyear_sales::NUMERIC * 100, 2
       )::TEXT || '%' AS yoy_growth
FROM growth_ratio
WHERE lastyear_sales IS NOT NULL;

-- 3. Calculate the correlation between product price and warranty claims, segmented by price range.
SELECT CASE 
           WHEN price < 1000 THEN 'Lower Range' 
           WHEN price BETWEEN 1000 AND 1800 THEN 'Mid Range' 
           ELSE 'High Range' 
       END AS price_range, 
       COUNT(w.claim_id) AS total_claims
FROM warranty w 
JOIN sales s ON s.sale_id = w.sale_id 
JOIN products p ON p.product_id = s.product_id 
GROUP BY price_range;

-- 4. Identify the store with the highest percentage of "Rejected" claims relative to total claims filed.
WITH total_repairs AS (
    SELECT store_id, COUNT(claim_id) AS total_cases
    FROM sales sl
    LEFT JOIN warranty w ON w.sale_id = sl.sale_id 
    GROUP BY 1
), rejected_claims AS (
    SELECT store_id, COUNT(claim_id) AS rejected_cases
    FROM sales sl
    LEFT JOIN warranty w ON w.sale_id = sl.sale_id 
    WHERE repair_status = 'Rejected'
    GROUP BY 1
)
SELECT tr.store_id, 
       store_name, 
       total_cases, 
       rejected_cases,
       ROUND(rejected_cases / total_cases::NUMERIC * 100, 2)::TEXT || '%' AS rejection_rate
FROM total_repairs tr
JOIN rejected_claims rc ON tr.store_id = rc.store_id 
JOIN stores ON stores.store_id = tr.store_id;

-- 5. Monthly running total of sales for each store over the past four years and compare trends.
WITH monthly_sales AS (
    SELECT s.store_id, store_name,
           EXTRACT(YEAR FROM sale_date) AS year,
           EXTRACT(MONTH FROM sale_date) AS month_num,
           SUM(price * quantity) AS total_revenue	
    FROM sales s
    JOIN products p ON s.product_id = p.product_id  
    JOIN stores st ON st.store_id = s.store_id 
    GROUP BY 1,2,3,4
    ORDER BY 1,2,3
)
SELECT store_name, year,
       TO_CHAR(TO_DATE(month_num::TEXT,'MM'),'Month') AS month_name,
       total_revenue,
       SUM(total_revenue) OVER (PARTITION BY store_id ORDER BY year, month_num) AS running_total,
       LAG(total_revenue) OVER (PARTITION BY store_id ORDER BY year, month_num) AS prev_year_revenue,
       ROUND(
           (total_revenue - LAG(total_revenue) OVER (PARTITION BY store_id ORDER BY year, month_num))::NUMERIC 
           * 100.0 / NULLIF(LAG(total_revenue) OVER (PARTITION BY store_id ORDER BY year, month_num), 0)::NUMERIC, 
           2
       ) AS yoy_growth_percent
FROM monthly_sales;

-- 6. Analyze product sales trends over time, segmented into key lifecycle periods.
SELECT * 
FROM (
    SELECT p.product_name,
           CASE 
               WHEN sale_date BETWEEN launch_date AND launch_date + INTERVAL '6 month' THEN '0-6 month' 
               WHEN sale_date BETWEEN launch_date + INTERVAL '6 month' AND launch_date + INTERVAL '12 month' THEN '6-12 month' 
               WHEN sale_date BETWEEN launch_date + INTERVAL '12 month' AND launch_date + INTERVAL '18 month' THEN '12-18 month'
               ELSE '18+ months'
           END AS plc,
           SUM(s.quantity) AS total_sales
    FROM sales s 
    JOIN products p ON p.product_id = s.product_id 
    GROUP BY 1,2
) AS plc_sales
ORDER BY 1,
         CASE 
             WHEN plc = '0-6 month' THEN 1
             WHEN plc = '6-12 month' THEN 2
             WHEN plc = '12-18 month' THEN 3
             ELSE 4
         END;
