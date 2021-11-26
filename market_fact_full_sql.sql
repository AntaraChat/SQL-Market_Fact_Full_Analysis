USE market_star_schema;

-- Rank all the sales based on the order id in the descending order , to analyse the highest sales data.
SELECT customer_name,
	   ord_id,
       ROUND(sales) as rounded_sales,
       RANK() OVER (ORDER BY sales DESC) AS sales_rank
FROM market_fact_full as m
INNER JOIN cust_dimen as c
ON c.cust_id = m.cust_id;
-- WHERE customer_name = 'RICK WILSON';

-- Top10 sales order from customer: Filter the above result and get the top10 results
WITH rank_info as
(
SELECT customer_name,
	   ord_id,
       ROUND(sales) as rounded_sales,
       RANK() OVER (ORDER BY sales DESC) AS sales_rank
FROM market_fact_full as m
INNER JOIN cust_dimen as c
ON c.cust_id = m.cust_id)
SELECT * FROM rank_info
WHERE sales_rank <=10;

-- SELECT quantityinstock,
--        RANK() OVER(ORDER BY quantityinstock DESC) AS rank_stock
-- FROM products;

-- To get the discounts offered to a customer and rank the discounts given accodingly
SELECT customer_name,
       ord_id,
	   discount,
       RANK() OVER(ORDER BY Discount DESC) AS rank_,
       dense_rank() OVER(ORDER BY discount DESC) AS dense_rank_,
       ROW_NUMBER() OVER(ORDER BY discount DESC) AS row_number_
FROM market_fact_full as m
INNER JOIN cust_dimen as c
ON c.cust_id = m.cust_id;
-- named window application
-- In order to avoid the repetition of the query: ORDER BY discount DESC, we'll use a named window
 SELECT customer_name,
       ord_id,
	   discount,
       RANK() OVER w AS rank_,
       dense_rank() OVER w AS dense_rank_,
       ROW_NUMBER() OVER w AS row_number_
FROM market_fact_full as m
INNER JOIN cust_dimen as c
ON c.cust_id = m.cust_id
WINDOW w AS (order by discount DESC);

-- Number of orders each customer has placed
SELECT Customer_name,COUNT(DISTINCT ord_id) as Total_orders,
       RANK() OVER(ORDER BY COUNT(DISTINCT ord_id) DESC) as count_rank,
       DENSE_RANK() OVER(ORDER BY COUNT(DISTINCT ord_id) DESC) AS count_dense_rank,
       ROW_NUMBER() OVER(ORDER BY COUNT(DISTINCT ord_id) DESC) AS count_row
FROM market_fact_full as m
INNER JOIN cust_dimen as c
ON m.cust_id = c.cust_id
GROUP BY customer_name;

-- Rank the various shipment modes - use of partition with window functions
WITH shipment_summary AS
(
SELECT ship_mode,COUNT(*) AS shipments,MONTH(ship_date) AS shipping_month
FROM shipping_dimen
GROUP BY ship_mode,shipping_month
)
SELECT Ship_mode,shipping_month,shipments,
       RANK() OVER(PARTITION BY ship_mode ORDER BY shipments DESC) AS shipping_rank,
       DENSE_RANK() OVER(PARTITION BY ship_mode ORDER BY shipments DESC) AS shipping_dense_rank,
       ROW_NUMBER() OVER(PARTITION BY ship_mode ORDER BY shipments DESC) AS shipping_rank
FROM shipment_summary;

-- Doing the same thing using a groupby
WITH shipment_summary AS
(
SELECT ship_mode,COUNT(*) AS shipments,MONTH(ship_date) AS shipping_month
FROM shipping_dimen
GROUP BY ship_mode,shipping_month
)
SELECT Ship_mode,shipping_month,shipments
FROM shipment_summary
GROUP BY ship_mode,shipping_month 
ORDER BY Ship_mode,shipments DESC;

-- getting the total count of shipments for each months(use of partition and over clause)
SELECT Ship_mode,MONTH(ship_date) as month,
COUNT(ship_id) OVER (PARTITION BY MONTH(ship_date) ORDER BY ship_mode) AS Monthwise_shipping_count
FROM shipping_dimen;
-- Frames example:
WITH Daily_shipping_summary AS
(
SELECT ship_date,SUM(shipping_cost) AS daily_total
FROM shipping_dimen as s
INNER JOIN market_fact_full as m
ON s.ship_id = m.ship_id
GROUP BY ship_date)
SELECT *,
       SUM(daily_total) OVER w1 AS Running_total,
       AVG(daily_total) OVER w2 AS Moving_avg
FROM Daily_shipping_summary
WINDOW w1 AS(ORDER BY ship_date ROWS UNBOUNDED PRECEDING), -- beginning till the particular row in backward manner
w2 AS(ORDER BY ship_date ROWS 6 PRECEDING); -- moving_avg


