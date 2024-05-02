use SportStore
go

/*Task 1*/
/*1*/
CREATE TRIGGER trg_UpdateProductIfExists
ON [Products_PR]
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @ProductName NVARCHAR(100), @ProductType NVARCHAR(50), @Quantity INT, @Cost DECIMAL(10, 2), @Manufacturer NVARCHAR(100), @SalePrice DECIMAL(10, 2);

    SELECT @ProductName = ProductName, @ProductType = ProductType, @Quantity = Quantity, @Cost = Cost, @Manufacturer = Manufacturer, @SalePrice = SalePrice
    FROM inserted;

    IF EXISTS (
        SELECT 1
        FROM [Products_PR]
        WHERE ProductName = @ProductName
          AND ProductType = @ProductType
          AND Cost = @Cost
          AND Manufacturer = @Manufacturer
          AND SalePrice = @SalePrice
    )
    BEGIN
        UPDATE [Products_PR]
        SET Quantity = Quantity + @Quantity
        WHERE ProductName = @ProductName
          AND ProductType = @ProductType
          AND Cost = @Cost
          AND Manufacturer = @Manufacturer
          AND SalePrice = @SalePrice;
    END
    ELSE
    BEGIN
        INSERT INTO Products_PR (ProductName, ProductType, Quantity, Cost, Manufacturer, SalePrice)
        SELECT ProductName, ProductType, Quantity, Cost, Manufacturer, SalePrice
        FROM inserted;
    END
END;

/*2*/
CREATE TABLE EmployeeArchive (
    Id INT PRIMARY KEY IDENTITY(1, 1),
    FullName NVARCHAR(100),
    Position NVARCHAR(50),
    HireDate DATE,
    Gender NVARCHAR(10),
    Salary DECIMAL(10, 2)
);

CREATE TRIGGER trg_ArchiveEmployeeOnDelete
ON [Employees_PR]
FOR DELETE
AS
BEGIN
    INSERT INTO [EmployeeArchive] (FullName, Position, HireDate, Gender, Salary)
    SELECT FullName, Position, HireDate, Gender, Salary
    FROM deleted;
END;

/*3*/
CREATE TRIGGER trg_LimitSalespersonCount
ON [Employees_PR]
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @Position NVARCHAR(50);
    SELECT @Position = Position FROM inserted;

    IF (@Position = 'Salesperson' AND (SELECT COUNT(*) FROM Employees_PR WHERE Position = 'Salesperson') > 6)
    BEGIN
        RAISERROR('Maximum number of salespersons exceeded.', 16, 1);
        ROLLBACK;
    END
    ELSE
    BEGIN
        INSERT INTO [Employees_PR] (FullName, Position, HireDate, Gender, Salary)
        SELECT FullName, Position, HireDate, Gender, Salary
        FROM inserted;
    END
END;

/*Task 2*/
/*1*/
CREATE TRIGGER trg_NoDuplicateAlbum
ON [Albums_HW]
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @AlbumName NVARCHAR(100);
    SELECT @AlbumName = AlbumName FROM inserted;

    IF EXISTS (SELECT 1 FROM Albums WHERE AlbumName = @AlbumName)
    BEGIN
        RAISERROR('Album already exists.', 16, 1);
        ROLLBACK;
    END
    ELSE
    BEGIN
        INSERT INTO Albums (AlbumName, Artist, Year, Genre, Quantity)
        SELECT AlbumName, Artist, Year, Genre, Quantity
        FROM inserted;
    END
END;

/*2*/
CREATE TRIGGER trg_NoDeleteBeatles
ON Albums
FOR DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM deleted WHERE Artist = 'The Beatles')
    BEGIN
        RAISERROR('Cannot delete albums by The Beatles.', 16, 1);
        ROLLBACK;
    END
END;

/*3*/
CREATE TABLE AlbumArchive (
    Id INT PRIMARY KEY IDENTITY(1, 1),
    AlbumName NVARCHAR(100),
    Artist NVARCHAR(100),
    Year INT,
    Genre NVARCHAR(50),
    Quantity INT,
    DeletedDate DATE DEFAULT GETDATE()
);

