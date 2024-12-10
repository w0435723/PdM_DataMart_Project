/*********************************************************/
/**************** Staging Tables DML *********************/
/*********************************************************/
/* 
   Data for staging tables was imported using the SQL Server Import and Export Wizard.
   The source data files were in CSV format, and each file was mapped to the corresponding
   staging table under the 'stg' schema. 
   Column mappings and data types were verified during the import process to ensure compatibility
   with the existing table schema. The import operation used the "Append Rows" option to add data
   to existing staging tables without overwriting or truncating any previous data.
*/

USE Sandbox;
GO

/*********************************************************/
/***************   Load Dimension tables  ****************/
/*********************************************************/

-- dim.Machines--

INSERT INTO dim.Machines (MachineID, Model, Age)
SELECT 
    s_m.MachineID,
    s_m.Model,
    s_m.Age
FROM stg.Machines AS s_m
WHERE s_m.MachineID NOT IN (SELECT MachineID FROM dim.Machines);
GO

-- dim.Errors ---

INSERT INTO dim.Errors (ErrorTimestamp, MachineID, Error)
SELECT 
    s_e.ErrorTimestamp,
    s_e.MachineID,
    s_e.Error
FROM stg.Errors AS s_e
WHERE s_e.Error NOT IN (SELECT Error FROM dim.Errors);
GO

--- dim.Failures ---

INSERT INTO dim.Failures (FailureTimestamp, MachineID, Failure)
SELECT 
    s_f.FailureTimestamp,
    s_f.MachineID,
    s_f.Failure
FROM stg.Failures AS s_f
WHERE s_f.Failure NOT IN (SELECT Failure FROM dim.Failures);
GO

--- dim.Maintenance ---

INSERT INTO dim.Maintenance (RepairedTime, MachineID, Comp)
SELECT 
    s_m.RepairedTime,
    s_m.MachineID,
    s_m.Comp
FROM stg.Maintenance AS s_m
WHERE NOT EXISTS (
    SELECT 1 
    FROM dim.Maintenance 
    WHERE RepairedTime = s_m.RepairedTime 
      AND MachineID = s_m.MachineID
      AND Comp = s_m.Comp
);
GO

/*********************************************************/
/***************     Load Fact tables    *****************/
/*********************************************************/

--- f.Telemetry ---

INSERT INTO f.Telemetry (MachineID, SensorReadTime, Volt, Rotate, Pressure, Vibration)
SELECT 
    s_t.MachineID,
    s_t.SensorReadTime,
    s_t.Volt,
    s_t.Rotate,
    s_t.Pressure,
    s_t.Vibration
FROM stg.Telemetry AS s_t
WHERE NOT EXISTS (
    SELECT 1 
    FROM f.Telemetry AS f_t
    WHERE s_t.MachineID = f_t.MachineID
      AND s_t.SensorReadTime = f_t.SensorReadTime
);
GO
