-- Fraud Customer Flag
-- Checking for unique customer names and city
WITH fraud_cust AS
(
SELECT cust_id,customer_name,
	   city,
       COUNT(cust_id) as cust_id_count
FROM cust_dimen
GROUP BY customer_name,city
HAVING cust_id_count>1
),
cust_more_1 AS
( 
SELECT m.Cust_id,Customer_name,city,state,customer_segment,COUNT(DISTINCT m.ord_id) as order_count
FROM cust_dimen as c
LEFT JOIN
market_fact_full as m
ON
m.cust_id = c.cust_id
GROUP BY Cust_id
HAVING order_count =1
)
SELECT c.*,
       CASE WHEN cust_id_count IS NOT NULL THEN 'Fraud' ELSE 'NORMAL' END AS Fraud_Flag
FROM cust_more_1 as c
LEFT JOIN
fraud_cust as f
ON c.cust_id = f.cust_id;