CREATE TRIGGER trg_ArchiveDeletedAlbum
ON Albums
FOR DELETE
AS
BEGIN
    INSERT INTO AlbumArchive (AlbumName, Artist, Year, Genre, Quantity)
    SELECT AlbumName, Artist, Year, Genre, Quantity
    FROM deleted;
END;

/*4*/
CREATE TRIGGER trg_NoDarkPowerPop
ON Albums
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @Genre NVARCHAR(50);
    SELECT @Genre = Genre FROM inserted;

    IF (@Genre = 'Dark Power Pop')
    BEGIN
        RAISERROR('Cannot add albums of genre "Dark Power Pop".', 16, 1);
        ROLLBACK;
    END
    ELSE
    BEGIN
        INSERT INTO Albums (AlbumName, Artist, Year, Genre, Quantity)
        SELECT AlbumName, Artist, Year, Genre, Quantity
        FROM inserted;
    END
END;

/*Task 3*/
/*1*/
CREATE TABLE DuplicateCustomerLog (
    Id INT PRIMARY KEY IDENTITY(1, 1),
    FullName NVARCHAR(100),
    Email NVARCHAR(100),
    Phone NVARCHAR(15),
    Gender NVARCHAR(10),
    CheckedDate DATE DEFAULT GETDATE()
);
CREATE TRIGGER trg_CheckDuplicateCustomer
ON Customers
FOR INSERT
AS
BEGIN
    DECLARE @FullName NVARCHAR(100);
    SELECT @FullName = FullName FROM inserted;

    IF EXISTS (SELECT 1 FROM Customers WHERE FullName = @FullName)
    BEGIN
        INSERT INTO DuplicateCustomerLog (FullName, Email, Phone, Gender)
        SELECT FullName, Email, Phone, Gender
        FROM inserted;
    END;
END;

/*2*/
CREATE TABLE PurchaseHistory (
    Id INT PRIMARY KEY IDENTITY(1, 1),
    CustomerId INT,
    Product
	ProductName NVARCHAR(100),
    Quantity INT,
    PurchaseDate DATE
   );

   CREATE TRIGGER trg_ArchiveCustomerPurchaseHistory
   ON Customers
   FOR DELETE
   AS
   BEGIN
       INSERT INTO PurchaseHistory (CustomerId, ProductName, Quantity, PurchaseDate)
       SELECT 
           d.Id AS CustomerId, 
           p.ProductName, 
           s.Quantity, 
           s.SaleDate AS PurchaseDate
       FROM 
           deleted AS d
       JOIN 
           Sales_PR AS s
       ON 
           s.CustomerID = d.Id
       JOIN 
           Products_PR AS p
       ON 
           s.ProductID = p.Id;
   END;

/*3*/
CREATE TRIGGER trg_CheckSalespersonInCustomers
ON Employees_PR
FOR INSERT
AS
BEGIN
    DECLARE @FullName NVARCHAR(100);
    SELECT @FullName = FullName FROM inserted;

    IF EXISTS (SELECT 1 FROM Customers_PR WHERE FullName = @FullName)
    BEGIN
        RAISERROR('Salesperson already exists as a customer.', 16, 1);
        ROLLBACK;
    END;
END;

/*4*/
CREATE TRIGGER trg_CheckCustomerInSalesperson
ON Customers_PR
FOR INSERT
AS
BEGIN
    DECLARE @FullName NVARCHAR(100);
    SELECT @FullName = FullName FROM inserted;

    IF EXISTS (SELECT 1 FROM Employees_PR WHERE FullName = @FullName)
    BEGIN
        RAISERROR('Customer already exists as a salesperson.', 16, 1);
        ROLLBACK;
    END;
END;

/*5*/
CREATE TRIGGER trg_NoForbiddenProducts
ON Sales_PR
FOR INSERT
AS
BEGIN
    DECLARE @ProductName NVARCHAR(100);
    SELECT @ProductName = (SELECT p.ProductName FROM Products_PR p JOIN inserted i ON p.Id = i.ProductID);

    IF @ProductName IN ('Яблука', 'Груші', 'Сливи', 'Кінза')
    BEGIN
        RAISERROR('Cannot add sales with forbidden products.', 16, 1);
        ROLLBACK;
    END;
END;