-- For the case w2 , it keeps updating the avg for evry row until the 7th row, 
-- from the 8th row onwards it takes the avg 

WITH Daily_shipping_summary AS
(
SELECT ship_date,SUM(shipping_cost) AS daily_total
FROM shipping_dimen as s
INNER JOIN market_fact_full as m
ON s.ship_id = m.ship_id
GROUP BY ship_date)
SELECT *,
       SUM(daily_total) OVER w1 AS Running_total,
       AVG(daily_total) OVER w2 AS Moving_avg
FROM Daily_shipping_summary
WINDOW w1 AS(ORDER BY ship_date ROWS UNBOUNDED PRECEDING), -- beginning till the particular row in backward manner
w2 AS(ORDER BY  ship_date DESC ROWS BETWEEN 1 PRECEDING AND UNBOUNDED FOLLOWING); -- moving_avg

-- Lead Lag example
WITH cust_summary AS
(
SELECT c.customer_name,m.ord_id,o.order_date
FROM cust_dimen as c
RIGHT JOIN
market_fact_full as m
using(cust_id)
LEFT JOIN
orders_dimen as o
using(ord_id)
WHERE customer_name = 'AARON BERGMAN'
GROUP BY c.customer_name,m.ord_id,o.order_date
),
next_date_summary AS
(
SELECT *,LEAD(order_date,1) OVER(ORDER BY Order_date,ord_id) AS next_ord_date
FROM cust_summary
ORDER BY customer_name,order_date,ord_id)
SELECT *,DATEDIFF(next_ord_date,order_date) as Days_diff
FROM next_date_summary;
-- Lag
WITH cust_summary AS
(
SELECT c.customer_name,m.ord_id,o.order_date
FROM cust_dimen as c
RIGHT JOIN
market_fact_full as m
using(cust_id)
LEFT JOIN
orders_dimen as o
using(ord_id)
WHERE customer_name = 'AARON BERGMAN'
GROUP BY c.customer_name,m.ord_id,o.order_date
),
previous_date_summary AS
(
SELECT *,LAG(order_date,1) OVER(ORDER BY Order_date,ord_id) AS previous_ord_date
FROM cust_summary
ORDER BY customer_name,order_date,ord_id)
SELECT *,DATEDIFF(order_date,previous_ord_date) as Days_diff
FROM previous_date_summary;

-- Use of cases: Categorising the profit into range
-- profit < -500  ---> Huge loss
-- profit -500 to 0   ----> bearable loss
-- profit 0 to 500 ----> decent profit
-- profit >500 ----> great profit
SELECT market_fact_id,profit, 
CASE 
    WHEN profit < (-500) THEN 'Huge Loss'
    WHEN profit BETWEEN -500 AND 0 THEN 'Bearable loss'
    WHEN profit BETWEEN 0 AND 500 THEN 'Decent Profit'
    WHEN profit > 500 THEN 'Great Profit'
    ELSE 'Not in the range'
    END AS Profit_category
FROM market_fact_full
ORDER BY profit ASC;

-- Complex Case statements
-- Classify the customers on the following criteria based on the sales they do:
-- Top 10% of custmers as Gold
-- Next 40% of custmers as Silver
-- Rest 50% of custmers as Bronze
WITH cust_summary AS
(
SELECT m.Cust_id,customer_name,
       ROUND(SUM(Sales)) as Total_Sales,
       PERCENT_RANK() OVER(ORDER BY ROUND(SUM(Sales)) DESC) AS Perc_Rank
FROM market_fact_full as m
LEFT JOIN
cust_dimen as c
using(cust_id)
GROUP BY c.cust_id
)
SELECT *,
CASE WHEN perc_rank < 0.1 THEN 'Gold'
     WHEN perc_rank BETWEEN 0.11 AND 0.4 THEN 'Silver'
     WHEN perc_rank > 0.41 THEN 'Bronze'
     ELSE 'Not in range'
     END AS Cust_Category
FROM Cust_summary;

-- User Defined functions

DELIMITER $$
CREATE FUNCTION profittype_(profit int)
RETURNS VARCHAR(30) DETERMINISTIC

BEGIN
DECLARE message VARCHAR(30);
IF profit < -500 THEN
SET message = 'Huge Loss';
ELSEIF profit BETWEEN -500  AND 0 THEN
SET message = 'Bearable';
ELSEIF profit BETWEEN 0 AND 500 THEN
SET message = 'Decent Profit';
ELSE 
   SET message='Huge Profit';
