USE TargetMartII;
GO

/*
  Load the customer dimension data ...
*/
GO

INSERT INTO dim.Customers(CustomerID, Customer, City, Country, LoadDate, SourceCountry)
	SELECT nwc.CustomerID
		  ,nwc.CompanyName 
		  ,nwc.City
		  ,nwc.Country
		  ,CAST(getdate() as DATE)
		  ,concat('Country = ', nwc.Country) 
	FROM Northwind_2023.dbo.Customers nwc
	WHERE nwc.CustomerID not in (SELECT CustomerID FROM dim.Customers)

;
GO

/*
  Load the calendar dimension data ...
*/

IF (SELECT count(*) FROM dim.Calendar) = 0
BEGIN
-- Declare variables
DECLARE @StartDate DATE = '2020-01-01'
DECLARE @EndDate DATE = DATEADD(year, 0, GETDATE())
DECLARE @Date DATE = @StartDate
DECLARE @DayID INT = (datepart(year, @StartDate)-1900)*1000 + datepart(dy, @StartDate)
;


-- Populate the Calendar table
WHILE @Date <= @EndDate
	BEGIN
		INSERT INTO dim.Calendar (pkCalendar, DateValue, Year, Quarter, Qtr, Month,  MonthName, MonthShort, Week, Day, DayName, DayShort, IsWeekday, Weekday)
		VALUES (
			@DayID,
			@Date,
			YEAR(@Date),
			DATEPART(QUARTER, @Date),
			CASE WHEN DATEPART(QUARTER, @Date) IN (1) THEN '1st'
				 WHEN DATEPART(QUARTER, @Date) IN (2) THEN '2nd'
				 WHEN DATEPART(QUARTER, @Date) IN (3) THEN '3rd'
				 WHEN DATEPART(QUARTER, @Date) IN (4) THEN '4th'
				 ELSE '5th'
				 END,
			MONTH(@Date),
			DATENAME(MONTH, @Date),
			LEFT(DATENAME(MONTH, @Date),3),
			DATEPART(WEEK, @Date),
			DAY(@Date),
			DATENAME(WEEKDAY, @Date),
			LEFT(DATENAME(WEEKDAY, @Date),3),
			CASE WHEN DATEPART(WEEKDAY, @Date) IN (1, 7) THEN 0 ELSE 1 END, -- Set IsWeekday to 0 for Saturday (1) and Sunday (7), and 1 for weekdays
			CASE WHEN DATEPART(WEEKDAY, @Date) IN (1, 7) THEN 'No' ELSE 'Yes' END
	 )

		-- Increment the date and day ID
		SET @Date = DATEADD(DAY, 1, @Date)
		SET @DayID = @DayID + 1
	END
END
GO


/*
  Load the shipper dimension data ...
*/
GO

INSERT INTO dim.Shipper(pkShipId, Shipper, Phone)
SELECT s_sh.ShipperID
      ,s_sh.CompanyName
      ,s_sh.Phone
FROM Northwind_2023.dbo.Shippers s_sh
WHERE s_sh.ShipperID not in (SELECT pkShipId FROM dim.Shipper)
;
GO

/*
  Load the products dimension data ...
*/

INSERT INTO dim.Products(pkProdId, ProductId, Product, ProductCategory, CategoryDesc, UnitPrice, UnitsInStock, UnitsOnOrder, ReorderLevel, Discontinued, ReorderFlag)
SELECT prod.ProductID + 10000 as 'pkProdId'
      , prod.ProductID as 'ProductId'
      , prod.ProductName as 'Product'
	  , cat.CategoryName as 'ProductCategory'
	  , cat.[Description] as 'CategoryDesc'
	  , prod.UnitPrice
	  , prod.UnitsInStock
	  , prod.UnitsOnOrder
	  , prod.ReorderLevel
	  , prod.Discontinued
	  , CASE 
			WHEN prod.ReorderLevel >= (prod.UnitsInStock + prod.UnitsOnOrder)
			     AND prod.Discontinued = 0
			 THEN 'Yes'
	      ELSE 'No'
	    END as 'ReorderFlag'
FROM Northwind_2023.dbo.Products prod
	INNER JOIN Northwind_2023.dbo.Categories cat
	ON prod.CategoryID = cat.CategoryID
WHERE prod.ProductID not in (SELECT ProductId FROM dim.Products)
;



GO

/*
  Load the employees dimension data ...
*/

INSERT INTO dim.Employees(EmployeeID, Employee, Title, BirthDate, HireDate, City, Country, ReportsTo)
SELECT sEmp.EmployeeID
	  ,concat( sEmp.TitleOfCourtesy, ' ', sEmp.FirstName, ', ', sEmp.LastName)
      ,sEmp.Title
      ,sEmp.BirthDate
      ,sEmp.HireDate
      ,sEmp.City
      ,sEmp.Country
      ,sEmp.ReportsTo
FROM Northwind_2023.dbo.Employees sEmp
WHERE sEmp.EmployeeID not in (SELECT EmployeeID FROM dim.Employees)


/*********************************************************/
/******************  Fact TableLoaders  ******************/
/*********************************************************/


/******************  Orders Perf Fact   ******************/

TRUNCATE TABLE TargetMart.f.OrderPerf
GO

INSERT INTO TargetMart.f.OrderPerf(OrderID, fkCalendar, fkCustomer, fkShipper, fkEmployee, Freight, DaysToShip, DaysTilRequired, OrderCount)
SELECT sO.OrderID
	  ,tC.pkCalendar as fkCalendar
	  ,tCus.pkCustomer as fkCustomer
	  ,sO.ShipVia as fkShipper
	  ,sO.EmployeeID as fkEmployee
	  ,sO.Freight
	  ,DATEDIFF ( day , sO.OrderDate , sO.ShippedDate ) as 'DaysToShip'
	  ,DATEDIFF ( day , sO.OrderDate , sO.RequireDate ) as 'DaysTilRequired'
	  , 1 as 'OrderCount'
FROM Northwind_2023.dbo.Orders sO
	INNER JOIN TargetMart.dim.Calendar tC
	ON cast(so.OrderDate as DATE) = tc.DateValue
	INNER JOIN TargetMart.dim.Customers tCus
	ON sO.CustomerID = tCus.CustomerID
; 


/******************  Products Perf Fact  ******************/

TRUNCATE TABLE TargetMart.f.ProductPerf
GO

INSERT INTO TargetMart.f.ProductPerf(OrderID, OrderDate, ProductID, CustomerID, UnitPrice, Quantity, Discount, DiscFlag, LineTotal)
SELECT sDet.OrderID
      ,tCal.pkCalendar as 'OrderDate'
      ,sDet.ProductID + 10000 as 'ProductID'
--	  ,sOrd.CustomerID
	  ,tCust.pkCustomer
      ,sDet.UnitPrice
      ,sDet.Quantity
      ,sDet.Discount
	  ,CASE 
		 WHEN sDet.Discount = 0 THEN 0
		 ELSE 1
	   END as 'DiscFlag'
	  ,CAST(((1 - sDet.Discount) * sDet.UnitPrice) * sDet.Quantity as MONEY) as 'LineTotal'
FROM Northwind_2023.dbo.OrderDetails sDet
	INNER JOIN Northwind_2023.dbo.Orders sOrd
	ON sDet.OrderID = sOrd.OrderID
	INNER JOIN dim.Calendar tCal
	ON CAST(sOrd.OrderDate as DATE) = tCal.DateValue
	INNER JOIN dim.Customers tCust
	ON sOrd.CustomerID = tCust.CustomerID
;

