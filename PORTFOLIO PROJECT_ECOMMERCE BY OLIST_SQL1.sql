

-- DASHBOARD 1 IN TABLEAU

--I.1 Total Revenue of 2017 & 2018? YOY Revenue change?
WITH total_current_table AS (
	SELECT FORMAT(CAST(order_purchase_timestamp AS datetime), 'yyyy') AS [year]
			, COUNT (order_id) AS total_ord_per_year
	FROM dbo.olist_orders_dataset 
	GROUP BY FORMAT(CAST(order_purchase_timestamp AS datetime), 'yyyy')
)
, diff_table AS (
	SELECT *
		, LAG(total_ord_per_year) OVER (ORDER BY [year]) AS total_ord_preyear
	FROM total_current_table
)
SELECT *
	, FORMAT((total_ord_per_year - total_ord_preyear)*1.0/ total_ord_preyear, 'p') AS pct_diff_ord
FROM diff_table 



--I.2 Total Revenue of 2017 & 2018? YOY Revenue change?
WITH total_current_table AS (
	SELECT FORMAT(CAST(ord.order_purchase_timestamp AS datetime), 'yyyy') AS [year]
		, SUM(CAST(ite.price AS decimal(13,2))) AS total_amount_per_year
	FROM dbo.olist_orders_dataset AS ord
	JOIN dbo.olist_order_items_dataset AS ite
		ON ord.order_id = ite.order_id
	GROUP BY FORMAT(CAST(ord.order_purchase_timestamp AS datetime), 'yyyy')
)
, diff_table AS (
	SELECT *
		, LAG(total_amount_per_year) OVER (ORDER BY [year]) AS total_amount_preyear
	FROM total_current_table
)
SELECT *
	, FORMAT((total_amount_per_year - total_amount_preyear)*1.0 / total_amount_preyear, 'p') AS pct_diff_amount
FROM diff_table 



--I.3 Total Order Quantity of 2017 & 2018 by month, 

SELECT FORMAT(CAST(order_purchase_timestamp AS datetime), 'yyyyMM') AS yearmonth
		, COUNT(order_id) AS total_ord
FROM dbo.olist_orders_dataset 
GROUP BY FORMAT(CAST(order_purchase_timestamp AS datetime), 'yyyyMM')
ORDER BY 1


--I.4 Total Revenue of 2017 & 2018 by month, then visualize

SELECT FORMAT(CAST(ord.order_purchase_timestamp AS datetime), 'yyyyMM') AS yearmonth
		, SUM(CAST(ite.price AS decimal(13,2))) AS total_amount	 
FROM dbo.olist_orders_dataset AS ord
JOIN dbo.olist_order_items_dataset AS ite
	ON ord.order_id = ite.order_id
GROUP BY FORMAT(CAST(ord.order_purchase_timestamp AS datetime), 'yyyyMM')
ORDER BY 1



--I.5 	Total 2017 & 2018 Order Qty by Order Status 

WITH number_status AS (
	SELECT 
		FORMAT(CAST(order_purchase_timestamp AS datetime), 'yyyy') AS [year]
		, order_status
		, COUNT (order_id) as number_status_orders
		, (SELECT COUNT (order_id) FROM dbo.olist_orders_dataset) AS total_orders
	FROM dbo.olist_orders_dataset
	GROUP BY order_status, FORMAT(CAST(order_purchase_timestamp AS datetime), 'yyyy') 
)
SELECT *
		, FORMAT (number_status_orders*1.0/total_orders, 'p') AS pct_number_status
FROM number_status
WHERE [year] != 2016 
ORDER BY 1, 3 DESC


--I.6 	Total 2017 & 2018 Revenue by Order Status 
WITH revenue_status AS (
	SELECT 
		FORMAT(CAST(order_purchase_timestamp AS datetime), 'yyyy') AS [year]
		, order_status
		, SUM(CAST(ite.price AS decimal(13,2))) AS total_amount_per_year
		, (SELECT SUM (CAST(price AS decimal(13,2))) FROM dbo.olist_order_items_dataset) AS total_revenue
	FROM dbo.olist_orders_dataset AS ord
	JOIN dbo.olist_order_items_dataset AS ite
		ON ord.order_id = ite.order_id
	GROUP BY order_status, FORMAT(CAST(order_purchase_timestamp AS datetime), 'yyyy') 
)
SELECT *
	, FORMAT (total_amount_per_year*1.0/total_revenue, 'p') AS pct_revenue
