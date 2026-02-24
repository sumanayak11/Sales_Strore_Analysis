CREATE DATABASE Sales_Store_Analysis
drop table Sales_Store

CREATE TABLE Sales_Store(
transaction_id VARCHAR(15),
customer_id VARCHAR(15),
customer_name VARCHAR(30),
customer_age INT,
gender VARCHAR (15),
product_id VARCHAR(15),
product_name VARCHAR(15),
product_category VARCHAR(15),
quantiy INT,
prce FLOAT,
payment_mode VARCHAR(15),
Purchase_date DATE,
Time_of_purchase TIME,
status VARCHAR(15)
)

select * from Sales_Store
---insert the data
--YYYY-MM-DD
  set DATEFORMAT dmy
BULK INSERT Sales_Store
FROM 'C:\Users\Dell\Downloads\SALESTORE\Sales_Store.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

--DATA CLEANING
select * from Sales_Store

--Sales_STore copy
SELECT * INTO Sales_C FROM Sales_Store

--Analysis on this copy
select * from Sales_C


--DATA CLEANING
--STEP 1: Check for duplicates

SELECT transaction_id, COUNT(*)
FROM Sales_C
GROUP BY transaction_id
HAVING COUNT(transaction_id)>1

WITH CTE AS (
SELECT*,
    ROW_NUMBER() OVER(PARTITION BY transaction_id ORDER BY transaction_id) AS Row_Num
FROM Sales_C
)
delete from CTE
WHERE Row_Num=2
SELECT * FROM CTE
WHERE Row_Num>1

--STEP 2: CORRECTION OF HEADERS

EXEC sp_rename 'Sales_C.quantiy','quantity','COLUMN'
EXEC sp_rename 'Sales_C.prce','price','COLUMN'

--STEP 3:To check DataTypes

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='Sales_C'

