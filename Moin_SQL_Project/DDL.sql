
USE master;
GO

DECLARE @data_path nvarchar(256);
SET @data_path = (SELECT SUBSTRING(physical_name, 1, CHARINDEX(N'master.mdf', LOWER(physical_name)) - 1)
      FROM master.sys.master_files
      WHERE database_id = 1 AND file_id = 1);

EXECUTE ('CREATE DATABASE RentalManagementDB
ON PRIMARY(NAME =RentalManagementDB_data, FILENAME = ''' + @data_path + 'RentalManagementDB_data.mdf'', SIZE = 25MB, MAXSIZE = Unlimited, FILEGROWTH = 5%)
LOG ON (NAME = RentalManagementDB_log, FILENAME = ''' + @data_path + 'RentalManagementDB_log.ldf'', SIZE = 10MB, MAXSIZE = 100MB, FILEGROWTH = 1MB)'
);
GO
--Users Table
USE RentalManagementDB
Create Table Users
 (
    UserId INT PRIMARY KEY IDENTITY(1,1),
    Name VARCHAR(50) NOT NULL,
    Email VARCHAR(50) NULL,
    Phone VARCHAR(30) Not NULL,
    Usertype VARCHAR(10) NOT NULL CHECK (Usertype IN ('owner','Renters')),
    Createdate DATETIME DEFAULT SYSUTCDATETIME(),
    ActiveStatus VARCHAR(10) 
        DEFAULT 'active' 
        CHECK (ActiveStatus IN ('active', 'inactive'))
 )
Go

 Select * From Users

 --Properties Table
 USE RentalManagementDB
 CREATE TABLE Properties
 (
    PropertyId INT PRIMARY KEY IDENTITY(1,1),
    OwnerId INT FOREIGN KEY REFERENCES Users(UserId),
    Title VARCHAR(50) NOT NULL,
    Description NVARCHAR(200) NULL,
    Type VARCHAR(20) NOT NULL CHECK (Type IN ('Home','Office','Sublet','Bachelor','Hostel')),
    Address NVARCHAR(100) NOT NULL,
    Size VARCHAR(50) NOT NULL,
    Rooms INT NULL,
    Available DATE NULL,
    ExpectedRentAmount DECIMAL(10,2) NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'available' CHECK (Status IN ('available','rented','inactive')),
    CreatedAt DATETIME DEFAULT GETDATE()
)


GO
Select * From Properties


--Rentals Tables
USE RentalManagementDB
Create Table Rentals 
(
    RentalId INT PRIMARY KEY IDENTITY(1,1),
    PropertyId INT FOREIGN KEY REFERENCES Properties(PropertyId),
    TenantId INT FOREIGN KEY REFERENCES Users(UserId),
    StartDate DATE NOT NULL,
    EndDate DATE NULL,
    RentAmount DECIMAL(10,2) NOT NULL,
    Deposit DECIMAL(10,2),
    IsActive BIT DEFAULT 1
)

Go

Select * From Rentals


--payments Tables

USE RentalManagementDB
CREATE TABLE Payments 
(
    PaymentId INT PRIMARY KEY IDENTITY(1,1),
    RentalId INT FOREIGN KEY REFERENCES Rentals(RentalId),
    PaymentDate DATE DEFAULT GETDATE(),
    Amount DECIMAL(10,2) NOT NULL,
    PaymentMethod VARCHAR(20) NOT NULL 
        CHECK (PaymentMethod IN ('cash', 'card', 'bank transfer', 'mobile')),
    Status VARCHAR(20) NOT NULL DEFAULT 'completed' CHECK (Status IN ('pending', 'completed', 'failed'))
)

GO
Select * From Payments




--MaintenanceReq

USE RentalManagementDB
CREATE TABLE MaintenanceReq 
(
    RequestId INT PRIMARY KEY IDENTITY(1,1),
    PropertyId INT FOREIGN KEY REFERENCES Properties(PropertyId),
    TenantId INT FOREIGN KEY REFERENCES Users(UserId),
    RequestDate DATETIME NOT NULL DEFAULT GETDATE(),
    Description NVARCHAR(50) NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (Status IN ('pending', 'in-progress', 'resolved', 'closed')),
    ResolutionDate DATETIME NULL
)

GO
Select * From MaintenanceReq


--Images Tables
USE RentalManagementDB
Create Table Images
( 
  ImageId INT PRIMARY KEY IDENTITY(1,1),
  PropertyId INT FOREIGN KEY REFERENCES Properties(PropertyId),
  Image VARBINARY(MAX) NOT NULL
)

GO
Select * From Images
Go

--View

Create VIEW vw_ActiveRentals AS
Select r.RentalId, u.Name AS TenantName, p.Title AS PropertyTitle, r.RentAmount, r.StartDate, r.EndDate
FROM Rentals r
INNER JOIN Users u ON r.TenantId = u.UserId
INNER JOIN Properties p ON r.PropertyId = p.PropertyId
WHERE r.IsActive = 1;
GO

SELECT * FROM vw_ActiveRentals;



-- Clustered index on Rentals table based on RentalId

Create Clustered Index CIndex_Images
ON Images(ImageId)
GO



-- Non-clustered index on Users table Phone column
CREATE NONCLUSTERED INDEX NonIndex_Users 
ON Users(Phone);
Go

SELECT * 
FROM Users
WHERE Phone = '01712345678';

--Function

CREATE FUNCTION fn_TotalPayments (@RentalId INT)
RETURNS DECIMAL(10,2)
AS
 BEGIN
    RETURN (SELECT SUM(Amount) FROM Payments WHERE RentalId = @RentalId);
END
Go

--calling Function
SELECT dbo.fn_TotalPayments(1) AS TotalPaidForRental1;



--procedure

CREATE PROC sp_AddPayment
    @RentalId INT,
    @Amount DECIMAL(10,2),
    @Method VARCHAR(20)
AS
 BEGIN
    INSERT INTO Payments (RentalId, Amount, PaymentMethod)
    VALUES (@RentalId, @Amount, @Method);
END;

--Alter

ALTER TABLE Users ADD NationalId VARCHAR(20) NULL
GO

ALTER TABLE Users DROP COLUMN NationalId
GO



--Transaction

BEGIN TRANSACTION;
    UPDATE Rentals SET RentAmount = RentAmount + 1000 WHERE RentalId = 1;
    INSERT INTO Payments (RentalId, Amount, PaymentMethod, Status)
    VALUES (1, 12000, 'cash', 'completed');
COMMIT;

-- Rollback 

BEGIN TRANSACTION;
    DELETE FROM Users WHERE UserId = 5;
ROLLBACK;



--Trigger 
CREATE TRIGGER trg_UpdateRentalStatus
ON Payments
AFTER INSERT
AS
 BEGIN
    UPDATE Rentals
    SET IsActive = 0
    WHERE RentalId IN (SELECT RentalId FROM inserted WHERE Status = 'failed');
 END
GO


--Drop

DROP TABLE Images
GO

DROP DATABASE RentalManagementDB;


-- Drop Non-Clustered Index
DROP INDEX NonIndex_Users ON Users;
GO

-- Rebuild clustered index
ALTER INDEX CIndex_Images ON Images REBUILD;=====================44444
GO

-- Create schema for reports

CREATE SCHEMA Reports;
GO

-- Move a view into Reports schema

ALTER SCHEMA Reports TRANSFER vw_ActiveRentals;
GO

-- Temp table 

CREATE TABLE #TopPayments
(
    TenantId INT,
    TotalPaid DECIMAL(10,2)
);
GO

--SEQUENCE

CREATE SEQUENCE PaymentSeq
    START WITH 1000
    INCREMENT BY 1;
GO

-- Prevent delete on Users if still owns properties
CREATE TRIGGER trg_PreventOwnerDelete
ON Users
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Properties p JOIN deleted d ON p.OwnerId = d.UserId)======44444
    BEGIN
        RAISERROR('Cannot delete owner with active properties!', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        DELETE FROM Users WHERE UserId IN (SELECT UserId FROM deleted);
    END
END;
GO

-- Encrypted view with schema binding

CREATE VIEW vw_CompletedPayments
WITH ENCRYPTION, SCHEMABINDING
AS
SELECT RentalId, Amount, PaymentDate
FROM dbo.Payments
WHERE Status = 'completed';
GO
 

--Filtered Index
CREATE NONCLUSTERED INDEX IX_ActiveRentals
ON Rentals(IsActive)
WHERE IsActive = 1;
Go

-- Sparse Columns Example
CREATE TABLE OptionalInfo
(
    InfoId INT IDENTITY(1,1) PRIMARY KEY,
    Notes NVARCHAR(100) SPARSE NULL,
    ExtraDetails NVARCHAR(200) SPARSE NULL
);

-- Unicode / Collation Example
CREATE TABLE MultilingualData
(
    DataId INT PRIMARY KEY,
    TextData NVARCHAR(100) COLLATE Latin1_General_CI_AI
);


--DROP FUNCTION

DROP FUNCTION fn_TotalPayments;
GO

--DROP PROCEDURE

DROP PROCEDURE sp_AddPayment;
GO

-- DROP TRIGGER
DROP TRIGGER trg_UpdateRentalStatus;
GO

-- ALTER SEQUENCE
ALTER SEQUENCE PaymentSeq
    RESTART WITH 2000
    INCREMENT BY 5;
GO


--DROP SEQUENCE
DROP SEQUENCE PaymentSeq;
GO

--ALTER DATABASE (for snapshot isolation)

ALTER DATABASE RentalManagementDB
SET ALLOW_SNAPSHOT_ISOLATION ON;
GO



BEFORE Trigger (SQL Server doesn’t support it directly, but conceptually it’s a INSTEAD OF trigger for INSERT/UPDATE/DELETE)

-- Example: BEFORE INSERT equivalent using INSTEAD OF
CREATE TRIGGER trg_BeforeInsertProperties
ON Properties
INSTEAD OF INSERT
AS
BEGIN
    -- Check condition before inserting
    IF EXISTS (SELECT 1 FROM inserted WHERE ExpectedRentAmount < 0)
    BEGIN
        RAISERROR('Rent cannot be negative', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        INSERT INTO Properties(PropertyId, OwnerId, Title, Description, Type, Address, Size, Rooms, Available, ExpectedRentAmount, Status, CreatedAt)
        SELECT PropertyId, OwnerId, Title, Description, Type, Address, Size, Rooms, Available, ExpectedRentAmount, Status, CreatedAt
        FROM inserted;
    END
END;
GO



-- Simulating a scheduled event
CREATE PROCEDURE sp_DailyRentUpdate
AS
BEGIN
    UPDATE Rentals
    SET RentAmount = RentAmount + 50
    WHERE IsActive = 1;
END;
GO



--THROW instead of RAISERROR

CREATE TRIGGER trg_PreventNegativeRent
ON Rentals
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE RentAmount < 0)
    BEGIN
        THROW 50001, 'Rent cannot be negative', 1;
    END
    ELSE
    BEGIN
        INSERT INTO Rentals(RentalId, PropertyId, TenantId, StartDate, EndDate, RentAmount, Deposit, IsActive)
        SELECT RentalId, PropertyId, TenantId, StartDate, EndDate, RentAmount, Deposit, IsActive
        FROM inserted;
    END
END;
GO


--MONEY datatype for financial columns

CREATE TABLE Invoice (
    InvoiceId INT PRIMARY KEY IDENTITY(1,1),
    RentalId INT FOREIGN KEY REFERENCES Rentals(RentalId),
    TotalAmount MONEY NOT NULL,
    PaymentTotal MONEY NOT NULL,
    InvoiceDate DATE DEFAULT GETDATE()
);
GO


--Denormalized table / functional dependency example

CREATE TABLE PropertyOwnerSummary
(
    PropertyId INT PRIMARY KEY,
    OwnerName VARCHAR(50),
    PropertyTitle VARCHAR(50),
    ExpectedRentAmount DECIMAL(10,2),
    TotalRentCollected DECIMAL(10,2)
);
GO




--System Views (metadata)
-- List all tables
SELECT * FROM sys.tables;

-- List all views
SELECT * FROM sys.views;

-- List all columns
SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users');

-- List schemas
SELECT * FROM sys.schemas;

-- List all sequences
SELECT * FROM sys.sequences;

-- List constraints
SELECT * FROM sys.key_constraints;

-- List foreign keys
SELECT * FROM sys.foreign_keys;