FROM revenue_status
ORDER BY 1, 3 DESC


--I.7 Total delivered Order Qty in 2017 & 2018 by Day of Week 
WITH orders_dayweek_table AS (
	SELECT 
		FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy') AS [year]
		, FORMAT(CAST(order_purchase_timestamp AS date), 'ddd') AS dayweek
		, COUNT(order_id) AS order_qty_dayweek
		, (SELECT COUNT (order_id) FROM dbo.olist_orders_dataset 
				WHERE order_status = 'delivered' AND FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy') != 2016
			) AS total_delivered_orders
	FROM dbo.olist_orders_dataset 
	WHERE order_status = 'delivered' 
		AND FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy') != 2016
	GROUP BY FORMAT(CAST(order_purchase_timestamp AS date), 'ddd')
			, FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy')
)
SELECT * 
	, FORMAT(order_qty_dayweek*1.0/total_delivered_orders, 'p') AS pct_orders_dayweek
FROM orders_dayweek_table
ORDER BY 1 DESC


--I.8 Total 2017 & 2018 Order Qty by Day of Week 

	SELECT 
		FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy') AS [year]
		, FORMAT(CAST(order_purchase_timestamp AS date), 'ddd') AS dayweek
		, SUM(CAST(price AS decimal(13,2))) AS total_revenue_dayweek
		
	FROM dbo.olist_orders_dataset AS ord
	JOIN dbo.olist_order_items_dataset AS ite
		ON ord.order_id = ite.order_id
	WHERE ord.order_status = 'delivered' 
		AND FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy') != 2016
	GROUP BY FORMAT(CAST(order_purchase_timestamp AS date), 'ddd') 
			, FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy') 
	ORDER BY 1 DESC



--I.9 TOTAL PURCHASED ORDERS AND SUCCESSFULLY DELIVERED BY TIME OF THE DAY 
		/*Morning     6:00 to 12:00
		Afternoon   12:01 to 17:00 
		Evening     17:01 to 20:00 
		Night       20:01 to 5:59 */	

WITH hour_table AS (
	SELECT order_id
		, order_purchase_timestamp
		, FORMAT(CAST(order_purchase_timestamp AS datetime2), 'HH:mm') AS [time]
	FROM dbo.olist_orders_dataset
)
, timeday_table AS (
	SELECT *
		, CASE
			WHEN [time] BETWEEN '06:00' AND '12:00' THEN 'Morning'
			WHEN [time] BETWEEN '12:01' AND '17:00' THEN 'Afternoon'
			WHEN [time] BETWEEN '17:01' AND '20:00' THEN 'Evening'
			ELSE 'Night'
		END AS timeday
	FROM hour_table
)
, pct_timeday_table AS (
	SELECT timeday
		, (SELECT COUNT (order_id) FROM hour_table) AS total_ord_delivered
		, COUNT(order_id) AS ordamount_timeday
	FROM timeday_table 
	GROUP BY timeday 
)
SELECT *
	,FORMAT(ordamount_timeday*1.0/total_ord_delivered, 'p') AS pct_timeday
FROM pct_timeday_table
ORDER BY ordamount_timeday DESC;




-- DASHBOARD 2 IN TABLEAU

--II.1 Total Order Quantity of 2018 by State (Each order has a unique customer_id)

WITH pct_cus_table AS (
SELECT FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy') AS [year]
	, customer_state
	, (SELECT COUNT(order_id) FROM dbo.olist_orders_dataset
		WHERE FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy') = 2018
	) AS total_orders -- Each order has a unique customer_id.
	, COUNT(ord.order_id) as total_orders_bystate
FROM dbo.olist_customers_dataset AS cus
JOIN dbo.olist_orders_dataset AS ord
	ON cus.customer_id = ord.customer_id
WHERE FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy') = 2018
GROUP BY customer_state
		, FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy')
)
SELECT * 
	, FORMAT(total_orders_bystate*1.0/total_orders, 'p') AS pct_cus_bystate
