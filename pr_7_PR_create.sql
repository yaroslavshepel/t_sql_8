USE SportStore;
GO

CREATE TABLE [Products_PR] (
    Id INT PRIMARY KEY IDENTITY(1, 1) not null,
    [ProductName] NVARCHAR(100) not null,
    [ProductType] NVARCHAR(50) not null,
    [Quantity] INT not null,
    [Cost] DECIMAL(10, 2) not null,
    [Manufacturer] NVARCHAR(100) not null,
    [SalePrice] DECIMAL(10, 2) not null
);

CREATE TABLE [Employees_PR] (
    Id INT PRIMARY KEY IDENTITY(1, 1) not null,
    [FullName] NVARCHAR(100) not null,
    [Position] NVARCHAR(50) not null,
    [HireDate] DATE not null,
    [Gender] NVARCHAR(10) not null,
    [Salary] DECIMAL(10, 2) not null
);

CREATE TABLE [Customers_PR] (
    Id INT PRIMARY KEY IDENTITY(1, 1) not null,
    [FullName] NVARCHAR(100) not null,
    [Email] NVARCHAR(100) UNIQUE not null,
    [Phone] NVARCHAR(15) not null,
    [Gender] NVARCHAR(10) not null,
    [OrderHistory] NVARCHAR(MAX) not null,
    [DiscountPercent] INT not null,
    [NewsletterSubscription] BIT not null
);

CREATE TABLE [Sales_PR] (
    Id INT PRIMARY KEY IDENTITY(1, 1) not null,
    [ProductID] INT not null,
    [SalePrice] DECIMAL(10, 2) not null,
    [Quantity] INT not null,
    [SaleDate] DATE not null,
    [EmployeeID] INT not null,
    [CustomerID] INT not null,
    FOREIGN KEY ([ProductID]) REFERENCES [Products_PR](Id),
    FOREIGN KEY ([EmployeeID]) REFERENCES [Employees_PR](Id),
    FOREIGN KEY ([CustomerID]) REFERENCES [Customers_PR](Id)
);

CREATE TABLE [SaleHistory_PR] (
    Id INT PRIMARY KEY IDENTITY(1, 1) not null,
    [SaleID] INT not null,
    [ProductID] INT not null,
    [SalePrice] DECIMAL(10, 2) not null,
    [Quantity] INT not null,
    [SaleDate] DATE not null,
    [EmployeeID] INT not null,
    [CustomerID] INT not null
);

CREATE TABLE [Archive_PR] (
    Id INT PRIMARY KEY IDENTITY(1, 1),
    [ProductID] INT not null,
    [ProductName] NVARCHAR(100) not null,
    [SaleDate] DATE not null
);

CREATE TABLE [LastUnit] (
    Id INT PRIMARY KEY IDENTITY(1, 1) not null,
    [ProductID] INT not null,
    [ProductName] NVARCHAR(100) not null,
    NotedDate DATE not null
);
