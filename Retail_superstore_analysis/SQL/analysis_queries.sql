CREATE DATABASE superstore;
USE superstore;
CREATE TABLE orders (
    Row_ID INT,
    Order_ID VARCHAR(20),
    Order_Date DATE,
    Ship_Date DATE,
    Ship_Mode VARCHAR(50),
    Customer_ID VARCHAR(20),
    Customer_Name VARCHAR(100),
    Segment VARCHAR(50),
    Country VARCHAR(50),
    City VARCHAR(100),
    State VARCHAR(100),
    Postal_Code VARCHAR(20),
    Region VARCHAR(50),
    Product_ID VARCHAR(50),
    Category VARCHAR(50),
    Sub_Category VARCHAR(50),
    Product_Name VARCHAR(255),
    Sales DECIMAL(10,2),
    Quantity INT,
    Discount DECIMAL(5,2),
    Profit DECIMAL(10,2)
);

CREATE TABLE returns (
  Returned VARCHAR(10),
  Returned_Order_ID VARCHAR(50)
);

CREATE TABLE people (
  Person VARCHAR(100),
  Region VARCHAR(50)
);


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/superstore_orders.csv'
INTO TABLE orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Row_ID, Order_ID, @Order_Date, @Ship_Date, Ship_Mode, Customer_ID, Customer_Name, Segment,
 Country, City, State, Postal_Code, Region, Product_ID, Category, Sub_Category, Product_Name,
 @Sales, Quantity, Discount, @Profit)
SET 
Order_Date = STR_TO_DATE(@Order_Date, '%d-%m-%Y'),
Ship_Date  = STR_TO_DATE(@Ship_Date, '%d-%m-%Y'),
Sales  = CAST(REPLACE(REPLACE(@Sales, ',', ''), '$', '') AS DECIMAL(10,2)),
Profit = CAST(REPLACE(REPLACE(@Profit, ',', ''), '$', '') AS DECIMAL(10,2));

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/superstore_returns.csv'
INTO TABLE returns
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Returned, Returned_Order_ID);

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/superstore_people.csv'
INTO TABLE people
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Person, Region);


SELECT * FROM superstore.orders;
SELECT * FROM superstore.returns;
SELECT * FROM superstore.people;

--Table Joins
--1. Combine orders and returns
SELECT
  o.Order_ID,
  o.Region,
  o.Category,
  o.Sales,
  o.Profit,
  r.Returned
FROM orders o
LEFT JOIN returns r
  ON o.Order_ID = r.Returned_Order_ID;

--2. Combine orders and people
SELECT 
  o.Region,
  p.Person AS Manager,
  SUM(o.Sales) AS Total_Sales,
  SUM(o.Profit) AS Total_Profit
FROM orders o
LEFT JOIN people p
  ON o.Region = p.Region
GROUP BY o.Region, p.Person;

SELECT 
  p.Person AS Sales_Person,
  ROUND(SUM(o.Sales), 2) AS Total_Sales
FROM orders o
JOIN people p 
  ON UPPER(TRIM(o.Region)) = UPPER(TRIM(p.Region))
GROUP BY p.Person
ORDER BY Total_Sales DESC
LIMIT 1 OFFSET 1;


--3. Combine All Three Tables
SELECT 
  o.Order_ID,
  o.Region,
  o.Category,
  o.Sales,
  o.Profit,
  r.Returned,
  p.Person AS Manager
FROM orders o
LEFT JOIN returns r
  ON o.Order_ID = r.Returned_Order_ID
LEFT JOIN people p
  ON o.Region = p.Region;

--Insights
-- 1. View sample data
SELECT * FROM orders LIMIT 10;

-- 2. Total sales and profit
SELECT ROUND(SUM(Sales),2) AS Total_Sales, ROUND(SUM(Profit),2) AS Total_Profit FROM orders;

-- 3. Sales by Category
SELECT Category, ROUND(SUM(Sales),2) AS Sales, ROUND(SUM(Profit),2) AS Profit
FROM orders
GROUP BY Category
ORDER BY Sales DESC;

--4.Sales by Region and State
SELECT Region, State,
    ROUND(SUM(Sales),2) AS Sales,
    ROUND(SUM(Profit),2) AS Profit
FROM orders
GROUP BY Region, State
ORDER BY Region, Sales DESC;

--5. Top 10 Customers by Sales
SELECT 
    Customer_Name,
    ROUND(SUM(Sales),2) AS Total_Sales,
    ROUND(SUM(Profit),2) AS Total_Profit,
    COUNT(Order_ID) AS Order_Count
FROM orders
GROUP BY Customer_Name
ORDER BY Total_Sales DESC
LIMIT 10;

