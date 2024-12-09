# PdM_DataMart_Project
 
## Project Description
This repository contains the data mart project for Predictive Maintenance (PdM).
The scope of this project is to create a star schema data mart to analyze machine telemetry, errors, and maintenance data for predictive analytics.


**📝Dataset Overview:**   

The source datasets include:

| Source Table      | Description                                                                                          |
|-------------------|------------------------------------------------------------------------------------------------------|
| `PdM_errors`      | Contains error logs with timestamps and machine IDs.                                                 |
| `PdM_failures`    | Tracks machine failures with timestamps and failure types.                                           |
| `PdM_machines`    | Details about the machines, such as ID, age, and type.                                               |
| `PdM_maint`       | Maintenance records including timestamps and activity types.                                         |
| `PdM_telemetry`   | Time-series data with sensor readings for each machine, such as voltage, rotation, pressure, and vibration. |  


**📝 Data Source:**  

The datasets are sourced from Microsoft Azure Predictive Maintenance Dataset. It can be found on [Kaggle](https://www.kaggle.com/datasets/arnabbiswas1/microsoft-azure-predictive-maintenance/data)   

**📝 Datamart Objectives / Key Points:**  

1.  Identify trends in failures and errors
2.  Analyze machine perfoamrnace metrics

**📝 Project Files:**   

[Datamart project notebook]  
[ERD diagram]    
[SQL DDL Scripts]   
[SQL DML Loader]   
[Data files]  