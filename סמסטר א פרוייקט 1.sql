------����� ������� �������-----

-- ����� ���� 1

SELECT TOP 5 p.Name AS ProductName, SUM(sod.LineTotal) AS TotalSalesAmount
FROM Sales.SalesOrderDetail sod JOIN  Production.Product p ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY TotalSalesAmount DESC;

-- ����� ���� 2
SELECT pc.Name AS CategoryName, AVG(sod.UnitPrice) AS AverageUnitPrice
FROM Sales.SalesOrderDetail sod JOIN Production.Product p ON sod.ProductID = p.ProductID 
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE pc.Name IN ('Bikes', 'Components')
GROUP BY pc.Name;

-- ����� ���� 3
SELECT p.Name AS ProductName,SUM(sod.OrderQty) AS TotalOrderQty
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE pc.Name NOT IN ('Components', 'Clothing')
GROUP BY p.Name;

-- ����� ���� 4
SELECT TOP 3 st.Name AS TerritoryName,SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader soh JOIN  Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
GROUP BY st.Name
ORDER BY TotalSales DESC;

-- ����� ���� 5

SELECT c.CustomerID, CONCAT(p.FirstName, ' ', p.LastName) AS FullName
FROM Sales.Customer c JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
WHERE soh.SalesOrderID IS NULL

-- ����� ���� 6

DELETE FROM Sales.SalesTerritory WHERE TerritoryID NOT IN ( SELECT DISTINCT TerritoryID FROM Sales.SalesPerson )

-- ����� ���� 7
INSERT INTO Sales.SalesTerritory ([Name], CountryRegionCode, [Group])
SELECT [Name], CountryRegionCode, [Group]
FROM [AdventureWorks2022].Sales.SalesTerritory
WHERE TerritoryID NOT IN (SELECT DISTINCT TerritoryID FROM Sales.SalesPerson)

-- ����� ���� 8
SELECT p.FirstName, p.LastName
FROM sales.SalesOrderHeader soh JOIN sales.Customer c ON soh.CustomerID = c.CustomerID
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
GROUP BY p.FirstName, p.LastName
HAVING COUNT(soh.SalesOrderID) > 20;

-- ����� ���� 9
SELECT GroupName, COUNT(*) AS DepartmentCount
FROM HumanResources.Department
GROUP BY GroupName
HAVING COUNT(*) > 2
ORDER BY DepartmentCount DESC;


-- ����� ���� 10
SELECT e.LoginID AS EmployeeName,d.Name AS DepartmentName,s.Name AS ShiftName
FROM HumanResources.Employee AS e JOIN HumanResources.EmployeeDepartmentHistory AS edh ON e.BusinessEntityID = edh.BusinessEntityID
JOIN HumanResources.Department AS d ON edh.DepartmentID = d.DepartmentID
JOIN HumanResources.Shift AS s ON edh.ShiftID = s.ShiftID
WHERE e.HireDate > '2010-01-01' AND (d.GroupName = 'Quality Assurance' OR d.GroupName = 'Manufacturing')
ORDER BY e.LoginID;



















