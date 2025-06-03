--**פתרון פרוייקט מספר 2**

--תשובה לשאלה 1 
WITH YearlySales AS (
    SELECT YEAR(i.InvoiceDate) AS Year, SUM(il.Quantity * il.UnitPrice) AS AnnualSales
    FROM Sales.InvoiceLines il JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID
    WHERE i.InvoiceDate IS NOT NULL
    GROUP BY YEAR(i.InvoiceDate)
),
LinearIncome AS (
    SELECT YEAR(i.InvoiceDate) AS Year,
        SUM(il.Quantity * il.UnitPrice) / COUNT(DISTINCT MONTH(i.InvoiceDate)) AS LinearIncome,
        COUNT(DISTINCT MONTH(i.InvoiceDate)) AS NumberOfDistinctMonths
    FROM Sales.InvoiceLines il JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID
    GROUP BY YEAR(i.InvoiceDate)
)
SELECT ys.Year, ys.AnnualSales, li.LinearIncome,li.NumberOfDistinctMonths,
    (li.LinearIncome - LAG(li.LinearIncome) OVER (ORDER BY ys.Year)) / LAG(li.LinearIncome) OVER (ORDER BY ys.Year) * 100 AS GrowthRate
FROM YearlySales ys JOIN LinearIncome li ON ys.Year = li.Year
ORDER BY ys.Year;

--תשובה לשאלה 2
WITH QuarterlySales AS (
    SELECT YEAR(i.InvoiceDate) AS Year, DATEPART(QUARTER, i.InvoiceDate) AS Quarter, i.CustomerID,
        SUM(il.Quantity * il.UnitPrice - il.TaxAmount) AS NetIncome 
    FROM Sales.InvoiceLines il 
    JOIN Sales.Invoices i ON il.InvoiceID = i.InvoiceID
    WHERE i.InvoiceDate IS NOT NULL
    GROUP BY YEAR(i.InvoiceDate), DATEPART(QUARTER, i.InvoiceDate), i.CustomerID
),
RankedCustomers AS (
    SELECT qs.Year, qs.Quarter, qs.CustomerID, qs.NetIncome,
        ROW_NUMBER() OVER (PARTITION BY qs.Year, qs.Quarter ORDER BY qs.NetIncome DESC) AS RowNum
    FROM QuarterlySales qs
)
SELECT rc.Year, rc.Quarter, c.CustomerName, rc.NetIncome, 
    ((rc.RowNum - 1) % 5) + 1 AS DNR 
FROM RankedCustomers rc 
JOIN Sales.Customers c ON rc.CustomerID = c.CustomerID
WHERE rc.RowNum <= 5
ORDER BY rc.Year, rc.Quarter, rc.RowNum;

--תשובה לשאלה 3
WITH ProductProfit AS (
 SELECT il.StockItemID, si.StockItemName,SUM(il.ExtendedPrice - il.TaxAmount) AS TotalProfit 
    FROM Sales.InvoiceLines il JOIN Warehouse.StockItems si ON il.StockItemID = si.StockItemID 
    GROUP BY il.StockItemID, si.StockItemName
)
SELECT TOP 10 pp.StockItemID, pp.StockItemName,pp.TotalProfit
FROM ProductProfit pp
ORDER BY pp.TotalProfit DESC;

--תשובה לשאלה 4
SELECT 
    ROW_NUMBER() OVER (ORDER BY (si.RecommendedRetailPrice - si.UnitPrice) DESC) AS Rn,
    si.StockItemID, si.StockItemName, si.UnitPrice, si.RecommendedRetailPrice, 
    (si.RecommendedRetailPrice - si.UnitPrice) AS NominalProfit,
	DENSE_RANK() OVER (ORDER BY si.UnitPrice DESC) AS DNR
FROM Warehouse.StockItems si
WHERE si.ValidFrom <= GETDATE() AND si.ValidTo >= GETDATE() 
ORDER BY NominalProfit DESC; 

--תשובה לשאלה 5
SELECT CONCAT(s.SupplierID, ' - ', s.SupplierName) AS SupplierDetails,
	   STRING_AGG(CONCAT(si.StockItemID, ' ', si.StockItemName), ', / ') AS ProductsList
FROM Purchasing.Suppliers s JOIN Warehouse.StockItems si ON s.SupplierID = si.SupplierID
GROUP BY s.SupplierID, s.SupplierName
ORDER BY s.SupplierID;

--תשובה לשאלה 6
SELECT TOP 5 
    c.CustomerID, ci.CityName AS CityName, co.CountryName AS CountryName, co.Continent AS Continent, co.Region AS Region,
    SUM(il.ExtendedPrice) AS TotalExtendedPrice
