-- combining the order years tables
with all_orders as (
SELECT 
OrderID, 
CustomerID,
ProductID,
OrderDate,
Quantity,
Revenue,
COGS
FROM Orders_2023

union all

SELECT 
OrderID, 
CustomerID,
ProductID,
OrderDate,
Quantity,
Revenue,
COGS
FROM Orders_2024

union all

SELECT 
OrderID, 
CustomerID,
ProductID,
OrderDate,
Quantity,
Revenue,
COGS
FROM Orders_2025)

--building the main dataset query
select  
a.OrderID, 
a.CustomerID,
c.Region,
a.ProductID,
a.OrderDate,
DATEADD(WEEK, DATEDIFF(WEEK, 0, a.OrderDate),0) as Week_Date,
c.CustomerJoinDate,
a.Quantity,
round(a.Revenue,2) as Revenue,
CASE WHEN a.Revenue is null then round((p.Price * a.Quantity),2) else round(a.Revenue,2) end as CleanedRevenue, --Creating CleanedRevenue column by filling nulls with price*quantity
round((a.Revenue - a.COGS),2) as Profit,
round(a.COGS,2) as COGS,
p.ProductName,
p.ProductCategory,
round(p.Price,2) as Price,
round(p.Base_Cost,2) as Base_Cost
from all_orders a
left join customers c --left join to NULL non matching values to cleanse
on a.CustomerID = c.CustomerID
left join products p 
on a.ProductID = p.ProductID

where a.CustomerID is not NULL --Dropping non customers ids



















































