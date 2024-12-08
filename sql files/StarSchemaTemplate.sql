USE TargetMartII;
GO

/*********************************************************/
/******************    Schema DDL       ******************/
/*********************************************************/

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dim' ) 
BEGIN
	EXEC sp_executesql N'CREATE SCHEMA dim AUTHORIZATION dbo;'
END
;

GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'stg' ) 
BEGIN
	EXEC sp_executesql N'CREATE SCHEMA stg AUTHORIZATION dbo;'
END
;

GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'f' ) 
BEGIN
	EXEC sp_executesql N'CREATE SCHEMA f AUTHORIZATION dbo;'
END
;

GO

/*********************************************************/
/******************  Customer DIM DDL   ******************/
/*********************************************************/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dim' AND TABLE_NAME = 'Customers')
BEGIN
	CREATE TABLE dim.Customers(
	pkCustomer int IDENTITY(1000,1) NOT NULL,
	CustomerID nvarchar(5) NOT NULL,
	Customer nvarchar(40) NOT NULL,
	City nvarchar(15) NULL,
	Country nvarchar(15) NULL,
	LoadDate DATE NOT NULL,
	SourceCountry nvarchar(25) NULL
	)
	;

	ALTER TABLE dim.Customers
	ADD CONSTRAINT PK_Customers_LUP PRIMARY KEY(pkCustomer);

	ALTER TABLE dim.Customers
    ADD CONSTRAINT UC_Customers_ID UNIQUE (CustomerID);

END


GO

/*********************************************************/
/****************** Calendar DIM Script ******************/
/*********************************************************/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dim' AND TABLE_NAME = 'Calendar')
BEGIN
-- Create the Calendar table
CREATE TABLE dim.Calendar
(
    pkCalendar INT NOT NULL,
    DateValue DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
	Qtr VARCHAR(3) NOT NULL,
    Month INT NOT NULL,
    MonthName VARCHAR(10) NOT NULL,
	MonthShort VARCHAR(3) NOT NULL,
    Week INT NOT NULL,
    Day INT NOT NULL,
	DayName VARCHAR(10) NOT NULL,
	DayShort VARCHAR(3) NOT NULL,
    IsWeekday BIT NOT NULL,
	Weekday VARCHAR(3) NOT NULL
);

	ALTER TABLE dim.Calendar
	ADD CONSTRAINT PK_Calendar_Julian PRIMARY KEY(pkCalendar);

	ALTER TABLE dim.Calendar
    ADD CONSTRAINT UC_Calendar UNIQUE (DateValue);
END

GO

/*********************************************************/
/******************  Shipper DIM DDL    ******************/
/*********************************************************/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dim' AND TABLE_NAME = 'Shipper')
BEGIN
-- Create the Calendar table
CREATE TABLE dim.Shipper
(
    pkShipId int not null,
	Shipper nvarchar(40) not null,
	Phone nvarchar(24) null
);

	ALTER TABLE dim.Shipper
	ADD CONSTRAINT PK_Ship PRIMARY KEY(pkShipId);
END

GO

/*********************************************************/
/******************  Products DIM DDL   ******************/
/*********************************************************/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dim' AND TABLE_NAME = 'Products')
BEGIN
CREATE TABLE dim.Products(
	pkProdId int NOT NULL,
	ProductId int NOT NULL,
	Product nvarchar(50) NOT NULL,
	ProductCategory nvarchar(25) NOT NULL,
	CategoryDesc ntext NULL,
	UnitPrice money NULL,
	UnitsInStock int NULL,
	UnitsOnOrder int NULL,
	ReorderLevel int NULL,
	Discontinued bit NOT NULL,
	ReorderFlag nvarchar(3) NOT NULL
);

	ALTER TABLE dim.Products
	ADD CONSTRAINT PK_Prods PRIMARY KEY(pkProdId);

	ALTER TABLE dim.Products
    ADD CONSTRAINT UC_Prods UNIQUE (ProductId);
END
;
GO

