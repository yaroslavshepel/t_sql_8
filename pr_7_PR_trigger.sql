use SportStore

/*1*/
CREATE TRIGGER trg_SaleHistory
ON [Sales_PR]
AFTER INSERT
AS
BEGIN
    INSERT INTO [SaleHistory_PR] (SaleID, ProductID, SalePrice, Quantity, SaleDate, EmployeeID, CustomerID)
    SELECT Id, ProductID, SalePrice, Quantity, SaleDate, EmployeeID, CustomerID 
    FROM inserted;
END;
GO

/*2*/
CREATE TRIGGER trg_ArchiveSoldOut
ON [Sales_PR]
AFTER INSERT
AS
BEGIN
    INSERT INTO [Archive_PR] (ProductID, ProductName, SaleDate)
    SELECT p.Id, p.ProductName, GETDATE()
    FROM [Products_PR] p
    INNER JOIN inserted i
    ON p.Id = i.ProductID
    WHERE p.Quantity = 0;
END;
GO

/*3*/
CREATE TRIGGER trg_NoDuplicateCustomer
ON [Customers_PR]
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM [Customers_PR]
        WHERE FullName = (SELECT FullName FROM inserted)
          AND Email = (SELECT Email FROM inserted)
    )
    BEGIN
        RAISERROR ('Клієнт вже існує', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        INSERT INTO [Customers_PR] (FullName, Email, Phone, Gender, OrderHistory, DiscountPercent, NewsletterSubscription)
        SELECT FullName, Email, Phone, Gender, OrderHistory, DiscountPercent, NewsletterSubscription
        FROM inserted;
    END
END;
GO

/*4*/
CREATE TRIGGER trg_NoCustomerDelete
ON [Customers_PR]
INSTEAD OF DELETE
AS
BEGIN
    RAISERROR ('Видалення клієнтів заборонено', 16, 1);
    ROLLBACK TRANSACTION;
END;
GO

/*5*/
CREATE TRIGGER trg_NoOldEmployeeDelete
ON [Employees_PR]
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM deleted
        WHERE HireDate < '2015-01-01'
    )
    BEGIN
        RAISERROR ('Видалення співробітників, прийнятих до 2015 року, заборонено', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        DELETE FROM [Employees_PR]
        WHERE Id IN (SELECT Id FROM deleted);
    END
END;
GO

/*6*/
CREATE TRIGGER trg_CheckCustomerSpending
ON [Sales_PR]
AFTER INSERT
AS
BEGIN
    DECLARE @CustomerID INT
    DECLARE @TotalSpent DECIMAL(10, 2)

    SELECT @CustomerID = CustomerID
    FROM inserted;

    SELECT @TotalSpent = SUM(SalePrice * Quantity)
    FROM [Sales_PR]
    WHERE CustomerID = @CustomerID;

    IF @TotalSpent >= 50000
    BEGIN
        UPDATE [Customers_PR]
        SET DiscountPercent = 15
        WHERE Id = @CustomerID;
    END
END;
GO

/*7*/
CREATE TRIGGER trg_NoSpecificBrand
ON [Products_PR]
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM inserted
        WHERE [Manufacturer] = 'Спорт, сонце та штанга'
    )
    BEGIN
        RAISERROR ('Додавання товарів фірми "Спорт, сонце та штанга" заборонено', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        INSERT INTO [Products_PR] (ProductName, ProductType, Quantity, Cost, Manufacturer, SalePrice)
        SELECT ProductName, ProductType, Quantity, Cost, Manufacturer, SalePrice
        FROM inserted;
    END
END;
GO

/*8*/
CREATE TRIGGER trg_LastUnit
ON [Sales_PR]
AFTER INSERT
AS
BEGIN
    INSERT INTO LastUnit (ProductID, ProductName, NotedDate)
    SELECT p.Id, p.Id, GETDATE()
    FROM [Products_PR] p
    INNER JOIN inserted i
    ON p.Id = i.ProductID
    WHERE p.Quantity = 1;
END;
GO
