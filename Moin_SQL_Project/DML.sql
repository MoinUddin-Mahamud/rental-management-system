
--Insert into Users Table
USE RentalManagementDB;
INSERT INTO Users (Name, Email, Phone, UserType, ActiveStatus)
VALUES 
('Sufian', 'sufian@gmail.com', '01712345678', 'owner', 'active'),
('Miska', 'miska@gmail.com', '01887654321', 'owner', 'inactive'),
('Monir', 'monir@gmail.com', '01798765432', 'Renters', 'active'),
('Sayem', 'sayem@gmail.com', '01812349876', 'Renters', 'inactive'),
('Minhaj', 'minhaj@gmail.com', '01756473829', 'Renters', 'active');
Go

--Insert into Properties Table

USE RentalManagementDB;
INSERT INTO Properties (OwnerId, Title, Description, Type, Address, Size, Rooms, Available, ExpectedRentAmount, Status)
VALUES
(1, 'Cozy Family Apartment', 'Spacious flat with balcony view', 'Home', 'Dhanmondi, Dhaka', '1200 Sq ft', 3, '2025-09-15', 12000, 'available'),
(1, 'Modern Bachelor Flat', 'Well-lit flat near city center', 'Bachelor', 'Mirpur-10, Dhaka', '1000 Sq ft', 2, '2025-09-20', 10000, 'available'),
(2, 'Prime Office Space', 'Furnished space with meeting room', 'Office', 'Banani, Dhaka', '1800 Sq ft', 5, '2025-09-25', 15000, 'rented'),
(2, 'Luxury Sublet Flat', 'Stylish sublet with full amenities', 'Sublet', 'Gulshan-2, Dhaka', '1500 Sq ft', 3, '2025-09-18', 13000, 'rented'),
(1, 'Hostel Accommodation', 'Safe hostel for university students', 'Hostel', 'Uttara, Dhaka', '1300 Sq ft', 3, '2025-09-22', 11000, 'inactive');
Go


--Insert into Rentals Table

USE RentalManagementDB;
INSERT INTO Rentals (PropertyId, TenantId, StartDate, EndDate, RentAmount, Deposit, IsActive)
VALUES
(1, 3, '2025-09-15', '2026-09-14', 12000, 25000, 1),
(2, 4, '2025-09-20', '2026-09-19', 10000, 20000, 1),
(3, 5, '2025-09-25', NULL, 15000, 30000, 1),
(4, 3, '2025-09-18', NULL, 13000, 28000, 0),
(5, 4, '2025-09-22', '2026-09-21', 11000, 22000, 1);
GO

--Insert into Payments Table


USE RentalManagementDB;
INSERT INTO Payments (RentalId, PaymentDate, Amount, PaymentMethod, Status)
VALUES
(1, '2025-09-16', 12000, 'cash', 'completed'),
(2, '2025-09-21', 10000, 'card', 'completed'),
(3, '2025-09-26', 15000, 'bank transfer', 'pending'),
(4, '2025-09-19', 13000, 'mobile', 'completed'),
(5, '2025-09-23', 11000, 'cash', 'failed');
GO

--Insert into MaintenanceReq Table

USE RentalManagementDB;
INSERT INTO MaintenanceReq (PropertyId, TenantId, Description, Status, ResolutionDate)
VALUES
(1, 3, 'Leaking bathroom pipe', 'pending', NULL),
(2, 4, 'Broken window glass', 'in-progress', NULL),
(3, 5, 'Air conditioning not working', 'resolved', '2025-09-28'),
(4, 3, 'Water supply issue', 'closed', '2025-09-27'),
(5, 4, 'Furniture damage', 'pending', NULL);
GO 

--Insert into Images Table


INSERT INTO Images (PropertyId, Image)
values (1, (SELECT * FROM OPENROWSET(BULK N'D:\Untitled.png', SINGLE_BLOB) as T1)),
       (2, (SELECT * FROM OPENROWSET(BULK N'D:\ayan2.png', SINGLE_BLOB) as T1)),
       (3, (SELECT * FROM OPENROWSET(BULK N'D:\Ayan.png', SINGLE_BLOB) as T1))
Go

--Update

UPDATE Rentals 
SET IsActive = 0 
WHERE RentalId = 4
GO


--Delete

DELETE FROM Payments 
WHERE Status = 'failed';
GO

--Inner Join
SELECT Name, Title
FROM Users 
INNER JOIN Properties ON Users.UserId = Properties.OwnerId;
Go

--Left Join
SELECT Users.Name, Properties.Title
FROM Users
LEFT JOIN Properties 
ON Users.UserId = Properties.OwnerId
Go

--Full outer join
SELECT 
    Users.Name, Properties.Title
FROM Users
FULL OUTER JOIN Properties 
ON Users.UserId = Properties.OwnerId
Go

