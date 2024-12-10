USE Sandbox;
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
/***************** Machines Staging DDL ******************/
/*********************************************************/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'stg' AND TABLE_NAME = 'Machines')
BEGIN
    CREATE TABLE stg.Machines (
        MachineID INT NOT NULL,
        Model NVARCHAR(10) NOT NULL,
        Age INT NOT NULL
    );
END;
GO

/*********************************************************/
/***************** Telemetry Staging DDL *****************/
/*********************************************************/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'stg' AND TABLE_NAME = 'Telemetry')
BEGIN
    CREATE TABLE stg.Telemetry (
        SensorReadTime DATETIME NOT NULL,
        MachineID INT NOT NULL,
        Volt FLOAT NOT NULL,
        Rotate FLOAT NOT NULL,
        Pressure FLOAT NOT NULL,
        Vibration FLOAT NOT NULL
    );
END;
GO

/*********************************************************/
/***************** Errors Staging DDL ********************/
/*********************************************************/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'stg' AND TABLE_NAME = 'Errors')
BEGIN
    CREATE TABLE stg.Errors (
        ErrorTimestamp DATETIME NOT NULL,
        MachineID INT NOT NULL,
        Error NVARCHAR(10) NOT NULL
    );
END;
GO

/*********************************************************/
/***************** Failures Staging DDL ******************/
/*********************************************************/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'stg' AND TABLE_NAME = 'Failures')
BEGIN
    CREATE TABLE stg.Failures (
        FailureTimestamp DATETIME NOT NULL,
        MachineID INT NOT NULL,
		Failure NVARCHAR(10) NOT NULL
    );
END;
GO

/*********************************************************/
/**************** Maintenance Staging DDL ****************/
/*********************************************************/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'stg' AND TABLE_NAME = 'Maintenance')
BEGIN
    CREATE TABLE stg.Maintenance (
        RepairedTime DATETIME NOT NULL,
        MachineID INT NOT NULL,
        Comp NVARCHAR(10) NOT NULL
    );
END;
GO

/*********************************************************/
/***************** Machines DIM DDL **********************/
/*********************************************************/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dim' AND TABLE_NAME = 'Machines')
BEGIN
    CREATE TABLE dim.Machines (
        pkMachineID INT IDENTITY(1,1) NOT NULL,
        MachineID INT NOT NULL,
        Model NVARCHAR(10) NOT NULL,
        Age INT NOT NULL
    );

    ALTER TABLE dim.Machines
    ADD CONSTRAINT PK_Machines PRIMARY KEY (pkMachineID);

    ALTER TABLE dim.Machines
    ADD CONSTRAINT UC_Machines UNIQUE (MachineID);
END;
GO

/*********************************************************/
/***************** Calendar DIM DDL **********************/
/*********************************************************/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dim' AND TABLE_NAME = 'Calendar')
BEGIN
    CREATE TABLE dim.Calendar (
        pkCalendarID INT IDENTITY(1,1) NOT NULL,
        CalendarDateTime DATETIME NOT NULL,
        Year INT NOT NULL,
        Month INT NOT NULL,
        Day INT NOT NULL,
        Hour INT NOT NULL,
        Weekday NVARCHAR(10) NOT NULL
    );

    ALTER TABLE dim.Calendar
    ADD CONSTRAINT PK_Calendar PRIMARY KEY (pkCalendarID);

    ALTER TABLE dim.Calendar
    ADD CONSTRAINT UC_Calendar UNIQUE (datetime);
END;
GO

/*********************************************************/
/***************** Errors DIM DDL ************************/
/*********************************************************/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dim' AND TABLE_NAME = 'Errors')
BEGIN
    CREATE TABLE dim.Errors (
		ErrorTimestamp DATETIME NOT NULL,
		MachineID INT NOT NULL,
        Error NVARCHAR(10) NOT NULL
 
    );

    ALTER TABLE dim.Errors
    ADD CONSTRAINT PK_Errors PRIMARY KEY (ErrorID);
END;
GO

/*********************************************************/
/***************** Failures DIM DDL **********************/
/*********************************************************/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dim' AND TABLE_NAME = 'Failures')
BEGIN
    CREATE TABLE dim.Failures (
        FailureTimestamp DATETIME NOT NULL,
        MachineID INT NOT NULL,
		Failure NVARCHAR(10) NOT NULL
    );

    ALTER TABLE dim.Failures
    ADD CONSTRAINT PK_Failures PRIMARY KEY (datetime, MachineID);
END;
GO

/*********************************************************/
/***************** Maintenance DIM DDL *******************/
/*********************************************************/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dim' AND TABLE_NAME = 'Maintenance')
BEGIN
    CREATE TABLE dim.Maintenance (
        RepairedTime DATETIME NOT NULL,
        MachineID INT NOT NULL,
        Comp NVARCHAR(10) NOT NULL
    );

    ALTER TABLE dim.Maintenance
    ADD CONSTRAINT PK_Maintenance PRIMARY KEY (datetime, MachineID);
END;
GO

/*********************************************************/
/**************** Telemetry Fact Table DDL ***************/
/*********************************************************/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'f' AND TABLE_NAME = 'Telemetry')
BEGIN
    CREATE TABLE f.Telemetry (
        TelemetryID INT IDENTITY(1,1) NOT NULL,
        MachineID INT NOT NULL,
        SensorReadTime DATETIME NOT NULL,
        Volt FLOAT NOT NULL,
        Rotate FLOAT NOT NULL,
        Pressure FLOAT NOT NULL,
        Vibration FLOAT NOT NULL
    );

    ALTER TABLE f.Telemetry
    ADD CONSTRAINT PK_Telemetry PRIMARY KEY (TelemetryID);

    ALTER TABLE f.Telemetry
    ADD CONSTRAINT FK_Telemetry_MachineID FOREIGN KEY (MachineID)
    REFERENCES dim.Machines (MachineID);

    ALTER TABLE f.Telemetry
    ADD CONSTRAINT FK_Telemetry_Datetime FOREIGN KEY (datetime)
    REFERENCES dim.Calendar (datetime);
END;
GO
