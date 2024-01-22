

-- DASHBOARD 1 - TIME SERIES ANALYSIS

--I.1 TOTAL ORDERS/REVENUE PER YEAR? YOY ORDERS/ REVENUE?

WITH total_current_table AS (
	SELECT DATEPART(year, order_purchase_timestamp) AS [year]
			, COUNT (order_id) AS total_ord_per_year
	FROM dbo.olist_orders_dataset 
	GROUP BY DATEPART(year, order_purchase_timestamp)
)
, diff_table AS (
	SELECT *
		, LAG(total_ord_per_year) OVER (ORDER BY [year]) AS total_ord_preyear
	FROM total_current_table
)
SELECT *
	, FORMAT((total_ord_per_year - total_ord_preyear)*1.0/ total_ord_preyear, 'p') AS pct_diff_ord
FROM diff_table;



WITH total_current_table AS (
	SELECT DATEPART(year, order_purchase_timestamp) AS [year]
		, SUM(CAST(ite.price AS decimal(13,2))) AS total_amount_per_year
	FROM dbo.olist_orders_dataset AS ord
	JOIN dbo.olist_order_items_dataset AS ite
		ON ord.order_id = ite.order_id
	GROUP BY DATEPART(year, order_purchase_timestamp) 
)
, diff_table AS (
	SELECT *
		, LAG(total_amount_per_year) OVER (ORDER BY [year]) AS total_amount_preyear
	FROM total_current_table
)
SELECT *
	, FORMAT((total_amount_per_year - total_amount_preyear)*1.0 / total_amount_preyear, 'p') AS pct_diff_amount
FROM diff_table;



--I.2 TOTAL ORDERS/ REVENUE OVER TIME 

SELECT FORMAT(CAST(order_purchase_timestamp AS datetime), 'yyyyMM') AS yearmonth
		, COUNT(order_id) AS total_ord
FROM dbo.olist_orders_dataset 
GROUP BY FORMAT(CAST(order_purchase_timestamp AS datetime), 'yyyyMM')
ORDER BY 1;



SELECT FORMAT(CAST(ord.order_purchase_timestamp AS datetime), 'yyyyMM') AS yearmonth
		, SUM(CAST(ite.price AS decimal(13,2))) AS total_amount	 
FROM dbo.olist_orders_dataset AS ord
JOIN dbo.olist_order_items_dataset AS ite
	ON ord.order_id = ite.order_id
GROUP BY FORMAT(CAST(ord.order_purchase_timestamp AS datetime), 'yyyyMM')
ORDER BY 1;


--I.5 TOTAL ORDERS/ REVENUE BY DAY OF MONTH

SELECT 
	DATEPART(day, order_purchase_timestamp) AS day_of_month
	, COUNT(order_id) AS orders_daymonth
FROM dbo.olist_orders_dataset 
GROUP BY DATEPART(day, order_purchase_timestamp) 
ORDER BY 1;


SELECT 
	DATEPART(day, order_purchase_timestamp) AS day_of_month
	, SUM(CAST(price AS decimal(13,2))) AS revenue_daymonth
FROM dbo.olist_orders_dataset AS ord
JOIN dbo.olist_order_items_dataset AS ite
	ON ord.order_id = ite.order_id
GROUP BY DATEPART(day, order_purchase_timestamp) 
ORDER BY 1;


--I.4 TOTAL ORDERS/REVENUE BY WEEKDAY 

WITH orders_dayweek_table AS (
	SELECT 
		FORMAT(CAST(order_purchase_timestamp AS date), 'ddd') AS dayweek
		, COUNT(order_id) AS order_qty_dayweek
		, (SELECT COUNT (order_id) FROM dbo.olist_orders_dataset) AS total_orders
	FROM dbo.olist_orders_dataset 
	GROUP BY FORMAT(CAST(order_purchase_timestamp AS date), 'ddd')
		
)
SELECT * 
	, FORMAT(order_qty_dayweek*1.0/total_orders, 'p') AS pct_orders_dayweek
