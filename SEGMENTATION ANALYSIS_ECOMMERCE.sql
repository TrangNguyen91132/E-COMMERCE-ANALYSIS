-- DASHBOARD 2 IN TABLEAU

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



