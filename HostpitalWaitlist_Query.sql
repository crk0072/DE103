-- Hospital Waitlist Database
-- Create the HospitalWaitlist Database
CREATE DATABASE HospitalWaitlist;
GO

--Use the HospitalWaitlist Database
USE HospitalWaitlist;
GO

-- Set statistics to ON
SET STATISTICS IO ON
GO
SET STATISTICS TIME ON
GO
SET STATISTICS PROFILE ON
GO
-- Set statistics OFF
SET STATISTICS IO OFF
GO
SET STATISTICS TIME OFF
GO
SET STATISTICS PROFILE OFF
GO

-- Create tables with only Primary Keys, no Foreign Keys
-- According to my ERD this is: Patient, Department, Origin, Referee
CREATE TABLE Patient(
NHI CHAR(7) PRIMARY KEY NOT NULL,
FirstName VARCHAR(20),
LastName VARCHAR(30),
DOB DATE,
Gender VARCHAR(6),
);
GO

CREATE TABLE Department(
DepartmentID CHAR(2) PRIMARY KEY NOT NULL,
DepartmentName VARCHAR(20),
);
GO

CREATE TABLE Origin(
OriginID INT PRIMARY KEY NOT NULL,
OriginName VARCHAR(20),
);
GO

CREATE TABLE Referee(
RefereeID CHAR(4) PRIMARY KEY NOT NULL,
FirstName VARCHAR(20),
LastName VARCHAR(30),
);
GO

-- Create tables with Foreign Keys
-- According to my ERD this is: Surgeon, Referral
CREATE TABLE Surgeon(
SurgeonID CHAR(6) PRIMARY KEY NOT NULL,
FirstName VARCHAR(20),
LastName VARCHAR(30),
DepartmentID CHAR(2),
FOREIGN KEY (DepartmentID) REFERENCES [dbo].[Department]([DepartmentID]),
);
GO

CREATE TABLE Referral(
ReferralID INT PRIMARY KEY NOT NULL,
NHI CHAR(7),
SurgeonID CHAR(6),
OriginID INT,
RefereeID CHAR(4),
ReferralDate DATE,
WaitlistDate DATE,
FSA DATE,
AgeAtReferral INT,
DaysOnWaitlist INT,
FOREIGN KEY (NHI) REFERENCES [dbo].[Patient]([NHI]),
FOREIGN KEY (SurgeonID) REFERENCES [dbo].[Surgeon]([SurgeonID]),
FOREIGN KEY (OriginID) REFERENCES [dbo].[Origin]([OriginID]),
FOREIGN KEY (RefereeID) REFERENCES [dbo].[Referee]([RefereeID]),
);
GO

-- Table testing
SELECT * FROM [dbo].[Department];
SELECT * FROM [dbo].[Origin];
SELECT * FROM [dbo].[Patient];
SELECT * FROM [dbo].[Referee];
SELECT * FROM [dbo].[Surgeon];
SELECT * FROM [dbo].[Referral];
GO

-- Drop tables
DROP TABLE [dbo].[Department];
DROP TABLE [dbo].[Origin];
DROP TABLE [dbo].[Patient];
DROP TABLE [dbo].[Referee];
DROP TABLE [dbo].[Surgeon];
DROP TABLE [dbo].[Referral];
GO

-- Inserting Data from CSV files
-- ARA PATH: Unknown due to lockdown
-- LOCAL PATH: C:\Users\camer\Software&Databases\DE103\hospital-csv

BULK INSERT Patient FROM 'C:\Users\camer\Software&Databases\DE103\hospital-csv\patient.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='\n');
GO

BULK INSERT Department FROM 'C:\Users\camer\Software&Databases\DE103\hospital-csv\department.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='\n');
GO

BULK INSERT Origin FROM 'C:\Users\camer\Software&Databases\DE103\hospital-csv\origin.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='\n');
GO

BULK INSERT Referee FROM 'C:\Users\camer\Software&Databases\DE103\hospital-csv\referee.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='\n');
GO

BULK INSERT Surgeon FROM 'C:\Users\camer\Software&Databases\DE103\hospital-csv\surgeon.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='\n');
GO

BULK INSERT Referral FROM 'C:\Users\camer\Software&Databases\DE103\hospital-csv\referral.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='\n');
GO

-- QUERIES

-- Query 1 : How many people have been referred for cardiothoracic?
SELECT r.[ReferralID] AS 'Referral ID', r.[NHI], CONCAT_WS(' ', s.[FirstName], s.[LastName]) AS 'Surgeon', o.[OriginName] AS 'Origin of Referral' FROM [dbo].[Referral] r
INNER JOIN [dbo].[Surgeon] s ON r.[SurgeonID] = s.[SurgeonID]
INNER JOIN [dbo].[Origin] o ON r.[OriginID] = o.[OriginID]
WHERE s.[DepartmentID] = 'CT';
GO

-- Query 2 : What is the average number of days for a Patient to be seen by a Surgeon?
SELECT d.[DepartmentName] AS 'Department Name', AVG(DATEDIFF(DAY, r.[WaitlistDate], r.[FSA])) AS 'Time to be Seen' FROM [dbo].[Referral] r
INNER JOIN [dbo].[Surgeon] s ON s.[SurgeonID] = r.[SurgeonID]
INNER JOIN [dbo].[Department] d ON d.[DepartmentID] = s.[DepartmentID]
GROUP BY d.[DepartmentName];
GO

-- Query 3 : Who has each Surgeon had on their list and how long have they been waiting, or did they wait?
SELECT CONCAT_WS(' ', s.[FirstName], s.[LastName]) AS 'Surgeon', CONCAT_WS(' ', p.[FirstName], p.[LastName]) AS 'Patient',
DATEDIFF(DAY, r.[WaitlistDate], r.[FSA]) AS 'Wait Time (days)' FROM [dbo].[Referral] r
INNER JOIN [dbo].[Surgeon] s ON r.[SurgeonID] = s.[SurgeonID]
INNER JOIN [dbo].[Patient] p ON r.[NHI] = p.[NHI]
ORDER BY r.[SurgeonID];
GO

-- Query 4 : Do any patients need to be reassigned from Paediatric Surgery? No one needs to be reassigned
SELECT p.[NHI], p.[DOB], DATEDIFF(YEAR, p.[DOB], r.[FSA]) AS 'Age at FSA Date', d.[DepartmentName] AS 'Department Name' FROM [dbo].[Referral] r
INNER JOIN [dbo].[Patient] p ON r.[NHI] = p.[NHI]
INNER JOIN [dbo].[Surgeon] s ON r.[SurgeonID] = s.[SurgeonID]
INNER JOIN [dbo].[Department] d ON d.[DepartmentID] = s.[DepartmentID]
WHERE s.[DepartmentID] = 'PS' AND DATEDIFF(YEAR, p.[DOB], r.[FSA]) >= 18;
GO

-- Query 5 : What percentage of people were seen within the 75 day target, by department
-- I have no idea. I'm forfeiting these marks