FROM orders_dayweek_table
ORDER BY 4 DESC;

 

WITH revenue_dayweek_table AS (
	SELECT 
		FORMAT(CAST(order_purchase_timestamp AS date), 'ddd') AS dayweek
		, SUM(CAST(price AS decimal(13,2))) AS total_revenue_dayweek
		, (SELECT SUM(CAST(price AS decimal(13,2))) FROM dbo.olist_order_items_dataset) AS total_revenue
	FROM dbo.olist_orders_dataset AS ord
	JOIN dbo.olist_order_items_dataset AS ite
		ON ord.order_id = ite.order_id
	GROUP BY FORMAT(CAST(order_purchase_timestamp AS date), 'ddd') 
)
SELECT *
	, FORMAT(total_revenue_dayweek*1.0 / total_revenue, 'p') AS pct_revenue_dayweek
FROM revenue_dayweek_table
	ORDER BY 4 DESC;



--I.5 TOTAL ORDERS/ REVENUE BY TIME OF THE DAY 
		/*9 to 16 --> Morning/Afternoon
		16 to 18 --> Evening
		18 to 23 --> Night
		23 to 9 --> Early Morning */	

WITH hour_table AS (
	SELECT order_id
		, order_purchase_timestamp
		, DATEPART(hh, order_purchase_timestamp) AS time_hour
	FROM dbo.olist_orders_dataset
)
, timeday_table AS (
	SELECT *
		, CASE
			WHEN time_hour >= 9 AND time_hour < 16 THEN 'morning/afternoon'
			WHEN time_hour >= 16 AND time_hour < 18 THEN 'evening'
			WHEN time_hour >= 18 AND time_hour < 23 THEN 'night'
			ELSE 'early morning'
		END AS time_of_day
	FROM hour_table
)
, pct_timeday_table AS (
	SELECT time_of_day
		, (SELECT COUNT (order_id) FROM hour_table) AS total_orders
		, COUNT(order_id) AS ord_timeday
	FROM timeday_table 
	GROUP BY time_of_day
)
SELECT *
	,FORMAT(ord_timeday*1.0/total_orders, 'p') AS pct_timeday
FROM pct_timeday_table
ORDER BY ord_timeday DESC;

----------------------------------------

WITH hour_table AS (
	SELECT order_id
		, order_purchase_timestamp
		, DATEPART(hh, order_purchase_timestamp) AS time_hour
	FROM dbo.olist_orders_dataset
)
, timeday_table AS (
	SELECT ite.order_id,time_hour, ite.price
		, CASE
			WHEN time_hour >= 9 AND time_hour < 16 THEN 'morning/afternoon'
			WHEN time_hour >= 16 AND time_hour < 18 THEN 'evening'
			WHEN time_hour >= 18 AND time_hour < 23 THEN 'night'
			ELSE 'early morning'
		END AS time_of_day
	FROM hour_table
	JOIN dbo.olist_order_items_dataset AS ite
		ON hour_table.order_id = ite.order_id
)
, pct_timeday_table AS (
	SELECT time_of_day
		, SUM(CAST(price AS decimal(13,2))) AS revenue_timeday
		, (SELECT SUM(CAST(price AS decimal(13,2))) FROM dbo.olist_order_items_dataset) AS total_revenue
	FROM timeday_table
	GROUP BY time_of_day
)
SELECT *
	, FORMAT(revenue_timeday*1.0/ total_revenue, 'p') AS pct_revenue_timeday
FROM pct_timeday_table
ORDER BY 4 DESC;
	

-- DASHBOARD 2 - SEGMENTATION ANALYSIS

--II.1 TOTAL ORDERS/ REVENUE BY STATE

SELECT customer_state 
	, COUNT(DISTINCT cus.customer_id) AS customers_bystate
	, COUNT(DISTINCT sell.seller_id) AS seller_bystate 
