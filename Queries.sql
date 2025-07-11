-- Reports and Data Analysis


-- Q1. Coffee Consumer Estimation
-- How many people in each city are estimated to consume coffee if 25% of the population drinks coffee?
-- Return: city rank, city name, and estimated coffee consumers (in lakhs).


SELECT 
    city_rank,
    city_name,
    ROUND((population * .25) / 100000 ,2)AS coffee_consumers
FROM
    city
ORDER BY 3 DESC;


-- Q2. Total Revenue in Q4 2023
-- What is the total revenue from coffee sales in each city during the last quarter (Oct–Dec) of 2023?
-- Return: city name and total sales, sorted by revenue in descending order.


SELECT 
	ci.city_name,
    SUM(s.total) AS total_revenue	
FROM sales AS s
JOIN customers AS c 
ON s.customer_id = c.customer_id
JOIN  city as ci
ON ci.city_id = c.city_id
WHERE
	Year(sale_date) = 2023
    AND
    QUARTER( sale_date) = 4
GROUP BY 1 
ORDER BY 2 DESC;


-- Q3. Total Sales Count by Product
-- How many units of each product have been sold across all cities?
-- Return: product name and total order count, sorted by highest-selling products.
SELECT
	p.product_name,
    COUNT(s.sale_id) AS total_order
FROM products AS p
LEFT JOIN 
sales AS s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- Q4. Average Sales per Customer per City
-- What is the average amount spent per customer in each city?
-- Return: city name, total revenue, customer count, and average sale per customer.

    
    SELECT 
	ci.city_name,
    SUM(s.total) AS total_revenue	,
    COUNT(DISTINCT s.customer_id) as total_cx,
    ROUND(
			SUM(s.total)/
            COUNT(DISTINCT s.customer_id)
            ,1) as avg_sale_pr_cx
FROM sales AS s
JOIN customers AS c 
ON s.customer_id = c.customer_id
JOIN  city as ci
ON ci.city_id = c.city_id
GROUP BY 1 
ORDER BY 2 DESC;

-- Q5. Population vs Coffee Consumers vs Customers
-- For each city, show total population, estimated coffee consumers (25%), and actual number of unique customers.
-- Return: city name, population, estimated consumers (in lakhs), and unique customers.

SELECT 
    ci.city_name,
    ci.population,
    ROUND((ci.population * 0.25) / 100000 ,2)AS coffee_consumers_lakhs,
    COUNT(DISTINCT c.customer_id) AS Unique_CX
    
FROM 
    city as ci
    LEFT JOIN customers as c ON
    c.city_id = ci.city_id
    
    
    GROUP BY ci.city_id,city_name, population
    ORDER BY 3 DESC;

-- Q6. Top 3 Selling Products by City
-- What are the top 3 best-selling coffee products in each city based on sales volume?
-- Return: city name, product name, total orders, and product rank per city.

SELECT * 
FROM
	(SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) AS total_orders,
		DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS ranks
	FROM sales AS s
	JOIN customers AS c 
	ON s.customer_id = c.customer_id
	JOIN  city as ci
	ON ci.city_id = c.city_id
	JOIN products as p
	ON s.product_id = p.product_id
	GROUP BY 1,2
	ORDER BY 1,3 DESC)
AS T1
WHERE ranks <= 3;
;

-- Q7. Coffee-Only Customers
-- How many unique customers in each city have only purchased coffee-related products?
-- Return: city ID, city name, and count of unique coffee-only customers.

SELECT 
	ci.city_id,
	ci.city_name,
    COUNT(DISTINCT c.customer_id) AS Unique_Coffee_customers
 FROM 
city as ci
JOIN customers as c
ON ci.city_id = c.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE s.product_id IN (1,2,3,4,5,6,7,8,9,10,12,13,14)
GROUP BY 1
ORDER BY 3 DESC
;

-- Q8. Average Sale vs Average Rent per Customer
-- For each city, calculate:
--   - average sale per customer
--   - average rent per customer
-- Compare the two to assess how much people spend on coffee vs their rent.
-- Return: city name, total customers, average sale per customer, average rent per customer.
 SELECT 
	ci.city_name,
    ci.estimated_went	,
    COUNT(DISTINCT s.customer_id) as total_cx,
    ROUND(
			SUM(s.total)/
            COUNT(DISTINCT s.customer_id)
            ,0) as avg_sale_pr_cx,
	ROUND(
				ci.estimated_rent/
				COUNT(DISTINCT s.customer_id)
                ,0) as avg_rent_pr_cx
