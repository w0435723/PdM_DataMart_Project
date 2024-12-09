USE Sandbox2;
GO

/*********************************************************/
/******************    Schema DDL       ******************/
/*********************************************************/

-- Creating schema for dimension tables
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dim' ) 
BEGIN
	EXEC sp_executesql N'CREATE SCHEMA dim AUTHORIZATION dbo;'
END
;

GO
-- Create schema for staging tables
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'stg' ) 
BEGIN
	EXEC sp_executesql N'CREATE SCHEMA stg AUTHORIZATION dbo;'
END
;

GO
-- Creating schema for fact tables
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'f' ) 
BEGIN
	EXEC sp_executesql N'CREATE SCHEMA f AUTHORIZATION dbo;'
END
;

GO

/*********************************************************/
/****************  Staging Tables DDL   ******************/
/*********************************************************/







/*********************************************************/
/****************  Dimension Tables DDL   ****************/
/*********************************************************/



/*********************************************************/
/****************  Fact Tables DDL   *********************/
/*********************************************************/