--6. Sales & Profit by Month (Time Analysis)
SELECT 
    DATE_FORMAT(Order_Date, '%Y-%m') AS Month,
    ROUND(SUM(Sales),2) AS Total_Sales,
    ROUND(SUM(Profit),2) AS Total_Profit
FROM orders
GROUP BY Month
ORDER BY Month;

--7. Profit Margin Analysis by Category
SELECT 
    Category,
    ROUND(SUM(Profit),2) AS Total_Profit,
    ROUND(SUM(Sales),2) AS Total_Sales,
    ROUND((SUM(Profit)/SUM(Sales))*100,2) AS Profit_Margin_Percent
FROM orders
GROUP BY Category
ORDER BY Profit_Margin_Percent DESC;

--8. Identify Loss-Making Orders
SELECT 
    Order_ID,
    Product_Name,
    Sales,
    Profit,
    Discount,
    Category,
    Sub_Category
FROM orders
WHERE Profit < 0
ORDER BY Profit ASC
LIMIT 10;

--9. Top 10 Performing Products by Profit
SELECT Product_Name,
       ROUND(SUM(Sales), 2) AS Total_Sales,
       ROUND(SUM(Profit), 2) AS Total_Profit
FROM orders
GROUP BY Product_Name
ORDER BY Total_Profit DESC
LIMIT 10;

--10.2nd Best Performing Salesperson (by Sales)
SELECT p.Person AS Sales_Person,
       ROUND(SUM(o.Sales), 2) AS Total_Sales
FROM orders o
JOIN people p ON o.Region = p.Region
GROUP BY p.Person
ORDER BY Total_Sales DESC
LIMIT 1 OFFSET 1; 

--11.Top 5 Cities by Profit
SELECT City,
       ROUND(SUM(Profit), 2) AS Total_Profit
FROM orders
GROUP BY City
ORDER BY Total_Profit DESC
LIMIT 5;

--12. Bottom 5 Cities (Loss-Making)
SELECT City,
       ROUND(SUM(Profit), 2) AS Total_Profit
FROM orders
GROUP BY City
ORDER BY Total_Profit ASC
LIMIT 5;

--13. Sales and Profit by Category
SELECT Category,
       ROUND(SUM(Sales), 2) AS Total_Sales,
       ROUND(SUM(Profit), 2) AS Total_Profit
FROM orders
GROUP BY Category
ORDER BY Total_Sales DESC;

--14.Customer Segment Performance 
SELECT Segment,
       ROUND(SUM(Sales), 2) AS Total_Sales,
       ROUND(SUM(Profit), 2) AS Total_Profit,
       ROUND((SUM(Profit)/SUM(Sales))*100, 2) AS Profit_Margin_Percent
FROM orders
GROUP BY Segment
ORDER BY Profit_Margin_Percent DESC;

--15. Yearly Sales Growth
SELECT YEAR(Order_Date) AS Year,
       ROUND(SUM(Sales), 2) AS Total_Sales,
       ROUND(SUM(Profit), 2) AS Total_Profit,
       ROUND((SUM(Profit)/SUM(Sales))*100, 2) AS Profit_Margin
FROM orders
GROUP BY YEAR(Order_Date)
ORDER BY Year;

--16. Monthly Sales Trend
SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS Month,
       ROUND(SUM(Sales), 2) AS Total_Sales
FROM orders
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
ORDER BY Month;

--17. Sales by Region and Manager
SELECT o.Region,
       p.Person AS Manager,
       ROUND(SUM(o.Sales), 2) AS Total_Sales,
       ROUND(SUM(o.Profit), 2) AS Total_Profit
FROM orders o
JOIN people p ON o.Region = p.Region
GROUP BY o.Region, p.Person
ORDER BY Total_Sales DESC;

--18. Top Performing Region (by Profit Margin)
SELECT Region,
       ROUND(SUM(Profit)/SUM(Sales)*100, 2) AS Profit_Margin_Percent
FROM orders
GROUP BY Region
ORDER BY Profit_Margin_Percent DESC
LIMIT 1;

--19.Correlation- (Discount vs Profit)
SELECT ROUND(AVG(Discount), 2) AS Avg_Discount,
       ROUND(AVG(Profit), 2) AS Avg_Profit,
       ROUND(SUM(Profit)/SUM(Sales)*100, 2) AS Profit_Margin
FROM orders;

--20. Customer Lifetime Value (Approximation)
SELECT 
    Customer_Name,
    COUNT(DISTINCT Order_ID) AS Orders_Placed,
    ROUND(SUM(Sales), 2) AS Total_Spend,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM orders
GROUP BY Customer_Name
ORDER BY Total_Spend DESC
LIMIT 10;




