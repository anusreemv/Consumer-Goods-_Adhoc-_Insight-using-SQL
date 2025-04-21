/* ********************
   Codebasics SQL Challenge
   **************** */

/* 
1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
*/
-- Fetch distinct markets where customer "Atliq Exclusive" operates in APAC
SELECT DISTINCT market 
FROM dim_customer
WHERE customer = "Atliq Exclusive" 
AND region ="APAC";


/* 
2. What is the percentage of unique product increase in 2021 vs. 2020?
   The final output contains: unique_products_2020, unique_products_2021, percentage_chg
*/

-- Calculate total unique products per year and compare 2020 with 2021


WITH cte1 AS (
SELECT 
	COUNT(DISTINCT product_code) AS unique_product_2020
FROM fact_sales_monthly
WHERE fiscal_year='2020'
),
cte2 AS(
SELECT 
	COUNT(DISTINCT product_code)  AS unique_product_2021
FROM fact_sales_monthly
WHERE fiscal_year='2021'
)
SELECT 
	unique_product_2020,
	unique_product_2021,
    ROUND((unique_product_2021-unique_product_2020)*100/unique_product_2020 ,2) AS percentage_chg
FROM cte1
JOIN cte2;

/* 
3. Provide a report with all the unique product counts for each segment and sort them in descending order.
   Output: segment, product_count
*/

-- Count unique products per segment, sorted by count descending

SELECT 
	segment,
	COUNT(DISTINCT product_code) AS product_cnt
FROM dim_product
GROUP BY segment
ORDER BY product_cnt DESC;

/* 
4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
   Output: segment, product_count_2020, product_count_2021, difference
*/

-- Compare product count per segment between 2020 and 2021
WITH cte1 AS (
SELECT 
	segment,
	COUNT(DISTINCT p.product_code) AS product_cnt_2020
FROM dim_product p
JOIN fact_sales_monthly s USING(product_code)
WHERE s.fiscal_year ='2020'
GROUP BY segment),
cte2 AS (
SELECT 
	segment,
	COUNT(DISTINCT p.product_code) AS product_cnt_2021
FROM dim_product p
JOIN fact_sales_monthly s USING(product_code)
WHERE s.fiscal_year ='2021'
GROUP BY segment)
SELECT 
	segment, product_cnt_2020, product_cnt_2021, (product_cnt_2021-product_cnt_2020) AS difference
FROM cte1 JOIN cte2 USING(segment)
ORDER BY difference DESC;


/* 
5. Get the products that have the highest and lowest manufacturing costs.
   Output: product_code, product, manufacturing_cost
*/

-- Get max and min manufacturing cost products
SELECT 
	product_code, product, manufacturing_cost 
FROM fact_manufacturing_cost
JOIN dim_product USING(product_code)
WHERE manufacturing_cost IN 
((SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost),
(SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost));

/* 
6. Generate a report with top 5 customers in India (2021) by average high pre_invoice_discount_pct.
   Output: customer_code, customer, average_discount_percentage
*/

-- Top 5 customers in India (2021) by average pre-invoice discount
SELECT 
	customer_code, customer, ROUND(AVG(pre_invoice_discount_pct)*100,2) AS average_discount_percentage 
FROM dim_customer
JOIN fact_pre_invoice_deductions USING(customer_code)
WHERE market= 'India' AND fiscal_year=2021
GROUP BY customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;

/* 
7. Get gross sales amount for customer “Atliq Exclusive” per month.
   Output: Year, Month, Gross sales Amount
*/

-- Monthly gross sales for "Atliq Exclusive"
SELECT 
	MONTH(s.date) AS month,
	s.fiscal_year AS year,
    ROUND(SUM((gross_price*sold_quantity)),2) AS gross_sales_amount 
FROM fact_sales_monthly s
JOIN fact_gross_price g
USING(product_code)
JOIN dim_customer USING(customer_code)
WHERE customer = 'Atliq Exclusive'
GROUP BY month, year;


/* 
8. In which quarter of 2020 was the highest sold quantity?
   Output: Quarter, total_sold_quantity (in M)
*/

-- Highest sold quantity quarter in 2020
SELECT 
	CASE 
		WHEN MONTH(date) IN (9,10,11) THEN "Q1"
        WHEN MONTH(date) IN (12,1,2) THEN "Q2"
        WHEN MONTH(date) IN (3,4,5) THEN "Q3"
        ELSE "Q4"
	END AS quarter,
    SUM(sold_quantity) AS total_sold_quantity
 FROM fact_sales_monthly
WHERE fiscal_year = '2020'
GROUP BY quarter
ORDER BY total_sold_quantity DESC;


/* 
9. Which channel brought the most gross sales in 2021 and its contribution percentage?
   Output: channel, gross_sales_mln, percentage
*/

-- Top-performing sales channel in 2021 with contribution %
WITH cte AS(
SELECT 
    channel,
    ROUND(SUM((gross_price*sold_quantity)/1000000),2) AS gross_sales_mln
FROM fact_sales_monthly s
JOIN fact_gross_price g
USING(product_code)
JOIN dim_customer USING(customer_code)
WHERE s.fiscal_year='2021'
GROUP BY channel)

SELECT 
	channel,
	gross_sales_mln,
    round((gross_sales_mln*100)/sum(gross_sales_mln) OVER() ,2) AS percentage
FROM cte
ORDER BY gross_sales_mln DESC;


/* 
10. Get Top 3 products in each division by total_sold_quantity in 2021.
   Output: division, product_code, product, total_sold_quantity, rank_order
*/

-- Top 3 products per division based on total sold quantity

WITH cte AS(
SELECT
	division,
    product_code,
    product,
	SUM(sold_quantity) AS total_sold_quantity,
    RANK() OVER(PARTITION BY division ORDER BY SUM(sold_quantity) DESC) AS rank_order
FROM fact_sales_monthly
JOIN dim_product
USING(product_code)
WHERE fiscal_year=2021
GROUP BY division,product_code
)
SELECT * FROM cte 
WHERE rank_order <=3;