FROM dbo.olist_customers_dataset AS cus
JOIN dbo.olist_geolocation_dataset AS geo 
	ON cus.customer_zip_code_prefix = geo.geolocation_zip_code_prefix
JOIN dbo.olist_sellers_dataset AS sell
	ON geo.geolocation_zip_code_prefix = sell.seller_zip_code_prefix
GROUP BY customer_state
ORDER BY 2 DESC;


--II.2 TOTAL ORDERS/ REVENUE BY PAYMENT TYPE 

SELECT payment_type
	, COUNT(DISTINCT order_id) AS orders_paytype
	, SUM(CAST(payment_value AS float)) AS amount_paytype
FROM dbo.olist_order_payments_dataset 
GROUP BY payment_type
ORDER BY 2 DESC;


--II.3 TOTAL ORDERS/ REVENUE BY REVIEW SCORES

WITH pct_review_table AS(
	SELECT review_score
		, COUNT(DISTINCT order_id) AS orders_review_score
		, (SELECT COUNT(DISTINCT order_id) FROM olist_order_reviews_dataset) AS total_review_orders
	FROM olist_order_reviews_dataset
	GROUP BY review_score
)
SELECT *
	, FORMAT(orders_review_score *1.0/total_review_orders, 'p') AS pct_each_rev_num
FROM pct_review_table 
ORDER BY 2 DESC


--II.4 TOTAL ORDERS/ REVENUE BY PRODUCT CATEGORY

SELECT 
	cat.product_category_name_english AS category
	, SUM(CAST(ite.price AS decimal(13,2))) AS revenue_by_category
	, COUNT(ord.order_id) AS orders_by_category 
FROM dbo.olist_products_dataset AS pro
JOIN dbo.product_category_name_translation AS cat
	ON pro.product_category_name = cat.product_category_name
JOIN dbo.olist_order_items_dataset AS ite
	ON pro.product_id = ite.product_id
JOIN dbo.olist_orders_dataset AS ord
	ON ord.order_id = ite.order_id
GROUP BY cat.product_category_name_english
ORDER BY 3 DESC;


--II.5 Count transactions by payment installments

WITH pay_install_table AS (
SELECT payment_installments
	, COUNT(order_id) AS num_trans
	, (SELECT COUNT(order_id) FROM dbo.olist_order_payments_dataset) AS total_trans
FROM dbo.olist_order_payments_dataset
GROUP BY payment_installments
)
SELECT *
	, FORMAT(num_trans *1.0/total_trans, 'p') AS pct_pay_type
FROM pay_install_table
ORDER BY 2 DESC;

SELECT  *
	--, DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date) AS actual_datediff
	--, DATEDIFF(day, order_purchase_timestamp, order_estimated_delivery_date) AS est_date_diff
FROM dbo.olist_orders_dataset
WHERE order_delivered_customer_date IS NULL


--II.5 COUNT THE NUMBER ORDERS THAT WERE DELIVERED FASTER, IN TIME, SLOWER THAN ESTIMATED TIME 

WITH datediff_table AS (
SELECT DISTINCT *
	, DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date) AS actual_datediff
	, DATEDIFF(day, order_purchase_timestamp, order_estimated_delivery_date) AS est_date_diff
FROM dbo.olist_orders_dataset
WHERE order_delivered_customer_date IS NOT NULL
)
, datediff_comment_table AS (
SELECT *
	, CASE 
		WHEN actual_datediff < est_date_diff THEN 'faster'
		WHEN actual_datediff > est_date_diff THEN 'delay'
		ELSE 'in time'
		END AS datediff_comment
FROM datediff_table
--WHERE actual_datediff >= 0 AND est_date_diff >= 0
)
SELECT datediff_comment
	, COUNT(datediff_comment) AS count_comment
FROM datediff_comment_table
GROUP BY datediff_comment
ORDER BY 2 DESC