FROM pct_cus_table
ORDER BY 4 DESC;


----II.2 Total Revenue of 2018 by State (Each order has a unique customer_id)


SELECT FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy') AS [year]
	, customer_state
	, SUM(CAST(ite.price AS decimal(13,2))) AS revenue_bystates
	
FROM dbo.olist_customers_dataset AS cus
JOIN dbo.olist_orders_dataset AS ord
	ON cus.customer_id = ord.customer_id
JOIN dbo.olist_order_items_dataset AS ite
	ON ord.order_id = ite.order_id
WHERE FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy') = 2018
GROUP BY customer_state
		, FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy')
ORDER BY 3 DESC;


--II.3 Total Delivered Order Qty/ Revenue in 2018 by Product Category (Tree Map)


SELECT FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy') AS [year]
	, cat.product_category_name_english AS category
	, SUM(CAST(ite.price AS decimal(13,2))) AS revenue_by_category
	, COUNT(ord.order_id) AS orders_by_category 
FROM dbo.olist_products_dataset AS pro
JOIN dbo.product_category_name_translation AS cat
	ON pro.product_category_name = cat.product_category_name
JOIN dbo.olist_order_items_dataset AS ite
	ON pro.product_id = ite.product_id
JOIN dbo.olist_orders_dataset AS ord
	ON ord.order_id = ite.order_id
WHERE FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy') = 2018
	AND ord.order_status = 'delivered'
GROUP BY cat.product_category_name_english
		, FORMAT(CAST(order_purchase_timestamp AS date), 'yyyy')
ORDER BY 2 DESC;



--II.4 The growth of payment type from 2016 to 2018 
SELECT 
	FORMAT(CAST(ord.order_purchase_timestamp AS date), 'yyyy') AS [year]
	, FORMAT(CAST(ord.order_purchase_timestamp AS date), 'MM') AS [month]
	, pay.payment_type
	, COUNT(ord.order_id) AS num_trans
FROM dbo.olist_orders_dataset AS ord
JOIN dbo.olist_order_payments_dataset AS pay
	ON ord.order_id = pay.order_id
GROUP BY FORMAT(CAST(ord.order_purchase_timestamp AS date), 'yyyy')
		, FORMAT(CAST(ord.order_purchase_timestamp AS date), 'MM')
		, pay.payment_type
ORDER BY 1 DESC, 2;


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


--II.6 Query the number of orders by Review Scores 
WITH pct_review_table AS(
	SELECT review_score
		, COUNT(DISTINCT order_id) AS each_rev_num
		, (SELECT COUNT(DISTINCT order_id) FROM olist_order_reviews_dataset) AS total_review
	FROM olist_order_reviews_dataset
	GROUP BY review_score
)
SELECT *
	, FORMAT(each_rev_num *1.0/total_review, 'p') AS pct_each_rev_num
FROM pct_review_table 
ORDER BY 2 DESC




--DASHBOARD 3

--III.1 Top 5 states have the highest 5-review score orders qty 

SELECT TOP 5 cus.customer_state
	, COUNT(rev.review_score) AS num_rev_score
FROM dbo.olist_orders_dataset AS ord 
JOIN dbo.olist_customers_dataset AS cus 
	ON ord.customer_id = cus.customer_id
JOIN dbo.olist_order_reviews_dataset AS rev
	ON ord.order_id = rev.order_id
WHERE rev.review_score = 5 
GROUP BY cus.customer_state
ORDER BY 2 DESC



--III.2 Top 5 states have the highest 1-review score orders qty 

SELECT TOP 5 cus.customer_state
	, COUNT(rev.review_score) AS num_rev_score
FROM dbo.olist_orders_dataset AS ord 
JOIN dbo.olist_customers_dataset AS cus 
	ON ord.customer_id = cus.customer_id
JOIN dbo.olist_order_reviews_dataset AS rev
	ON ord.order_id = rev.order_id
WHERE rev.review_score = 1 
GROUP BY cus.customer_state
ORDER BY 2 DESC


--III.3 Top 5 states have the highest avg freight value 