FROM [Sales].[InvoiceLines] il JOIN [Sales].[Invoices] i ON il.InvoiceID = i.InvoiceID
JOIN [Sales].[Customers] c ON i.CustomerID = c.CustomerID
JOIN [Application].[Cities] ci ON c.DeliveryCityID = ci.CityID
JOIN [Application].[StateProvinces] sp ON ci.StateProvinceID = sp.StateProvinceID
JOIN [Application].[Countries] co ON sp.CountryID = co.CountryID
GROUP BY c.CustomerID, c.CustomerName, ci.CityName, sp.StateProvinceName, co.CountryName, co.Continent, co.Region
ORDER BY SUM(il.ExtendedPrice) DESC;


--תשובה לשאלה 7 
WITH MonthlySales AS (
    SELECT YEAR(o.OrderDate) AS OrderYear, MONTH(o.OrderDate) AS OrderMonth, SUM(ol.Quantity * ol.UnitPrice) AS MonthlyTotal
    FROM [Sales].[OrderLines] ol JOIN [Sales].[Orders] o ON ol.OrderID = o.OrderID
    JOIN [Sales].[Invoices] i ON o.OrderID = i.OrderID
    WHERE i.InvoiceDate IS NOT NULL AND YEAR(o.OrderDate) IS NOT NULL AND MONTH(o.OrderDate) IS NOT NULL  
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
),
CumulativeSales AS (
    SELECT OrderYear, OrderMonth, MonthlyTotal,
        SUM(MonthlyTotal) OVER (PARTITION BY OrderYear ORDER BY OrderMonth) AS CumulativeTotal
    FROM MonthlySales
),
YearlySummary AS (
    SELECT OrderYear, 13 AS OrderMonth, SUM(MonthlyTotal) AS MonthlyTotal, SUM(MonthlyTotal) AS CumulativeTotal
    FROM MonthlySales
    GROUP BY OrderYear
)
SELECT OrderYear,
    CASE WHEN OrderMonth = 13 THEN 'Grand Total' ELSE CAST(OrderMonth AS VARCHAR)
    END AS OrderMonth, 
	FORMAT(MonthlyTotal, 'N2') AS MonthlyTotal, 
    FORMAT(CumulativeTotal, 'N2') AS CumulativeTotal 
FROM (
    SELECT * FROM CumulativeSales
    UNION ALL
    SELECT * FROM YearlySummary
) AS CombinedData
ORDER BY OrderYear,
    CASE WHEN OrderMonth = 13 THEN 13 ELSE OrderMonth
    END;

-- תשובה לשאלה 8
SELECT OrderMonth, [2013], [2014], [2015], [2016] 
FROM ( 
	SELECT YEAR(OrderDate) AS OrderYear, MONTH(OrderDate) AS OrderMonth
    FROM [Sales].[Orders]) AS SourceData
PIVOT (
    COUNT(OrderYear)
    FOR OrderYear IN ([2013], [2014], [2015], [2016])
) AS PivotedData
ORDER BY OrderMonth;

-- תשובה לשאלה 9
with cte 
as 
(select o.CustomerID,c.CustomerName, OrderDate,
lag(orderDate) over (partition by o.customerID order by orderDate) as prevOrder,
max(orderDate) over (partition by o.customerID) as lastOrder,
max(orderDate) over () as LastAllOrder,
DATEDIFF(day,lag(orderDate) over (partition by o.customerID order by orderDate),orderDate) as daysSinceLastOrder,
DATEDIFF(day,MAX(orderDate) over(partition by o.customerID), max(orderDate) over()) as diff
from sales.Customers as c inner join Sales.Orders as o
	on c.CustomerID = o.CustomerID ) 

select CustomerID,CustomerName,OrderDate,prevOrder, diff,
AVG(daysSinceLastOrder) over(partition by CustomerID) as avgDaysBetweenOrders,
case when AVG(daysSinceLastOrder) over(partition by CustomerID) > diff then 'active' else 'potenial churn' end
from cte
order by 1

--תשובה לשאלה 10
select *,CAST(customerCount as decimal(5,2))/totalCustCount *100.0
from 
(select CustomerCategoryName,count(distinct customerName) as customerCount,
sum(count(distinct customerName)) over () as totalCustCount
from
(select cc.CustomerCategoryName,case when CustomerName like 'Wingtip%' then 'Wingtip'
		when CustomerName like 'tailspin%' then 'tailspin'
		else CustomerName end as customerName
from sales.CustomerCategories as cc inner join sales.Customers as c
on cc.CustomerCategoryID = c.CustomerCategoryID) as a
group by CustomerCategoryName) as b



