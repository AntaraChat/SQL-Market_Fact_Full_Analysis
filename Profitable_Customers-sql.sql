-- Top10 most profitable customers
WITH Cust_details AS 
(
SELECT customer_name,
	   Profits,
       ROW_NUMBER() OVER(ORDER BY Profits DESC) as ranks
FROM  
(    
SELECT customer_name,
	    SUM(m.Profit) as Profits 
FROM market_fact_full as m
INNER JOIN
cust_dimen as c
using(cust_id)
GROUP BY customer_name) AS a
)
SELECT customer_name,
	   Profits,
       ranks
FROM Cust_details
WHERE ranks<=10;


-- Customers without orders 
-- 'cust_id','cust_name','city','state','customer_segment'
-- A flag to indicate that there is another customer with the exact same name and city but a different customer ID.
SELECT m.Cust_id,Customer_name,city,state,customer_segment,COUNT(DISTINCT m.ord_id) as order_count
FROM cust_dimen as c
LEFT JOIN
market_fact_full as m
ON
m.cust_id = c.cust_id
GROUP BY Cust_id
-- WHERE ord_id IS NULL
HAVING order_count =1;

SELECT Cust_id,Customer_name,city,state,customer_segment
FROM cust_without_orders; 

SELECT COUNT(Cust_id) FROM cust_dimen;
SELECT COUNT(DISTINCT Cust_id) FROM market_fact_full;