--Cross Join
SELECT Name, Title
FROM 
    Users
CROSS JOIN 
    Properties
 Go


  -- Aggregate Functions

 --(1) SUM

SELECT SUM(Amount) AS TotalRentCollected
FROM Payments
WHERE 
Status = 'completed'
Go

--(2) Average
SELECT AVG(RentAmount) AS AverageRens
FROM 
Rentals
Go

-- (3) MAX, MIN

SELECT 
    MAX(Amount) AS HighestPayment,
    MIN(Amount) AS LowestPayment
FROM Payments
WHERE Status = 'completed';
Go

--(4) COUNT

SELECT COUNT(*) AS TotalPayment
FROM Payments
Go

--(5) DISTINCT

SELECT DISTINCT PaymentMethod
FROM 
  Payments
Go

--(6) GROUP BY and COUNT

SELECT PaymentMethod, COUNT(*) AS Numberofpayments
FROM Payments
GROUP BY PaymentMethod
Go



--(7) ROLLUP 

SELECT PaymentMethod,
SUM(Amount) as TotalAmount
FROM Payments
GROUP BY 
ROLLUP (PaymentMethod)
go

--(8) Cube

SELECT PaymentMethod, Status,
SUM(Amount) AS TotalAmount
FROM Payments
GROUP BY 
 CUBE (PaymentMethod, Status)
GO

--(9) GROUPING SETS

SELECT PaymentMethod,Status,
SUM(Amount) AS TotalAmount
FROM Payments
GROUP BY GROUPING SETS 
(
(PaymentMethod),(Status)
)
Go

-- Having
SELECT OwnerId, COUNT(*) AS PropertyCount
FROM Properties
GROUP BY OwnerId
HAVING COUNT(*) > 1;
GO




-- Execute Procedure (Insert into payments)

EXEC sp_AddPayment @RentalId=1, @Amount=12000, @Method='cash';

Select * From Payments


--ORDER BY, TOP

SELECT TOP 3 Title, ExpectedRentAmount
FROM Properties
ORDER BY ExpectedRentAmount DESC;
GO

-- Offset/Fetch

SELECT Title, ExpectedRentAmount
FROM Properties
ORDER BY ExpectedRentAmount DESC
OFFSET 2 ROWS FETCH NEXT 3 ROWS ONLY;
GO

-- IN / NOT IN
SELECT * FROM Users WHERE UserType IN ('owner','Renters');
SELECT * FROM Users WHERE UserId NOT IN (SELECT TenantId FROM Rentals);

-- EXISTS
SELECT Name FROM Users u
WHERE EXISTS (SELECT 1 FROM Rentals r WHERE r.TenantId = u.UserId);

-- ANY / SOME 
SELECT Title FROM Properties
WHERE ExpectedRentAmount > ANY (SELECT RentAmount FROM Rentals);
GO

--CASE
 
SELECT Title,
       CASE 
           WHEN Status = 'available' THEN 'Ready to Rent'
           WHEN Status = 'rented' THEN 'Occupied'
           ELSE 'Not Active'
       END AS RentStatus
FROM Properties;
GO

-- Like

SELECT * FROM Users
WHERE Phone LIKE '017%';
GO

--UNION 

SELECT Name, 'Owner' AS Role FROM Users WHERE UserType = 'owner'
UNION
SELECT Name, 'Tenant' FROM Users WHERE UserType = 'Renters';

-- UNION ALL

SELECT Name FROM Users
UNION ALL
SELECT Name FROM Users;
GO

--CTE 

WITH TenantPayments AS
(
    SELECT r.TenantId, SUM(p.Amount) AS TotalPaid
    FROM Rentals r
    JOIN Payments p ON r.RentalId = p.RentalId
    GROUP BY r.TenantId
)
SELECT u.Name, t.TotalPaid
FROM Users u
JOIN TenantPayments t ON u.UserId = t.TenantId
WHERE t.TotalPaid > 10000;
GO

---- MERGE
MERGE Rentals AS r
USING (
    SELECT RentalId, SUM(Amount) AS Paid
    FROM Payments
    GROUP BY RentalId
) AS p
ON r.RentalId = p.RentalId
WHEN MATCHED AND p.Paid >= r.RentAmount
    THEN UPDATE SET r.IsActive = 0;
GO


-- TRY…CATCH with Transaction
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE Rentals SET RentAmount = RentAmount + 500 WHERE RentalId = 2;
    INSERT INTO Payments (RentalId, Amount, PaymentMethod, Status)
    VALUES (999, 5000, 'cash', 'completed'); -- Error (invalid RentalId)
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error occurred: ' + ERROR_MESSAGE();
END CATCH;
GO