END IF;
RETURN message;
END;
$$
DELIMITER ;    -- Changing the delimiter back to semi-colon from $
SELECT profittype_(-20) as Function_output;
-- WITHOUT DETERMINISTIC KEYWORD
DELIMITER $$
CREATE FUNCTION profittype2(profit int)
RETURNS VARCHAR(30) DETERMINISTIC

BEGIN
DECLARE message VARCHAR(30);
IF profit < -500 THEN
SET message = 'Huge Loss';
ELSEIF profit BETWEEN -500  AND 0 THEN
SET message = 'Bearable';
ELSEIF profit BETWEEN 0 AND 500 THEN
SET message = 'Decent Profit';
ELSE 
   SET message='Huge Profit';
END IF;
RETURN message;
END;
$$
DELIMITER ;    -- Changing the delimiter back to semi-colon from $
SELECT profittype2(-20) as Function_output;

-- Stored Procedures
DELIMITER $$
CREATE PROCEDURE get_sales_customers (sales_input int)
BEGIN
     SELECT DISTINCT cust_id,
                      ROUND(sales) as sales_amount
	FROM market_fact_full
    WHERE ROUND(sales) > sales_input
    ORDER BY sales;
END $$
DELIMITER ;
CALL get_sales_customers(500);
DROP PROCEDURE get_sales_customers;

-- cursors
-- Declare @Ord_id int

-- Declare the cursor using the declare keyword
-- Declare ProfitCursor CURSOR FOR 
-- Select Profit from market_fact_full

-- Open statement, executes the SELECT statment
-- and populates the result set
-- Open ProfitCursor

-- Fetch the row from the result set into the variable
-- Fetch Next from ProfitCursor into @Ord_id

-- If the result set still has rows, @@FETCH_STATUS will be ZERO
-- While(@@FETCH_STATUS = 0)
-- Begin
--  Declare @ProductName nvarchar(50)
--  Select @ProductName = Name from tblProducts where Id = @ProductId
--  
--  if(@ProductName = 'Product - 55')
--  Begin
--   Update tblProductSales set UnitPrice = 55 where ProductId = @ProductId
--  End
--  else if(@ProductName = 'Product - 65')
--  Begin
--   Update tblProductSales set UnitPrice = 65 where ProductId = @ProductId
--  End
--  else if(@ProductName like 'Product - 100%')
--  Begin
--   Update tblProductSales set UnitPrice = 1000 where ProductId = @ProductId
--  End
--  
--  Fetch Next from ProductIdCursor into @ProductId 
-- End

-- Release the row set
-- CLOSE ProductIdCursor
-- Deallocate, the resources associated with the cursor
-- DEALLOCATE ProductIdCursor ;


-- Index Demo
-- Creating a table for the demo
USE market_star_schema;
CREATE TABLE market_fact_temp AS
SELECT *
FROM market_fact_full;

CREATE INDEX filter_index ON market_fact_temp (cust_id,ship_id,prod_id);

-- Dropping the index
ALTER TABLE market_fact_temp DROP INDEX filter_index;
SELECT * FROM filter_index;

-- QUERY OPTIMIZATION
-- QUERY to display top10 customers and their names
-- This is an example of a badly written query
SELECT ord_id,
       customer_name
FROM
(
SELECT m.*,c.customer_name,
       RANK() OVER(ORDER BY sales DESC ) AS sales_rank,
       DENSE_RANK() OVER(ORDER BY sales DESC ) AS sales_dense_rank,
       ROW_NUMBER() OVER(ORDER BY sales DESC ) AS row_num
FROM
market_fact_full as m
LEFT JOIN
cust_dimen as c
ON m.cust_id = c.cust_id
ORDER BY sales DESC
) AS a
LIMIT 10;

-- Optimising the above code: 
-- Note: Any kind of filters to be applied, we should do it as early as possible, for faster exec.
SELECT ord_id,
       customer_name
FROM
(
SELECT ord_id, c.customer_name, -- m.* -- we only need the ord_id column from market_fact_full table, hence removing it
       -- RANK() OVER(ORDER BY sales DESC ) AS sales_rank,
--        DENSE_RANK() OVER(ORDER BY sales DESC ) AS sales_dense_rank,
-- Rank() and dense_rank() were emoved as here the ask is to get the top 10 customers, 
-- so a row_number() would be the best choice.
       ROW_NUMBER() OVER(ORDER BY sales DESC ) AS sales_row_num
FROM
market_fact_full as m
INNER JOIN       -- Instead of left join, inner join will be more apt, as here we need only the customer name.
cust_dimen as c
ON m.cust_id = c.cust_id
-- ORDER BY sales DESC  -- Removing order by as it is the last query to be executed in the seq
) AS a
WHERE sales_row_num <= 10;
-- LIMIT 10 ; -- Removing limit, as the excution precedence is last and is time consuming