/*********************************************************/
/******************  Employees DIM DDL   ******************/
/*********************************************************/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dim' AND TABLE_NAME = 'Employees')
BEGIN
CREATE TABLE dim.Employees(
	EmployeeID int NOT NULL,
	Employee nvarchar(50) NOT NULL,
	Title nvarchar(30) NULL,
	BirthDate datetime NULL,
	HireDate datetime NULL,
	City nvarchar(15) NULL,
	Country nvarchar(15) NULL,
	ReportsTo int NULL
);
	ALTER TABLE dim.Employees
	ADD CONSTRAINT PK_Emp PRIMARY KEY(EmployeeID);

END

GO

/*********************************************************/
/*********************************************************/
/*********************************************************/
/******************  Fact Table Builds  ******************/
/*********************************************************/
/*********************************************************/
/*********************************************************/



/*********************************************************/
/******************  OrderPerf f.Table  ******************/
/*********************************************************/

-- OrderID, OrderDate, Customer, Freight(f)
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'f' AND TABLE_NAME = 'OrderPerf')
BEGIN 
	DROP TABLE f.OrderPerf;
END

GO

CREATE TABLE f.OrderPerf(
	OrderID int NOT NULL,
	fkCalendar int NOT NULL,
	fkCustomer int NOT NULL,
	fkShipper int NULL,
	fkEmployee int NULL,
	Freight money NOT NULL,
	DaysToShip int NULL,
	DaysTilRequired int NULL,
	OrderCount int NOT NULL
);

-- Could use PRIMARY or UNIQUE for the ORDERID - just used to not load dupes

ALTER TABLE f.OrderPerf
ADD CONSTRAINT PK_ORD PRIMARY KEY(OrderID)
;

ALTER TABLE f.OrderPerf
ADD CONSTRAINT FK_ORDtoCAL
	FOREIGN KEY (fkCalendar)              -- FROM the LOCAL TABLE
	 REFERENCES  dim.Calendar(pkCalendar) -- TO the FOREIGN TABLE
;

ALTER TABLE f.OrderPerf
ADD CONSTRAINT FK_ORDtoCUST
	FOREIGN KEY (fkCustomer)              -- FROM the LOCAL TABLE
	 REFERENCES  dim.Customers(pkCustomer) -- TO the FOREIGN TABLE
;

ALTER TABLE f.OrderPerf
ADD CONSTRAINT FK_ORDtoSHIP
	FOREIGN KEY (fkShipper)
	 REFERENCES dim.Shipper(pkShipId)
;

ALTER TABLE f.OrderPerf
ADD CONSTRAINT FK_ORDtoEMP
	FOREIGN KEY (fkEmployee)
	 REFERENCES dim.Employees(EmployeeID)
;

/*********************************************************/
/******************  ProductsPerf f.Table  ******************/
/*********************************************************/

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'f' AND TABLE_NAME = 'ProductPerf')
BEGIN 
	DROP TABLE f.ProductPerf;
END

CREATE TABLE f.ProductPerf(
	OrderID int NOT NULL,
	OrderDate int NOT NULL,
	ProductID int NOT NULL,
	CustomerID int NOT NULL,
	UnitPrice money NOT NULL,
	Quantity smallint NOT NULL,
	Discount float NOT NULL,
	DiscFlag int NOT NULL,
	LineTotal money NULL
);

ALTER TABLE f.ProductPerf
ADD CONSTRAINT PK_ProdPerf PRIMARY KEY(OrderID, ProductID)

ALTER TABLE f.ProductPerf
ADD CONSTRAINT FK_PRODtoCAL
	FOREIGN KEY (OrderDate)
	 REFERENCES dim.Calendar(pkCalendar)
;

ALTER TABLE f.ProductPerf
ADD CONSTRAINT FK_PRODtoPROD
	FOREIGN KEY (ProductID)
	 REFERENCES dim.Products(pkProdId)
;

ALTER TABLE f.ProductPerf
ADD CONSTRAINT FK_PRODtoCUST
	FOREIGN KEY (CustomerID)
	 REFERENCES dim.Customers(pkCustomer)
;