-- WHILE / BREAK / CONTINUE
DECLARE @Counter INT = 1;
WHILE @Counter <= 5
BEGIN
    IF @Counter = 3
    BEGIN
        PRINT 'Skipping 3...';
        SET @Counter = @Counter + 1;
        CONTINUE;
    END
    PRINT 'Counter = ' + CAST(@Counter AS VARCHAR);
    IF @Counter = 4 BREAK;
    SET @Counter = @Counter + 1;
END;
GO

-- Dynamic SQL (sp_executesql)
DECLARE @TableName NVARCHAR(50) = 'Users';
DECLARE @SQL NVARCHAR(MAX);
SET @SQL = N'SELECT TOP 3 * FROM ' + QUOTENAME(@TableName);  
EXEC sp_executesql @SQL;

-- PRINT, RETURN, GOTO inside Procedure
CREATE OR ALTER PROC sp_CheckRent
    @RentalId INT
AS
BEGIN
    DECLARE @Amount DECIMAL(10,2);
    SELECT @Amount = RentAmount FROM Rentals WHERE RentalId = @RentalId;
    IF @Amount IS NULL
    BEGIN
        PRINT 'No such rental exists';
        RETURN;
    END
    IF @Amount > 12000 GOTO Expensive;
    PRINT 'This rent is normal';
    RETURN;
Expensive:
    PRINT 'This rent is high!';
END;

EXEC sp_CheckRent 1;

-- SET Options
SET DATEFORMAT dmy;
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;

-- Transaction Isolation Levels
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
    SELECT * FROM Rentals WHERE RentalId = 1;
COMMIT;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- SAVE TRAN, @@ROWCOUNT, @@TRANCOUNT
BEGIN TRANSACTION;
    UPDATE Rentals SET RentAmount = RentAmount + 500 WHERE RentalId = 1;
    PRINT 'Rows updated: ' + CAST(@@ROWCOUNT AS VARCHAR);
    SAVE TRAN SavePoint1;
    DELETE FROM Payments WHERE RentalId = 99;
    PRINT 'Transaction count: ' + CAST(@@TRANCOUNT AS VARCHAR);
ROLLBACK TRANSACTION SavePoint1;
COMMIT;

--OVER 

SELECT RentalId, Amount,
       SUM(Amount) OVER (PARTITION BY RentalId ORDER BY PaymentDate) AS RunningTotal
FROM Payments;

-- Output Parameter in Procedure

CREATE OR ALTER PROCEDURE sp_GetTotalPayments
    @RentalId INT,
    @TotalPaid DECIMAL(10,2) OUTPUT
AS
 BEGIN
    SELECT @TotalPaid = SUM(Amount) 
    FROM Payments
    WHERE RentalId = @RentalId;
 END;
GO

-- Calling with output
DECLARE @Result DECIMAL(10,2);
EXEC sp_GetTotalPayments @RentalId = 1, @TotalPaid = @Result OUTPUT;
PRINT 'Total Paid = ' + CAST(@Result AS VARCHAR);

--Default Parameter Value in Procedure
CREATE OR ALTER PROCEDURE sp_AddPaymentWithDefault
    @RentalId INT,
    @Amount DECIMAL(10,2),
    @Method VARCHAR(20) = 'cash'   -- Default value
AS
BEGIN
    INSERT INTO Payments (RentalId, Amount, PaymentMethod)
    VALUES (@RentalId, @Amount, @Method);
END;
GO

-- Call without specifying method

EXEC sp_AddPaymentWithDefault @RentalId = 2, @Amount = 5000;
GO



--INSERT / UPDATE / DELETE in a CTE
-- CTE for active rentals
WITH ActiveRentals AS
(
    SELECT * FROM Rentals WHERE IsActive = 1
)
-- Update via CTE
UPDATE ActiveRentals
SET RentAmount = RentAmount + 500;
GO

-- Delete via CTE
WITH OldPayments AS
(
    SELECT * FROM Payments WHERE Status = 'failed'
)
DELETE FROM OldPayments;


-- Insert into denormalized table
INSERT INTO PropertyOwnerSummary(PropertyId, OwnerName, PropertyTitle, ExpectedRentAmount, TotalRentCollected)
SELECT p.PropertyId, u.Name, p.Title, p.ExpectedRentAmount, ISNULL(SUM(pay.Amount),0)
FROM Properties p
JOIN Users u ON p.OwnerId = u.UserId
LEFT JOIN Rentals r ON r.PropertyId = p.PropertyId
LEFT JOIN Payments pay ON pay.RentalId = r.RentalId
GROUP BY p.PropertyId, u.Name, p.Title, p.ExpectedRentAmount;
GO



-- Delete failed payments in denormalized table
DELETE FROM PropertyOwnerSummary
WHERE TotalRentCollected = 0;
GO