--STEP 4: TO check for NULL values
 
 DECLARE @SQL NVARCHAR(MAX) =''

 SELECT @SQL = STRING_AGG(
    'SELECT ''' + COLUMN_NAME + ''' AS ColumnName,
    COUNT(*) AS NullCount
    FROM ' + QUOTENAME(TABLE_SCHEMA) + '.Sales_C
    WHERE ' + QUOTENAME(COLUMN_NAME) + 'IS NULL',
    ' UNION ALL '
)
WITHIN GROUP (ORDER BY COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='Sales_C'

--EXECUTE THE DYNAMIC SQL
EXEC sp_executesql @SQL

--TREATING NULL VALUES

SELECT *
FROM Sales_C
WHERE transaction_id is null
or
customer_id is null
or 
customer_name is null
or
customer_age is null
or
gender is null
or
product_id is null
or
product_name is null
or
product_category is null
or
quantity is null
or
price is null
or
payment_mode is null
or
Purchase_date is null
or
Time_of_purchase is null
or
status is null

DELETE FROM Sales_C
WHERE transaction_id IS NULL

SELECT * FROM Sales_C
WHERE customer_name ='Ehsaan Ram'

update Sales_C
set customer_id='CUST9494'
WHERE transaction_id='TXN977900'

SELECT * FROM Sales_C
WHERE customer_name ='Damini Raju'

UPDATE Sales_C
SET customer_id='CUST1401'
WHERE transaction_id='TXN985663'

SELECT * from Sales_C
where customer_id='CUST1003'

update Sales_C
set customer_name='Mahika Saini', customer_age='35', gender='Male'
where transaction_id='TXN432798'

select * from Sales_C

--step 5: Data Cleaning
select DISTINCT gender
from Sales_C

UPDATE Sales_C
SET gender='M'
WHERE gender='Male'

UPDATE Sales_C
SET gender='F'
WHERE gender='Female'

select DISTINCT payment_mode
from Sales_C

UPDATE Sales_C
SET payment_mode ='Credit Card'
WHERE payment_mode='CC'

--Business requirements
--1.what are the TOP 5 most SELLING PRODUCT by QUANTITY?
--most demanding product
--helps priortize stock and boost sales through targeted performance
SELECT * FROM Sales_C

SELECT DISTINCT status
from Sales_C

SELECT TOP 5 product_name, SUM(quantity) as total_quantity_sold
from Sales_C
where status='delivered'
GROUP BY product_name
ORDER BY total_quantity_sold DESC

--2. which PRODUCTS are MOST frequently CANCELLED
--BUSINESS PROBLEM :frequent cancellation affect revenue and customer trust
--BUSINESS IMPACT: identify poor performing products to improve quality or remove from catalogue
select TOP 5 product_name, COUNT(*) AS total_cancelled
from Sales_C
where status='cancelled'
GROUP BY product_name
ORDER BY total_cancelled DESC

--3. what TIME of the DAY has the HIGHEST number of PURCHASE
---BUSINESS PROBLEM : Find peak sales times
--BUSINESS IMPACT:optimize staffing,promotions, and server loads

select * from Sales_C

select
    case
        when DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
        when DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
        when DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
        when DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
        END AS time_of_day,
        COUNT(*) as total_order
    from Sales_C
    GROUP BY 
        case
        when DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
        when DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
        when DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
        when DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
        END
        ORDER BY total_order DESC

--4. who are the TOP 5 HIGHEST SPENDING CUSTOMER
--BUSINESS PROBLEM: identify VI customers
----BUSINESS IMPACT:Persolized offers, loyalty rewards, and retention
select * from Sales_C

select TOP 5 customer_name, 
    FORMAT(sum(price*quantity),'C0','en-IN') as highest_spending_customer
from Sales_C
GROUP BY customer_name
ORDER BY sum(price*quantity) DESC

--5. which product CATEGORIES generate the HIGHEST REVENUE
select * from Sales_C
--BUSINESS PROBLEM:IDENTIFY TOP PERFORMING PRODUCT CATEGORIES
--BUSINESS IMPACT: allowing business to invest more in high-margin or high demand categories

select product_category, 
FORMAT(sum(quantity*price),'C0','en-IN') as Highest_Revenue
from Sales_C
GROUP BY product_category
ORDER BY sum(quantity*price) DESC

--6. what is the return/cancellation rate per product category
--BUSINESS PROBLEM: monitor dissatisfaction trend per category
--BUSINESS IMPACT:reduce returns, improve product descriptions/expectations, helps identify
--and fix product or logistic issues

select * from Sales_C
--cancellation
select product_category,
    FORMAT(COUNT(CASE WHEN status='cancelled' THEN 1 END)*100.0/COUNT(*),'N3')+' %' AS cancelled_percent
FROM C
GROUP BY product_category
ORDER BY cancelled_percent DESC

--RETURNED
select product_category,
    FORMAT(COUNT(CASE WHEN status='returned' THEN 1 END)*100.0/COUNT(*),'N3')+' %' AS returned_percent
FROM Sales_C
GROUP BY product_category
ORDER BY returned_percent DESC

--7. what is the most preferred payment mode 
--Business problem: know which payment options customer prefer
--Business Impact: streamline payment processing, priortize popular mode

select * from Sales_C

select payment_mode, count(*) as total_count
from Sales_C
group by payment_mode
order by total_count desc

--8. how does AGE group affect PURCHASING behaviour
--BUSINESS PROBLEM: Understand customer demographics
--Business Impact: targeted marketing and product recommendations by age group
select * from Sales_C

select min(customer_age), max(customer_age)
from Sales_C

select
    case 
        when customer_age BETWEEN 18 AND 25 THEN '18-25'
         when customer_age BETWEEN 26 AND 35 THEN '26-35'
          when customer_age BETWEEN 36 AND 50 THEN '36-50'
          ELSE '51+'
    END AS customer_age,
    FORMAT(SUM(price*quantity),'C0','EN-IN') AS Total_Purchase
from Sales_C
GROUP BY case 
        when customer_age BETWEEN 18 AND 25 THEN '18-25'
         when customer_age BETWEEN 26 AND 35 THEN '26-35'
          when customer_age BETWEEN 36 AND 50 THEN '36-50'
          ELSE '51+'
    END
ORDER BY Total_Purchase DESC

---9. what is the monthly sales trend?
--business problem: sales fluctuations go unnoticed
--business impact: plan inventory and marketing according to seasonal trends

select * from Sales_C

select 
    --YEAR(Purchase_date) AS YearS, 
    MONTH(Purchase_date) AS MONTHS,
    FORMAT(sum(price*quantity),'C0','en-IN') as total_sales,
    SUM(quantity) AS total_quantity
from Sales_C
group by MONTH(Purchase_date)
order by MONTHS

--10. Are certain genders busying more specific product categories?
--business problem: gender based product preferences
--business impact: persolized ads, gender focused campaigns
select * from Sales_C
--method 1
select gender, product_category, count(product_category) as Total_Purchase
from Sales_C
group by gender,product_category
order by gender ,Total_Purchase desc

--method 2
--pivot
select *
from (
    select gender, product_category
    from Sales_C
    ) as source_table
PIVOT(
    COUNT(gender)
    FOR gender IN ([M],[F])
    ) as pivot_table
order by product_category