FROM sales AS s
JOIN customers AS c 
ON s.customer_id = c.customer_id
JOIN  city as ci
ON ci.city_id = c.city_id
GROUP BY ci.city_name,ci.estimated_rent
ORDER BY 4 DESC ;

-- Q9. Monthly Sales Growth Analysis
-- Calculate the monthly sales trend for each city, including:
--   - total monthly sales
--   - previous month’s sales
--   - percentage growth or decline from the previous month
-- Return: city name, month, year, total sale, previous month sale, and growth rate.

WITH
monthly_sales
AS
(
	SELECT
		ci.city_name,
		MONTH(sale_date) as month,
		YEAR(sale_date) AS year,
		SUM(s.total) AS total_sale		
	FROM sales AS s
	JOIN customers AS c 
	ON s.customer_id = c.customer_id
	JOIN  city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1,2,3
	Order by 1,3,2
)
SELECT
	city_name,
    month,
    year,
    total_sale,
    LAG (total_sale,1) OVER (PARTITION BY city_name ORDER BY year,month) AS last_month_sale,
    
     ROUND(
        ((total_sale - LAG(total_sale, 1) OVER (PARTITION BY city_name ORDER BY year, month)) 
        / NULLIF(LAG(total_sale, 1) OVER (PARTITION BY city_name ORDER BY year, month), 0)) * 100, 
        2
    ) AS growth_ratio
    
FROM monthly_sales;

-- Q.10 Market Potential & City Comparison
-- Identify the top 3 cities with the highest total coffee sales.
-- For each city, show:
--   - total sales
--   - number of customers
--   - total estimated rent
--   - estimated number of coffee consumers
--   - average sale per customer
--   - average rent per customer
--   - sale-to-rent ratio (to assess affordability and profitability)
-- Rank the cities by total sales and return the top 3–5.


SELECT  
    ci.city_id,
    ci.city_name,
    
    -- Total revenue
    SUM(s.total) AS total_sales,
    
    -- Total customers
    COUNT(DISTINCT s.customer_id) AS total_customers,
    
    -- Total rent (from city table)
    ci.estimated_rent AS total_rent,
    
    -- Average sale per customer
    ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 0) AS avg_sale_per_customer,
    
    -- Average rent per customer (as you said: rent ÷ total customers)
    ROUND(ci.estimated_rent / COUNT(DISTINCT s.customer_id), 0) AS avg_rent_per_customer,
    
    -- Sale-to-Rent Ratio
    ROUND(
        (SUM(s.total) / COUNT(DISTINCT s.customer_id)) / 
        (ci.estimated_rent / COUNT(DISTINCT s.customer_id)), 2
    ) AS sale_to_rent_ratio,

    -- Coffee consumers estimate
    ROUND(ci.population * 0.25 / 1000000, 2) AS estimated_coffee_consumers_millions       

FROM sales AS s
JOIN customers AS c ON s.customer_id = c.customer_id
JOIN city AS ci ON ci.city_id = c.city_id

GROUP BY ci.city_id, ci.city_name, ci.estimated_rent, ci.population
ORDER BY total_sales DESC
LIMIT 5;


-- Recomendation
-- ==========================
-- City-wise Recommendations
-- ==========================

-- City 1: Pune
-- 1. Highest total revenue, indicating strong market engagement.
-- 2. Average sales per customer is among the highest, showing high individual spending.
-- 3. Average rent per customer is very low, increasing the sale-to-rent affordability ratio.
-- 4. Sale-to-rent ratio is significantly high, suggesting that customers spend much more on coffee than rent.
-- → Action: Prioritize Pune for premium product introductions or loyalty programs.

-- City 2: Delhi
-- 1. Highest estimated coffee consumers at 7.7 million, indicating vast market size.
-- 2. Total number of customers is highest (68), showing strong customer coverage.
-- 3. Average rent per customer is moderate (₹330), still under control.
-- 4. Sale-to-rent ratio is healthy, indicating balanced affordability.
-- → Action: Focus on expansion, targeted marketing, and optimizing delivery or subscriptions.

-- City 3: Jaipur
-- 1. Second-highest number of customers (69), showing wide reach.
-- 2. Lowest average rent per customer (₹156), boosting customer affordability.
-- 3. Strong average sales per customer (₹11.6k), which is competitive.
-- 4. Sale-to-rent ratio is very high, meaning customers spend much more on coffee than rent.
-- → Action: Promote bundled offers and increase store count or delivery zones in Jaipur.
