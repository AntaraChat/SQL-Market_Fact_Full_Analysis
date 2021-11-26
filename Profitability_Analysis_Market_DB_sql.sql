-- Profitability Analysis
-- Solve a business problem using SQL. 
-- In the first problem, you will identify the profitable product categories in the 'market star' schema

-- Problem Statement:
-- Identify the sustainable (profitable) product categories so that the growth team can capitalise on them to increase sales.
-- 1. Profit based on Product Category
SELECT Product_Category,
       SUM(profit) as Profits
FROM market_fact_full as m
INNER JOIN prod_dimen as p
ON m.prod_id = p.prod_id
GROUP BY Product_Category
ORDER BY Profits DESC;

-- 2. Profit based on Product Subcategory
SELECT Product_Category,
       Product_Sub_Category,
       SUM(profit) as Profits
FROM market_fact_full as m
INNER JOIN prod_dimen as p
ON m.prod_id = p.prod_id
GROUP BY Product_Category,Product_Sub_Category
ORDER BY Profits DESC;
-- Checking to see if we have distinct order ids
SELECT COUNT(*) as rec_count,
       COUNT(DISTINCT ord_id) as ord_id_count,
       COUNT(DISTINCT order_number) as ord_number_count
FROM orders_dimen;
-- We see a difference in count
-- Checking for orderid with orders > 1
SELECT order_number,
	   COUNT(ord_id)
FROM orders_dimen
GROUP BY order_number
HAVING COUNT(ord_id)>1;

-- Checking the records where order_ids are > 1
SELECT *
FROM orders_dimen
WHERE order_number IN
(
SELECT order_number
FROM orders_dimen
GROUP BY order_number
HAVING COUNT(ord_id)>1
);
-- 3. Average Profit per order
SELECT Product_category,
       SUM(m.profit) as Profits,
       ROUND((SUM(Profit)/COUNT(o.order_number)),2) AS Avg_Profits
FROM prod_dimen as p
INNER JOIN
market_fact_full as m
using(prod_id)
INNER JOIN orders_dimen as o
using(ord_id)
GROUP BY p.product_category
ORDER BY p.Product_Category,
         SUM(m.profit);

-- 4. Average Profit percentage per product_category

WITH Avg_details AS
(
SELECT Product_category,
       SUM(m.profit) as Profits,
       ROUND((SUM(m.Profit)/COUNT(o.order_number)),2) AS Avg_Profits,
       ROUND((SUM(m.Sales)/COUNT(o.order_number)),2) AS Avg_Sales
FROM prod_dimen as p
INNER JOIN
market_fact_full as m
using(prod_id)
INNER JOIN orders_dimen as o
using(ord_id)
GROUP BY p.product_category
ORDER BY p.Product_Category,
         SUM(m.profit))
SELECT Product_category,
       Avg_Profits/Avg_Sales as Profit_percent
FROM Avg_details
ORDER BY Profit_percent;

-- It is observed that the average profit percentage per order for furniture products is quite low (2.27%) 
-- compared to the other product categories. 
-- Such low values of the average profit and profit percentage per order for furniture show that these 
-- products are not doing well. Their sale should ideally be stopped or the company should come up with a 
-- robust plan to deal with this issue.

         