SELECT TOP 5 cus.customer_state
	, AVG(CAST(ite.freight_value AS float)) AS avg_freight_value
FROM dbo.olist_order_items_dataset AS ite
JOIN dbo.olist_orders_dataset AS ord
	ON ite.order_id = ord.order_id
JOIN dbo.olist_customers_dataset AS cus
	ON ord.customer_id = cus.customer_id
GROUP BY cus.customer_state
ORDER BY 2 DESC


--III.4 Top 5 states have the lowest avg freight value 

SELECT TOP 5 cus.customer_state
	, AVG(CAST(ite.freight_value AS float)) AS avg_freight_value
FROM dbo.olist_order_items_dataset AS ite
JOIN dbo.olist_orders_dataset AS ord
	ON ite.order_id = ord.order_id
JOIN dbo.olist_customers_dataset AS cus
	ON ord.customer_id = cus.customer_id
GROUP BY cus.customer_state
ORDER BY 2 


--III.5 Top 5 states have the highest avg time of delivery 

SELECT TOP 5 cus.customer_state
	, AVG(DATEDIFF(day, ord.order_purchase_timestamp, ord.order_delivered_customer_date)) AS avg_date_diff
FROM dbo.olist_orders_dataset AS ord
JOIN dbo.olist_customers_dataset AS cus
	ON ord.customer_id = cus.customer_id
WHERE ord.order_status = 'delivered'
GROUP BY cus.customer_state
ORDER BY 2 DESC	


--III.6 Top 5 states have the lowest avg time of delivery 

SELECT TOP 5 cus.customer_state
	, AVG(DATEDIFF(day, ord.order_purchase_timestamp, ord.order_delivered_customer_date)) AS avg_date_diff
FROM dbo.olist_orders_dataset AS ord
JOIN dbo.olist_customers_dataset AS cus
	ON ord.customer_id = cus.customer_id
WHERE ord.order_status = 'delivered'
GROUP BY cus.customer_state
ORDER BY 2 


--III.7 Top 5 states have the order qty that were delivered faster than time estimation 

WITH datediff_table AS (
SELECT cus.customer_state
	, DATEDIFF(day, ord.order_purchase_timestamp, ord.order_delivered_customer_date) AS actual_datediff
	, DATEDIFF(day, order_purchase_timestamp, order_estimated_delivery_date) AS est_date_diff
FROM dbo.olist_orders_dataset AS ord
JOIN dbo.olist_customers_dataset AS cus
	ON ord.customer_id = cus.customer_id
WHERE ord.order_status = 'delivered'
)
, datediff_comment_table AS (
SELECT *
	, CASE 
		WHEN actual_datediff < est_date_diff THEN 'faster'
		WHEN actual_datediff > est_date_diff THEN 'delay'
		ELSE 'in time'
		END AS datediff_comment
FROM datediff_table
)
SELECT TOP 5 customer_state
	, datediff_comment
	, COUNT(datediff_comment) AS count_comment
FROM datediff_comment_table
WHERE datediff_comment = 'faster'
GROUP BY customer_state, datediff_comment
ORDER BY 3 DESC



--III.8 Top 5 states have the order qty that were delivered slower than time estimation 

WITH datediff_table AS (
SELECT cus.customer_state
	, DATEDIFF(day, ord.order_purchase_timestamp, ord.order_delivered_customer_date) AS actual_datediff
	, DATEDIFF(day, order_purchase_timestamp, order_estimated_delivery_date) AS est_date_diff
FROM dbo.olist_orders_dataset AS ord
JOIN dbo.olist_customers_dataset AS cus
	ON ord.customer_id = cus.customer_id
WHERE ord.order_status = 'delivered'
)
, datediff_comment_table AS (
SELECT *
	, CASE 
		WHEN actual_datediff < est_date_diff THEN 'faster'
		WHEN actual_datediff > est_date_diff THEN 'delay'
		ELSE 'in time'
		END AS datediff_comment
FROM datediff_table
)
SELECT TOP 5 customer_state
	, datediff_comment
	, COUNT(datediff_comment) AS count_comment
FROM datediff_comment_table
WHERE datediff_comment = 'delay'
GROUP BY customer_state, datediff_comment
ORDER BY 3 DESC