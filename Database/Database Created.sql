/*
    Bank Core - Database Creation Script
    Creates the BankDB database and sets up the full schema.

    Steps:
    1. Creates database (skips if exists)
    2. Runs 001_schema.sql  - Core tables
    3. Runs 002_users_roles.sql - Auth/RBAC
    4. Runs 003_educational_objects.sql - SPs, Functions, Views, Triggers
*/
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ═══════════════════════════════════════════════════════════════════
-- STEP 1: CREATE DATABASE
-- ═══════════════════════════════════════════════════════════════════
CREATE DATABASE CoreBank_E_DB;
GO

USE CoreBank_E_DB;
GO

-- ═══════════════════════════════════════════════════════════════════
-- STEP 2: RUN 001_schema.sql (Core Tables)
-- ═══════════════════════════════════════════════════════════════════
IF OBJECT_ID(N'dbo.Customers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Customers
    (
        Id                 uniqueidentifier NOT NULL CONSTRAINT PK_Customers PRIMARY KEY,
        CustomerNumber     varchar(32)       NOT NULL,
        Type               tinyint          NOT NULL,
        DisplayName        nvarchar(200)    NOT NULL,
        NationalId         varchar(20)      NULL,
        CompanyNationalId  varchar(20)      NULL,
        BirthDate          date             NULL,
        RegistrationDate   date             NULL,
        PhoneNumber        nvarchar(30)     NULL,
        Address            nvarchar(500)    NULL,
        PostalCode         varchar(20)      NULL,
        Status             tinyint          NOT NULL CONSTRAINT DF_Customers_Status DEFAULT (1),
        RiskLevel          tinyint          NOT NULL CONSTRAINT DF_Customers_RiskLevel DEFAULT (1),
        CreatedAtUtc       datetime2(3)     NOT NULL CONSTRAINT DF_Customers_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAtUtc       datetime2(3)     NOT NULL CONSTRAINT DF_Customers_UpdatedAt DEFAULT (SYSUTCDATETIME()),
        RowVersion         rowversion       NOT NULL,
        CONSTRAINT UQ_Customers_CustomerNumber UNIQUE (CustomerNumber),
        CONSTRAINT CK_Customers_Type CHECK (Type IN (1, 2)),
        CONSTRAINT CK_Customers_Status CHECK (Status IN (1, 2, 3)),
        CONSTRAINT CK_Customers_RiskLevel CHECK (RiskLevel IN (1, 2, 3)),
        CONSTRAINT CK_Customers_Identity CHECK
            ((Type = 1 AND NationalId IS NOT NULL AND CompanyNationalId IS NULL)
             OR (Type = 2 AND CompanyNationalId IS NOT NULL AND NationalId IS NULL))
    );
    PRINT N'  + Customers table created.';
END;
ELSE
    PRINT N'  - Customers table exists.';
GO

IF OBJECT_ID(N'dbo.Accounts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Accounts
    (
        Id             uniqueidentifier NOT NULL CONSTRAINT PK_Accounts PRIMARY KEY,
        CustomerId     uniqueidentifier NOT NULL,
        AccountNumber  varchar(32)       NOT NULL,
        Iban           varchar(34)       NOT NULL,
        CardNumber     varchar(16)       NULL,
        Type           tinyint          NOT NULL,
        Status         tinyint          NOT NULL CONSTRAINT DF_Accounts_Status DEFAULT (1),
        Balance        decimal(19,4)     NOT NULL CONSTRAINT DF_Accounts_Balance DEFAULT (0),
        MinimumBalance decimal(19,4)     NOT NULL CONSTRAINT DF_Accounts_MinimumBalance DEFAULT (0),
        Version        bigint            NOT NULL CONSTRAINT DF_Accounts_Version DEFAULT (0),
        OpenedAtUtc    datetime2(3)     NOT NULL CONSTRAINT DF_Accounts_OpenedAt DEFAULT (SYSUTCDATETIME()),
        ClosedAtUtc    datetime2(3)     NULL,
        RowVersion     rowversion       NOT NULL,
        CONSTRAINT FK_Accounts_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers(Id),
        CONSTRAINT UQ_Accounts_AccountNumber UNIQUE (AccountNumber),
        CONSTRAINT UQ_Accounts_Iban UNIQUE (Iban),
        CONSTRAINT CK_Accounts_Type CHECK (Type IN (1, 2, 3, 4)),
        CONSTRAINT CK_Accounts_Status CHECK (Status IN (1, 2, 3, 4)),
        CONSTRAINT CK_Accounts_Balance CHECK (Balance >= 0),
        CONSTRAINT CK_Accounts_MinimumBalance CHECK (MinimumBalance >= 0),
        CONSTRAINT CK_Accounts_Version CHECK (Version >= 0),
        CONSTRAINT CK_Accounts_ClosedDate CHECK (Status <> 4 OR ClosedAtUtc IS NOT NULL)
    );
    PRINT N'  + Accounts table created.';
END;
ELSE
    PRINT N'  - Accounts table exists.';
GO

IF OBJECT_ID(N'dbo.BankTransactions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BankTransactions
    (
        Id                    uniqueidentifier NOT NULL CONSTRAINT PK_BankTransactions PRIMARY KEY,
        Reference             varchar(64)       NOT NULL,
        Type                  tinyint          NOT NULL,
        SourceAccountId       uniqueidentifier NULL,
        DestinationAccountId  uniqueidentifier NULL,
        Amount                decimal(19,4)     NOT NULL,
        Fee                   decimal(19,4)     NOT NULL CONSTRAINT DF_BankTransactions_Fee DEFAULT (0),
        Status                tinyint          NOT NULL CONSTRAINT DF_BankTransactions_Status DEFAULT (1),
        Description           nvarchar(500)    NOT NULL,
        CreatedAtUtc          datetime2(3)     NOT NULL CONSTRAINT DF_BankTransactions_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CompletedAtUtc        datetime2(3)     NULL,
        ReversedTransactionId uniqueidentifier NULL,
        CONSTRAINT UQ_BankTransactions_Reference UNIQUE (Reference),
        CONSTRAINT FK_BankTransactions_SourceAccount FOREIGN KEY (SourceAccountId) REFERENCES dbo.Accounts(Id),
        CONSTRAINT FK_BankTransactions_DestinationAccount FOREIGN KEY (DestinationAccountId) REFERENCES dbo.Accounts(Id),
        CONSTRAINT FK_BankTransactions_Reversal FOREIGN KEY (ReversedTransactionId) REFERENCES dbo.BankTransactions(Id),
        CONSTRAINT CK_BankTransactions_Type CHECK (Type BETWEEN 1 AND 9),
        CONSTRAINT CK_BankTransactions_Status CHECK (Status BETWEEN 1 AND 4),
        CONSTRAINT CK_BankTransactions_Amount CHECK (Amount > 0),
        CONSTRAINT CK_BankTransactions_Fee CHECK (Fee >= 0),
        CONSTRAINT CK_BankTransactions_Accounts CHECK
            (SourceAccountId IS NULL OR DestinationAccountId IS NULL OR SourceAccountId <> DestinationAccountId)
    );
    PRINT N'  + BankTransactions table created.';
END;
ELSE
    PRINT N'  - BankTransactions table exists.';
GO

IF OBJECT_ID(N'dbo.JournalEntries', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.JournalEntries
    (
        Id            uniqueidentifier NOT NULL CONSTRAINT PK_JournalEntries PRIMARY KEY,
        TransactionId uniqueidentifier NOT NULL,
        Description   nvarchar(500)    NOT NULL,
        EntryDateUtc  datetime2(3)     NOT NULL CONSTRAINT DF_JournalEntries_EntryDate DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT UQ_JournalEntries_Transaction UNIQUE (TransactionId),
        CONSTRAINT FK_JournalEntries_Transaction FOREIGN KEY (TransactionId) REFERENCES dbo.BankTransactions(Id)
    );
    PRINT N'  + JournalEntries table created.';
END;
ELSE
    PRINT N'  - JournalEntries table exists.';
GO

IF OBJECT_ID(N'dbo.JournalLines', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.JournalLines
    (
        Id                uniqueidentifier NOT NULL CONSTRAINT PK_JournalLines PRIMARY KEY,
        JournalEntryId    uniqueidentifier NOT NULL,
        AccountId         uniqueidentifier NULL,
        LedgerAccountCode varchar(50)       NOT NULL,
        Debit             decimal(19,4)     NOT NULL CONSTRAINT DF_JournalLines_Debit DEFAULT (0),
        Credit            decimal(19,4)     NOT NULL CONSTRAINT DF_JournalLines_Credit DEFAULT (0),
        Description       nvarchar(500)    NOT NULL,
        CONSTRAINT FK_JournalLines_Entry FOREIGN KEY (JournalEntryId) REFERENCES dbo.JournalEntries(Id),
        CONSTRAINT FK_JournalLines_Account FOREIGN KEY (AccountId) REFERENCES dbo.Accounts(Id),
        CONSTRAINT CK_JournalLines_Amounts CHECK
            ((Debit > 0 AND Credit = 0) OR (Credit > 0 AND Debit = 0))
    );
    PRINT N'  + JournalLines table created.';
END;
ELSE
    PRINT N'  - JournalLines table exists.';
GO

IF OBJECT_ID(N'dbo.LedgerAccounts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LedgerAccounts
    (
        Code        varchar(50)    NOT NULL CONSTRAINT PK_LedgerAccounts PRIMARY KEY,
        Name        nvarchar(200)  NOT NULL,
        Category    varchar(30)    NOT NULL,
        IsActive    bit            NOT NULL CONSTRAINT DF_LedgerAccounts_IsActive DEFAULT (1),
        CreatedAtUtc datetime2(3)  NOT NULL CONSTRAINT DF_LedgerAccounts_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT CK_LedgerAccounts_Category CHECK (Category IN ('ASSET', 'LIABILITY', 'EQUITY', 'INCOME', 'EXPENSE'))
    );
    PRINT N'  + LedgerAccounts table created.';
END;
ELSE
    PRINT N'  - LedgerAccounts table exists.';
GO

IF OBJECT_ID(N'dbo.AuditLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AuditLogs
    (
        Id            uniqueidentifier NOT NULL CONSTRAINT PK_AuditLogs PRIMARY KEY,
        Action        nvarchar(100)    NOT NULL,
        EntityType    nvarchar(100)    NOT NULL,
        EntityId      uniqueidentifier NULL,
        Details       nvarchar(max)    NULL,
        OccurredAtUtc datetime2(3)     NOT NULL CONSTRAINT DF_AuditLogs_OccurredAt DEFAULT (SYSUTCDATETIME()),
        MachineName   nvarchar(128)    NULL,
        UserName      nvarchar(256)    NULL
    );
    PRINT N'  + AuditLogs table created.';
END;
ELSE
    PRINT N'  - AuditLogs table exists.';
GO

IF OBJECT_ID(N'dbo.Loans', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Loans
    (
        Id              uniqueidentifier NOT NULL CONSTRAINT PK_Loans PRIMARY KEY,
        CustomerId      uniqueidentifier NOT NULL,
        Principal       decimal(19,4)     NOT NULL,
        AnnualRate      decimal(9,6)      NOT NULL,
        TermMonths      int              NOT NULL,
        Status          tinyint          NOT NULL CONSTRAINT DF_Loans_Status DEFAULT (1),
        RequestedAtUtc  datetime2(3)     NOT NULL CONSTRAINT DF_Loans_RequestedAt DEFAULT (SYSUTCDATETIME()),
        ApprovedAtUtc   datetime2(3)     NULL,
        CONSTRAINT FK_Loans_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers(Id),
        CONSTRAINT CK_Loans_Principal CHECK (Principal > 0),
        CONSTRAINT CK_Loans_AnnualRate CHECK (AnnualRate >= 0),
        CONSTRAINT CK_Loans_Term CHECK (TermMonths BETWEEN 1 AND 120)
    );
    PRINT N'  + Loans table created.';
END;
ELSE
    PRINT N'  - Loans table exists.';
GO

IF OBJECT_ID(N'dbo.Cheques', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Cheques
    (
        Id             uniqueidentifier NOT NULL CONSTRAINT PK_Cheques PRIMARY KEY,
        AccountId      uniqueidentifier NOT NULL,
        SerialNumber   varchar(32)       NOT NULL,
        SayadIdentifier varchar(32)       NULL,
        Amount         decimal(19,4)     NOT NULL,
        Status         tinyint          NOT NULL CONSTRAINT DF_Cheques_Status DEFAULT (1),
        IssueDate      date             NOT NULL,
        DueDate        date             NULL,
        CreatedAtUtc   datetime2(3)     NOT NULL CONSTRAINT DF_Cheques_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_Cheques_Accounts FOREIGN KEY (AccountId) REFERENCES dbo.Accounts(Id),
        CONSTRAINT UQ_Cheques_Serial UNIQUE (SerialNumber),
        CONSTRAINT CK_Cheques_Amount CHECK (Amount > 0),
        CONSTRAINT CK_Cheques_Status CHECK (Status BETWEEN 1 AND 5)
    );
    PRINT N'  + Cheques table created.';
END;
ELSE
    PRINT N'  - Cheques table exists.';
GO

/* Indexes for 001 */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Customers_NationalId' AND object_id = OBJECT_ID(N'dbo.Customers'))
    CREATE UNIQUE INDEX UX_Customers_NationalId ON dbo.Customers(NationalId) WHERE NationalId IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Customers_CompanyNationalId' AND object_id = OBJECT_ID(N'dbo.Customers'))
    CREATE UNIQUE INDEX UX_Customers_CompanyNationalId ON dbo.Customers(CompanyNationalId) WHERE CompanyNationalId IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Accounts_CustomerId' AND object_id = OBJECT_ID(N'dbo.Accounts'))
    CREATE INDEX IX_Accounts_CustomerId ON dbo.Accounts(CustomerId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Accounts_CardNumber' AND object_id = OBJECT_ID(N'dbo.Accounts'))
    CREATE UNIQUE INDEX UX_Accounts_CardNumber ON dbo.Accounts(CardNumber) WHERE CardNumber IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BankTransactions_CreatedAtUtc' AND object_id = OBJECT_ID(N'dbo.BankTransactions'))
    CREATE INDEX IX_BankTransactions_CreatedAtUtc ON dbo.BankTransactions(CreatedAtUtc DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BankTransactions_Accounts' AND object_id = OBJECT_ID(N'dbo.BankTransactions'))
    CREATE INDEX IX_BankTransactions_Accounts ON dbo.BankTransactions(SourceAccountId, DestinationAccountId, CreatedAtUtc DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AuditLogs_OccurredAtUtc' AND object_id = OBJECT_ID(N'dbo.AuditLogs'))
    CREATE INDEX IX_AuditLogs_OccurredAtUtc ON dbo.AuditLogs(OccurredAtUtc DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_Cheques_SayadIdentifier' AND object_id = OBJECT_ID(N'dbo.Cheques'))
    CREATE UNIQUE INDEX UX_Cheques_SayadIdentifier ON dbo.Cheques(SayadIdentifier) WHERE SayadIdentifier IS NOT NULL;
GO

/* Seed LedgerAccounts */
MERGE dbo.LedgerAccounts AS target
USING (VALUES
    ('CASH-VAULT',       N'Cash vault',                    'ASSET'),
    ('BANK-RESERVE',     N'Central bank reserve',           'ASSET'),
    ('CUSTOMER-DEPOSIT', N'Customer deposits',              'LIABILITY'),
    ('LOAN-RECEIVABLE',  N'Loans receivable',               'ASSET'),
    ('FEE-INCOME',       N'Fee income',                    'INCOME'),
    ('INTEREST-INCOME',  N'Interest income',                'INCOME'),
    ('OPERATING-EXPENSE',N'Operating expenses',             'EXPENSE'),
    ('EQUITY-CAPITAL',   N'Bank equity capital',             'EQUITY')
) AS source(Code, Name, Category)
ON target.Code = source.Code
WHEN MATCHED THEN
    UPDATE SET Name = source.Name, Category = source.Category, IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (Code, Name, Category) VALUES (source.Code, source.Name, source.Category);
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = N'FK_JournalLines_LedgerAccount'
      AND parent_object_id = OBJECT_ID(N'dbo.JournalLines')
)
BEGIN
    ALTER TABLE dbo.JournalLines
        ADD CONSTRAINT FK_JournalLines_LedgerAccount
        FOREIGN KEY (LedgerAccountCode) REFERENCES dbo.LedgerAccounts(Code);
END;
GO

CREATE OR ALTER VIEW dbo.vw_UnbalancedJournalEntries
AS
SELECT
    e.Id,
    e.TransactionId,
    e.EntryDateUtc,
    COALESCE(SUM(l.Debit), 0) AS TotalDebit,
    COALESCE(SUM(l.Credit), 0) AS TotalCredit,
    COALESCE(SUM(l.Debit), 0) - COALESCE(SUM(l.Credit), 0) AS Difference
FROM dbo.JournalEntries AS e
LEFT JOIN dbo.JournalLines AS l ON l.JournalEntryId = e.Id
GROUP BY e.Id, e.TransactionId, e.EntryDateUtc
HAVING COALESCE(SUM(l.Debit), 0) <> COALESCE(SUM(l.Credit), 0);
GO

PRINT N'[1/3] Core tables completed.';
GO

-- ═══════════════════════════════════════════════════════════════════
-- STEP 3: RUN 002_users_roles.sql (Auth & RBAC)
-- ═══════════════════════════════════════════════════════════════════

IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Users
    (
        Id               uniqueidentifier NOT NULL CONSTRAINT PK_Users PRIMARY KEY,
        Username         varchar(50)       NOT NULL,
        PasswordHash     varbinary(64)     NOT NULL,
        PasswordSalt     varbinary(128)    NOT NULL,
        DisplayName      nvarchar(200)    NOT NULL,
        Email            nvarchar(256)    NULL,
        PhoneNumber      nvarchar(30)     NULL,
        IsActive         bit              NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT (1),
        IsLockedOut      bit              NOT NULL CONSTRAINT DF_Users_IsLockedOut DEFAULT (0),
        FailedAttempts   int              NOT NULL CONSTRAINT DF_Users_FailedAttempts DEFAULT (0),
        LockoutEndUtc    datetime2(3)     NULL,
        LastLoginUtc     datetime2(3)     NULL,
        CreatedAtUtc     datetime2(3)     NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAtUtc     datetime2(3)     NOT NULL CONSTRAINT DF_Users_UpdatedAt DEFAULT (SYSUTCDATETIME()),
        RowVersion       rowversion       NOT NULL,
        CONSTRAINT UQ_Users_Username UNIQUE (Username),
        CONSTRAINT CK_Users_FailedAttempts CHECK (FailedAttempts >= 0)
    );
    PRINT N'  + Users table created.';
END;
ELSE
    PRINT N'  - Users table exists.';
GO

IF OBJECT_ID(N'dbo.Roles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Roles
    (
        Id          uniqueidentifier NOT NULL CONSTRAINT PK_Roles PRIMARY KEY,
        Name        varchar(50)       NOT NULL,
        Description nvarchar(500)    NULL,
        IsSystem    bit              NOT NULL CONSTRAINT DF_Roles_IsSystem DEFAULT (0),
        CreatedAtUtc datetime2(3)    NOT NULL CONSTRAINT DF_Roles_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT UQ_Roles_Name UNIQUE (Name)
    );
    PRINT N'  + Roles table created.';
END;
ELSE
    PRINT N'  - Roles table exists.';
GO

IF OBJECT_ID(N'dbo.Permissions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Permissions
    (
        Id          uniqueidentifier NOT NULL CONSTRAINT PK_Permissions PRIMARY KEY,
        Code        varchar(100)      NOT NULL,
        Name        nvarchar(200)    NOT NULL,
        Category    nvarchar(100)    NOT NULL,
        Description nvarchar(500)    NULL,
        CONSTRAINT UQ_Permissions_Code UNIQUE (Code)
    );
    PRINT N'  + Permissions table created.';
END;
ELSE
    PRINT N'  - Permissions table exists.';
GO

IF OBJECT_ID(N'dbo.UserRoles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserRoles
    (
        UserId    uniqueidentifier NOT NULL,
        RoleId    uniqueidentifier NOT NULL,
        CONSTRAINT PK_UserRoles PRIMARY KEY (UserId, RoleId),
        CONSTRAINT FK_UserRoles_User FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE CASCADE,
        CONSTRAINT FK_UserRoles_Role FOREIGN KEY (RoleId) REFERENCES dbo.Roles(Id) ON DELETE CASCADE
    );
    PRINT N'  + UserRoles table created.';
END;
ELSE
    PRINT N'  - UserRoles table exists.';
GO

IF OBJECT_ID(N'dbo.RolePermissions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RolePermissions
    (
        RoleId       uniqueidentifier NOT NULL,
        PermissionId uniqueidentifier NOT NULL,
        CONSTRAINT PK_RolePermissions PRIMARY KEY (RoleId, PermissionId),
        CONSTRAINT FK_RolePermissions_Role FOREIGN KEY (RoleId) REFERENCES dbo.Roles(Id) ON DELETE CASCADE,
        CONSTRAINT FK_RolePermissions_Permission FOREIGN KEY (PermissionId) REFERENCES dbo.Permissions(Id) ON DELETE CASCADE
    );
    PRINT N'  + RolePermissions table created.';
END;
ELSE
    PRINT N'  - RolePermissions table exists.';
GO

IF OBJECT_ID(N'dbo.LoginHistory', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LoginHistory
    (
        Id            uniqueidentifier NOT NULL CONSTRAINT PK_LoginHistory PRIMARY KEY,
        UserId        uniqueidentifier NOT NULL,
        Username      varchar(50)       NOT NULL,
        IsSuccess     bit              NOT NULL,
        FailureReason nvarchar(500)    NULL,
        IpAddress     nvarchar(45)     NULL,
        MachineName   nvarchar(128)    NULL,
        AttemptedAtUtc datetime2(3)    NOT NULL CONSTRAINT DF_LoginHistory_AttemptedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_LoginHistory_User FOREIGN KEY (UserId) REFERENCES dbo.Users(Id)
    );
    PRINT N'  + LoginHistory table created.';
END;
ELSE
    PRINT N'  - LoginHistory table exists.';
GO

IF OBJECT_ID(N'dbo.UserSessions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserSessions
    (
        Id           uniqueidentifier NOT NULL CONSTRAINT PK_UserSessions PRIMARY KEY,
        UserId       uniqueidentifier NOT NULL,
        Token        varchar(128)      NOT NULL,
        ExpiresAtUtc datetime2(3)     NOT NULL,
        CreatedAtUtc datetime2(3)     NOT NULL CONSTRAINT DF_UserSessions_CreatedAt DEFAULT (SYSUTCDATETIME()),
        RevokedAtUtc datetime2(3)     NULL,
        CONSTRAINT FK_UserSessions_User FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE CASCADE,
        CONSTRAINT UQ_UserSessions_Token UNIQUE (Token)
    );
    PRINT N'  + UserSessions table created.';
END;
ELSE
    PRINT N'  - UserSessions table exists.';
GO

/* Indexes for 002 */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserRoles_RoleId' AND object_id = OBJECT_ID(N'dbo.UserRoles'))
    CREATE INDEX IX_UserRoles_RoleId ON dbo.UserRoles(RoleId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_RolePermissions_PermissionId' AND object_id = OBJECT_ID(N'dbo.RolePermissions'))
    CREATE INDEX IX_RolePermissions_PermissionId ON dbo.RolePermissions(PermissionId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_LoginHistory_UserId' AND object_id = OBJECT_ID(N'dbo.LoginHistory'))
    CREATE INDEX IX_LoginHistory_UserId ON dbo.LoginHistory(UserId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_LoginHistory_AttemptedAt' AND object_id = OBJECT_ID(N'dbo.LoginHistory'))
    CREATE INDEX IX_LoginHistory_AttemptedAt ON dbo.LoginHistory(AttemptedAtUtc DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserSessions_UserId' AND object_id = OBJECT_ID(N'dbo.UserSessions'))
    CREATE INDEX IX_UserSessions_UserId ON dbo.UserSessions(UserId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserSessions_Token' AND object_id = OBJECT_ID(N'dbo.UserSessions'))
    CREATE INDEX IX_UserSessions_Token ON dbo.UserSessions(Token);
GO

/* Seed Roles */
MERGE dbo.Roles AS target
USING (VALUES
    ('Admin',        N'Administrator - Full access',           1),
    ('Manager',      N'Branch Manager - Operational access',   1),
    ('Teller',       N'Bank Teller - Transaction access',      1),
    ('Viewer',       N'Read-only Viewer',                      1),
    ('Auditor',      N'Audit & Compliance - View reports only',1)
) AS source(Name, Description, IsSystem)
ON target.Name = source.Name
WHEN MATCHED THEN
    UPDATE SET Description = source.Description, IsSystem = source.IsSystem
WHEN NOT MATCHED THEN
    INSERT (Id, Name, Description, IsSystem) VALUES (NEWID(), source.Name, source.Description, source.IsSystem);
GO

/* Seed Permissions */
MERGE dbo.Permissions AS target
USING (VALUES
    ('Customers.View',          N'View Customers',           'Customer Management',  N'View customer list and details'),
    ('Customers.Register',      N'Register Customer',        'Customer Management',  N'Register new individual or legal customer'),
    ('Customers.Edit',          N'Edit Customer',            'Customer Management',  N'Edit customer contact info'),
    ('Customers.Suspend',       N'Suspend Customer',         'Customer Management',  N'Change customer status to suspended'),
    ('Accounts.View',           N'View Accounts',            'Account Management',   N'View account list and details'),
    ('Accounts.Open',           N'Open Account',             'Account Management',   N'Open new account for customer'),
    ('Accounts.Freeze',         N'Freeze Account',           'Account Management',   N'Freeze an account'),
    ('Accounts.Close',          N'Close Account',            'Account Management',   N'Close an account'),
    ('Transactions.View',       N'View Transactions',        'Transaction Operations', N'View transaction history'),
    ('Transactions.Deposit',    N'Deposit',                  'Transaction Operations', N'Perform deposit operations'),
    ('Transactions.Withdraw',   N'Withdraw',                 'Transaction Operations', N'Perform withdrawal operations'),
    ('Transactions.Transfer',   N'Transfer',                 'Transaction Operations', N'Perform internal transfers'),
    ('Reports.Dashboard',       N'View Dashboard',           'Reports & Analytics',  N'View dashboard metrics'),
    ('Reports.AuditLog',        N'View Audit Log',           'Reports & Analytics',  N'View audit trail'),
    ('Reports.Financial',       N'Financial Reports',        'Reports & Analytics',  N'View financial reports'),
    ('Admin.Users',             N'Manage Users',             'Administration',       N'Create, edit, delete users'),
    ('Admin.Roles',             N'Manage Roles',             'Administration',       N'Create, edit, delete roles and permissions'),
    ('Admin.System',            N'System Settings',          'Administration',       N'System configuration')
) AS source(Code, Name, Category, Description)
ON target.Code = source.Code
WHEN MATCHED THEN
    UPDATE SET Name = source.Name, Category = source.Category, Description = source.Description
WHEN NOT MATCHED THEN
    INSERT (Id, Code, Name, Category, Description) VALUES (NEWID(), source.Code, source.Name, source.Category, source.Description);
GO

/* Assign permissions to roles */
INSERT INTO dbo.RolePermissions (RoleId, PermissionId)
SELECT r.Id, p.Id
FROM dbo.Roles r
CROSS JOIN dbo.Permissions p
WHERE r.Name = 'Admin'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolePermissions rp WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id
  );
GO

INSERT INTO dbo.RolePermissions (RoleId, PermissionId)
SELECT r.Id, p.Id
FROM dbo.Roles r
CROSS JOIN dbo.Permissions p
WHERE r.Name = 'Teller'
  AND p.Code IN ('Customers.View', 'Customers.Register', 'Accounts.View', 'Accounts.Open',
                  'Transactions.View', 'Transactions.Deposit', 'Transactions.Withdraw', 'Transactions.Transfer',
                  'Reports.Dashboard')
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolePermissions rp WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id
  );
GO

INSERT INTO dbo.RolePermissions (RoleId, PermissionId)
SELECT r.Id, p.Id
FROM dbo.Roles r
CROSS JOIN dbo.Permissions p
WHERE r.Name = 'Manager'
  AND p.Code IN ('Customers.View', 'Customers.Register', 'Customers.Edit', 'Customers.Suspend',
                  'Accounts.View', 'Accounts.Open', 'Accounts.Freeze', 'Accounts.Close',
                  'Transactions.View', 'Transactions.Deposit', 'Transactions.Withdraw', 'Transactions.Transfer',
                  'Reports.Dashboard', 'Reports.AuditLog', 'Reports.Financial')
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolePermissions rp WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id
  );
GO

INSERT INTO dbo.RolePermissions (RoleId, PermissionId)
SELECT r.Id, p.Id
FROM dbo.Roles r
CROSS JOIN dbo.Permissions p
WHERE r.Name = 'Viewer'
  AND p.Code IN ('Customers.View', 'Accounts.View', 'Transactions.View', 'Reports.Dashboard')
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolePermissions rp WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id
  );
GO

INSERT INTO dbo.RolePermissions (RoleId, PermissionId)
SELECT r.Id, p.Id
FROM dbo.Roles r
CROSS JOIN dbo.Permissions p
WHERE r.Name = 'Auditor'
  AND p.Code IN ('Customers.View', 'Accounts.View', 'Transactions.View',
                  'Reports.Dashboard', 'Reports.AuditLog', 'Reports.Financial')
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolePermissions rp WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id
  );
GO

/* ═══════════════════════════════════════════════════════════════════
   FINE-GRAINED UI POLICIES (Hierarchical via dot notation)
   ═══════════════════════════════════════════════════════════════════ */
MERGE dbo.Permissions AS target
USING (VALUES
    ('Dashboard.View',                 N'Dashboard Page',              'Dashboard',              N'View dashboard tab'),
    ('Dashboard.Cards.View',           N'Dashboard Cards',             'Dashboard',              N'View metric cards'),
    ('Dashboard.QuickActions.View',    N'Dashboard Quick Actions',     'Dashboard',              N'View quick action buttons'),
    ('Customers.Page.View',            N'Customers Page',              'Customers UI',           N'View customers tab'),
    ('Customers.Grid.View',            N'Customers Grid',              'Customers UI',           N'View customers grid'),
    ('Customers.Search.View',          N'Customers Search',            'Customers UI',           N'View and use search box'),
    ('Customers.Button.RegisterIndividual', N'Register Individual Btn', 'Customers UI',         N'Register individual customer button'),
    ('Customers.Button.RegisterLegal', N'Register Legal Btn',          'Customers UI',           N'Register legal customer button'),
    ('Customers.Button.Edit',          N'Edit Customer Btn',           'Customers UI',           N'Edit customer contact'),
    ('Customers.Button.ChangeStatus',  N'Change Status Btn',           'Customers UI',           N'Change customer status'),
    ('Customers.Context.Detail',       N'Customer Detail Context',     'Customers UI',           N'Context menu - detail'),
    ('Customers.Context.Copy',         N'Copy Customer Code Context',  'Customers UI',           N'Context menu - copy code'),
    ('Customers.Action.OpenAccount',   N'Open Account Action',         'Customers UI',           N'Open account for selected customer'),
    ('Accounts.Page.View',             N'Accounts Page',               'Accounts UI',            N'View accounts tab'),
    ('Accounts.Grid.View',             N'Accounts Grid',               'Accounts UI',            N'View accounts grid'),
    ('Accounts.Button.Open',           N'Open Account Btn',            'Accounts UI',            N'Open account button'),
    ('Accounts.Button.Freeze',         N'Freeze Account Btn',          'Accounts UI',            N'Freeze account button'),
    ('Accounts.Button.Unfreeze',       N'Unfreeze Account Btn',        'Accounts UI',            N'Unfreeze account button'),
    ('Accounts.Button.Close',          N'Close Account Btn',           'Accounts UI',            N'Close account button'),
    ('Accounts.Context.CopyNumber',    N'Copy Account Number',         'Accounts UI',            N'Context - copy account number'),
    ('Accounts.Context.CopyIban',      N'Copy IBAN',                   'Accounts UI',            N'Context - copy IBAN'),
    ('Accounts.Context.Deposit',       N'Context Deposit',             'Accounts UI',            N'Context - deposit to account'),
    ('Accounts.Context.Withdraw',      N'Context Withdraw',            'Accounts UI',            N'Context - withdraw from account'),
    ('Accounts.Context.Transfer',      N'Context Transfer',            'Accounts UI',            N'Context - transfer from account'),
    ('Transactions.Page.View',         N'Transactions Page',           'Transactions UI',        N'View transactions tab'),
    ('Transactions.Ops.Deposit',       N'Deposit Operation',           'Transactions UI',        N'Deposit button/card'),
    ('Transactions.Ops.Withdraw',      N'Withdraw Operation',          'Transactions UI',        N'Withdraw button/card'),
    ('Transactions.Ops.Transfer',      N'Transfer Operation',          'Transactions UI',        N'Transfer button/card'),
    ('Transactions.Ops.Statement',     N'Statement Operation',         'Transactions UI',        N'Statement button/card'),
    ('Transactions.Filter.View',       N'Transaction Filter',          'Transactions UI',        N'View and use filter panel'),
    ('Transactions.Grid.View',         N'Transactions Grid',           'Transactions UI',        N'View transactions grid'),
    ('Transactions.Action.Receipt',    N'Receipt Action',              'Transactions UI',        N'Receipt button'),
    ('Transactions.Action.Reverse',    N'Reverse Action',              'Transactions UI',        N'Reverse transaction button'),
    ('Transactions.Context.Receipt',   N'Context Receipt',             'Transactions UI',        N'Context menu - receipt'),
    ('Transactions.Context.Reverse',   N'Context Reverse',             'Transactions UI',        N'Context menu - reverse'),
    ('Reports.Page.View',              N'Reports Page',                'Reports',                N'View reports tab'),
    ('Reports.Daily.View',             N'Daily Report',                'Reports',                N'View daily report grid'),
    ('Audit.Page.View',                N'Audit Page',                  'Audit',                  N'View audit tab'),
    ('Audit.LoginHistory.View',        N'Login History',               'Audit',                  N'View login history grid'),
    ('Admin.Page.View',                N'Admin Page',                  'Administration',         N'View admin tab')
) AS source(Code, Name, Category, Description)
ON target.Code = source.Code
WHEN MATCHED THEN UPDATE SET Name = source.Name, Category = source.Category, Description = source.Description
WHEN NOT MATCHED THEN INSERT (Id, Code, Name, Category, Description) VALUES (NEWID(), source.Code, source.Name, source.Category, source.Description);
GO
INSERT INTO dbo.RolePermissions (RoleId, PermissionId)
SELECT r.Id, p.Id FROM dbo.Roles r CROSS JOIN dbo.Permissions p
WHERE r.Name = 'Admin' AND (p.Code LIKE '%.View' OR p.Code LIKE '%.Button.%' OR p.Code LIKE '%.Context.%' OR p.Code LIKE '%.Action.%' OR p.Code LIKE '%.Ops.%' OR p.Code LIKE '%.Filter.%' OR p.Code LIKE '%.Grid.%' OR p.Code LIKE '%Dashboard%' OR p.Code LIKE '%Audit%' OR p.Code LIKE '%Reports%')
AND NOT EXISTS (SELECT 1 FROM dbo.RolePermissions rp WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id);
GO
INSERT INTO dbo.RolePermissions (RoleId, PermissionId)
SELECT r.Id, p.Id FROM dbo.Roles r CROSS JOIN dbo.Permissions p
WHERE r.Name = 'Teller' AND p.Code IN ('Dashboard.View','Dashboard.Cards.View','Dashboard.QuickActions.View','Customers.Page.View','Customers.Grid.View','Customers.Search.View','Customers.Button.RegisterIndividual','Customers.Button.RegisterLegal','Accounts.Page.View','Accounts.Grid.View','Accounts.Button.Open','Transactions.Page.View','Transactions.Ops.Deposit','Transactions.Ops.Withdraw','Transactions.Ops.Transfer','Transactions.Filter.View','Transactions.Grid.View','Reports.Page.View','Reports.Daily.View')
AND NOT EXISTS (SELECT 1 FROM dbo.RolePermissions rp WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id);
GO
INSERT INTO dbo.RolePermissions (RoleId, PermissionId)
SELECT r.Id, p.Id FROM dbo.Roles r CROSS JOIN dbo.Permissions p
WHERE r.Name = 'Manager' AND p.Code IN ('Dashboard.View','Dashboard.Cards.View','Dashboard.QuickActions.View','Customers.Page.View','Customers.Grid.View','Customers.Search.View','Customers.Button.RegisterIndividual','Customers.Button.RegisterLegal','Customers.Button.Edit','Customers.Button.ChangeStatus','Accounts.Page.View','Accounts.Grid.View','Accounts.Button.Open','Accounts.Button.Freeze','Accounts.Button.Unfreeze','Transactions.Page.View','Transactions.Ops.Deposit','Transactions.Ops.Withdraw','Transactions.Ops.Transfer','Transactions.Filter.View','Transactions.Grid.View','Transactions.Action.Receipt','Reports.Page.View','Reports.Daily.View','Audit.Page.View','Audit.LoginHistory.View')
AND NOT EXISTS (SELECT 1 FROM dbo.RolePermissions rp WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id);
GO
INSERT INTO dbo.RolePermissions (RoleId, PermissionId)
SELECT r.Id, p.Id FROM dbo.Roles r CROSS JOIN dbo.Permissions p
WHERE r.Name = 'Viewer' AND p.Code IN ('Dashboard.View','Dashboard.Cards.View','Customers.Page.View','Customers.Grid.View','Customers.Search.View','Accounts.Page.View','Accounts.Grid.View','Transactions.Page.View','Transactions.Grid.View','Reports.Page.View')
AND NOT EXISTS (SELECT 1 FROM dbo.RolePermissions rp WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id);
GO
INSERT INTO dbo.RolePermissions (RoleId, PermissionId)
SELECT r.Id, p.Id FROM dbo.Roles r CROSS JOIN dbo.Permissions p
WHERE r.Name = 'Auditor' AND p.Code IN ('Dashboard.View','Customers.Page.View','Customers.Grid.View','Accounts.Page.View','Accounts.Grid.View','Transactions.Page.View','Transactions.Grid.View','Reports.Page.View','Reports.Daily.View','Audit.Page.View','Audit.LoginHistory.View')
AND NOT EXISTS (SELECT 1 FROM dbo.RolePermissions rp WHERE rp.RoleId = r.Id AND rp.PermissionId = p.Id);
GO

/* No default admin user — first admin is created via application bootstrap (first-run registration). */
PRINT N'  - No default admin user (bootstrap required on first launch).';
GO

/* Helper views */
CREATE OR ALTER VIEW dbo.vw_UserRoles
AS
SELECT
    u.Id,
    u.Username,
    u.DisplayName,
    u.Email,
    u.IsActive,
    u.IsLockedOut,
    u.LastLoginUtc,
    u.CreatedAtUtc,
    STRING_AGG(r.Name, ', ') WITHIN GROUP (ORDER BY r.Name) AS RoleNames
FROM dbo.Users u
LEFT JOIN dbo.UserRoles ur ON ur.UserId = u.Id
LEFT JOIN dbo.Roles r ON r.Id = ur.RoleId
GROUP BY u.Id, u.Username, u.DisplayName, u.Email, u.IsActive, u.IsLockedOut, u.LastLoginUtc, u.CreatedAtUtc;
GO

CREATE OR ALTER VIEW dbo.vw_RolePermissions
AS
SELECT
    r.Id,
    r.Name,
    r.Description,
    r.IsSystem,
    COUNT(rp.PermissionId) AS PermissionCount
FROM dbo.Roles r
LEFT JOIN dbo.RolePermissions rp ON rp.RoleId = r.Id
GROUP BY r.Id, r.Name, r.Description, r.IsSystem;
GO

CREATE OR ALTER VIEW dbo.vw_UserPermissions
AS
SELECT DISTINCT
    u.Id AS UserId,
    u.Username,
    p.Code AS PermissionCode,
    p.Name AS PermissionName,
    p.Category AS PermissionCategory
FROM dbo.Users u
INNER JOIN dbo.UserRoles ur ON ur.UserId = u.Id
INNER JOIN dbo.RolePermissions rp ON rp.RoleId = ur.RoleId
INNER JOIN dbo.Permissions p ON p.Id = rp.PermissionId
WHERE u.IsActive = 1;
GO

PRINT N'[2/3] Auth & RBAC completed.';
GO

-- ═══════════════════════════════════════════════════════════════════
-- STEP 4: RUN 003_educational_objects.sql (SPs, Functions, etc.)
-- ═══════════════════════════════════════════════════════════════════

-- SP1: Register customer
CREATE OR ALTER PROCEDURE dbo.sp_RegisterCustomer
    @Type              tinyint,
    @DisplayName       nvarchar(200),
    @NationalId        varchar(20) = NULL,
    @CompanyNationalId varchar(20) = NULL,
    @PhoneNumber       nvarchar(30) = NULL,
    @Address           nvarchar(500) = NULL,
    @NewCustomerId     uniqueidentifier OUTPUT,
    @CustomerNumber    varchar(32) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @Today varchar(8) = CONVERT(varchar(8), GETUTCDATE(), 112);
        DECLARE @Seq int;
        SELECT @Seq = ISNULL(MAX(CAST(RIGHT(CustomerNumber, 8) AS int)), 0) + 1
        FROM dbo.Customers WHERE CustomerNumber LIKE 'CUS-' + @Today + '-%';
        SET @CustomerNumber = 'CUS-' + @Today + '-' + RIGHT('00000000' + CAST(@Seq AS varchar(8)), 8);
        SET @NewCustomerId = NEWID();

        INSERT INTO dbo.Customers (Id, CustomerNumber, Type, DisplayName, NationalId, CompanyNationalId,
            PhoneNumber, Address, Status, RiskLevel, CreatedAtUtc, UpdatedAtUtc)
        VALUES (@NewCustomerId, @CustomerNumber, @Type, @DisplayName, @NationalId, @CompanyNationalId,
            @PhoneNumber, @Address, 1, 1, SYSUTCDATETIME(), SYSUTCDATETIME());
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO
PRINT N'  + sp_RegisterCustomer created.';
GO
-- SP2: Deposit
CREATE OR ALTER PROCEDURE dbo.sp_Deposit
    @AccountId   uniqueidentifier,
    @Amount      decimal(19,4),
    @Description nvarchar(500) = N'واریز',
    @NewBalance  decimal(19,4) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF @Amount <= 0 THROW 50001, 'مبلغ باید مثبت باشد.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.Accounts WHERE Id = @AccountId AND Status = 1)
        THROW 50002, 'حساب معتبر نیست.', 1;

    BEGIN TRANSACTION;
    UPDATE dbo.Accounts SET Balance = Balance + @Amount, Version = Version + 1 WHERE Id = @AccountId;
    SET @NewBalance = (SELECT Balance FROM dbo.Accounts WHERE Id = @AccountId);
    COMMIT TRANSACTION;
END;
GO
PRINT N'  + sp_Deposit created.';
GO
-- SP3: Transfer
CREATE OR ALTER PROCEDURE dbo.sp_Transfer
    @SourceId      uniqueidentifier,
    @DestinationId uniqueidentifier,
    @Amount        decimal(19,4),
    @Description   nvarchar(500) = N'انتقال'
AS
BEGIN
    SET NOCOUNT ON;
    IF @SourceId = @DestinationId THROW 50003, 'حساب مبدأ و مقصد یکسان است.', 1;
    IF @Amount <= 0 THROW 50001, 'مبلغ باید مثبت باشد.', 1;

    BEGIN TRANSACTION;
    DECLARE @First uniqueidentifier = CASE WHEN @SourceId < @DestinationId THEN @SourceId ELSE @DestinationId END;
    DECLARE @Second uniqueidentifier = CASE WHEN @SourceId < @DestinationId THEN @DestinationId ELSE @SourceId END;

    DECLARE @SrcBal decimal(19,4), @DstBal decimal(19,4);
    SELECT @SrcBal = Balance FROM dbo.Accounts WITH (UPDLOCK) WHERE Id = @First;
    SELECT @DstBal = Balance FROM dbo.Accounts WITH (UPDLOCK) WHERE Id = @Second;

    UPDATE dbo.Accounts SET Balance = Balance - @Amount, Version = Version + 1 WHERE Id = @SourceId;
    UPDATE dbo.Accounts SET Balance = Balance + @Amount, Version = Version + 1 WHERE Id = @DestinationId;

    DECLARE @TxRef varchar(64) = 'TRX-' + CONVERT(varchar(20), GETUTCDATE(), 112) + '-' + LEFT(REPLACE(CAST(NEWID() AS varchar(40)), '-', ''), 16);
    INSERT INTO dbo.BankTransactions (Id, Reference, Type, SourceAccountId, DestinationAccountId, Amount, Fee, Status, Description, CreatedAtUtc)
    VALUES (NEWID(), @TxRef, 3, @SourceId, @DestinationId, @Amount, 0, 2, @Description, SYSUTCDATETIME());
    COMMIT TRANSACTION;
END;
GO
PRINT N'  + sp_Transfer created.';
GO

-- SP4: Search customers
CREATE OR ALTER PROCEDURE dbo.sp_SearchCustomers
    @SearchTerm nvarchar(100) = NULL,
    @Status     tinyint = NULL,
    @Type       tinyint = NULL,
    @Page       int = 1,
    @PageSize   int = 50
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql nvarchar(max) = N'
        SELECT Id, CustomerNumber, Type, DisplayName, NationalId, PhoneNumber, Status, RiskLevel, CreatedAtUtc
        FROM dbo.Customers
        WHERE 1=1';

    IF @SearchTerm IS NOT NULL
        SET @sql += N' AND (DisplayName LIKE N''%'' + @s + N''%'' OR CustomerNumber LIKE N''%'' + @s + N''%'' OR NationalId LIKE N''%'' + @s + N''%'')';
    IF @Status IS NOT NULL
        SET @sql += N' AND Status = @st';
    IF @Type IS NOT NULL
        SET @sql += N' AND Type = @tp';

    SET @sql += N' ORDER BY CreatedAtUtc DESC OFFSET @off ROWS FETCH NEXT @ps ROWS ONLY';
    DECLARE @initOff INT = (@Page - 1) * @PageSize;
    EXEC sp_executesql @sql,
        N'@s nvarchar(100), @st tinyint, @tp tinyint, @off int, @ps int',
        @s = @SearchTerm, @st = @Status, @tp = @Type,
        @off = @initOff, @ps = @PageSize;
END;
GO
PRINT N'  + sp_SearchCustomers created.';
GO
-- SP5: Account statement
CREATE OR ALTER PROCEDURE dbo.sp_AccountStatement
    @AccountId uniqueidentifier,
    @FromDate  datetime2(3) = NULL,
    @ToDate    datetime2(3) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @FromDate IS NULL SET @FromDate = DATEADD(MONTH, -1, SYSUTCDATETIME());
    IF @ToDate IS NULL SET @ToDate = SYSUTCDATETIME();

    CREATE TABLE #Statement (
        RowNum      int IDENTITY(1,1),
        Reference   varchar(64),
        Type        tinyint,
        Amount      decimal(19,4),
        Fee         decimal(19,4),
        Status      tinyint,
        Description nvarchar(500),
        CreatedAt   datetime2(3),
        Balance     decimal(19,4)
    );

    INSERT INTO #Statement (Reference, Type, Amount, Fee, Status, Description, CreatedAt, Balance)
    SELECT Reference, Type, Amount, Fee, Status, Description, CreatedAtUtc, 0
    FROM dbo.BankTransactions
    WHERE (SourceAccountId = @AccountId OR DestinationAccountId = @AccountId)
      AND CreatedAtUtc BETWEEN @FromDate AND @ToDate
    ORDER BY CreatedAtUtc;

    UPDATE s SET s.Balance = (
        SELECT ISNULL(SUM(CASE WHEN DestinationAccountId = @AccountId THEN Amount ELSE -Amount END), 0)
        FROM dbo.BankTransactions t
        WHERE (t.SourceAccountId = @AccountId OR t.DestinationAccountId = @AccountId)
          AND t.CreatedAtUtc <= s.CreatedAt
          AND t.Status = 2
    )
    FROM #Statement s;

    SELECT * FROM #Statement ORDER BY CreatedAt;
    DROP TABLE #Statement;
END;
GO
PRINT N'  + sp_AccountStatement created.';
GO
-- SP6: Monthly interest (cursor)
CREATE OR ALTER PROCEDURE dbo.sp_CalculateMonthlyInterest
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @AccountId uniqueidentifier;
    DECLARE @Balance decimal(19,4);
    DECLARE @InterestRate decimal(9,6) = 0.18;
    DECLARE @Interest decimal(19,4);
    DECLARE @TotalProcessed int = 0;

    DECLARE account_cursor CURSOR FOR
        SELECT Id, Balance FROM dbo.Accounts
        WHERE Type IN (3, 4) AND Status = 1 AND Balance > 0;

    OPEN account_cursor;
    FETCH NEXT FROM account_cursor INTO @AccountId, @Balance;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Interest = ROUND(@Balance * @InterestRate / 12, 4);

        IF @Interest > 0
        BEGIN
            UPDATE dbo.Accounts SET Balance = Balance + @Interest, Version = Version + 1 WHERE Id = @AccountId;

            DECLARE @Ref varchar(64) = 'INT-' + CONVERT(varchar(20), GETUTCDATE(), 112) + '-' + LEFT(REPLACE(CAST(NEWID() AS varchar(40)), '-', ''), 16);
            INSERT INTO dbo.BankTransactions (Id, Reference, Type, DestinationAccountId, Amount, Fee, Status, Description, CreatedAtUtc)
            VALUES (NEWID(), @Ref, 8, @AccountId, @Interest, 0, 2, N'سود ماهانه', SYSUTCDATETIME());

            SET @TotalProcessed = @TotalProcessed + 1;
        END

        FETCH NEXT FROM account_cursor INTO @AccountId, @Balance;
    END

    CLOSE account_cursor;
    DEALLOCATE account_cursor;

    PRINT CAST(@TotalProcessed AS varchar(10)) + N' حساب سود ماهانه دریافت کردند.';
END;
GO
PRINT N'  + sp_CalculateMonthlyInterest created.';
GO
-- SP7: Check minimum balance (cursor)
CREATE OR ALTER PROCEDURE dbo.sp_CheckMinimumBalance
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @AccountId uniqueidentifier;
    DECLARE @AccountNumber varchar(32);
    DECLARE @Balance decimal(19,4);
    DECLARE @Minimum decimal(19,4);
    DECLARE @CustomerId uniqueidentifier;
    DECLARE @CustomerName nvarchar(200);

    DECLARE min_cursor CURSOR FOR
        SELECT a.Id, a.AccountNumber, a.Balance, a.MinimumBalance, a.CustomerId
        FROM dbo.Accounts a
        WHERE a.Status = 1 AND a.Balance < a.MinimumBalance;

    OPEN min_cursor;
    FETCH NEXT FROM min_cursor INTO @AccountId, @AccountNumber, @Balance, @Minimum, @CustomerId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @CustomerName = (SELECT DisplayName FROM dbo.Customers WHERE Id = @CustomerId);
        PRINT N'هشدار: حساب ' + @AccountNumber + N' (' + ISNULL(@CustomerName, N'') + N') مانده ' +
              CAST(@Balance AS nvarchar(20)) + N' از کف مجاز ' + CAST(@Minimum AS nvarchar(20)) + N' کمتر است.';

        FETCH NEXT FROM min_cursor INTO @AccountId, @AccountNumber, @Balance, @Minimum, @CustomerId;
    END

    CLOSE min_cursor;
    DEALLOCATE min_cursor;
END;
GO
PRINT N'  + sp_CheckMinimumBalance created.';
GO
-- SP8: Archive old transactions
CREATE OR ALTER PROCEDURE dbo.sp_ArchiveOldTransactions
    @DaysOld int = 365
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TxId uniqueidentifier;
    DECLARE @Count int = 0;

    DECLARE tx_cursor CURSOR FOR
        SELECT Id FROM dbo.BankTransactions
        WHERE CreatedAtUtc < DATEADD(DAY, -@DaysOld, SYSUTCDATETIME())
          AND Status IN (2, 3, 4);

    OPEN tx_cursor;
    FETCH NEXT FROM tx_cursor INTO @TxId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Count = @Count + 1;
        FETCH NEXT FROM tx_cursor INTO @TxId;
    END

    CLOSE tx_cursor;
    DEALLOCATE tx_cursor;

    PRINT CAST(@Count AS varchar(10)) + N' تراکنش قدیمی یافت شد.';
END;
GO
PRINT N'  + sp_ArchiveOldTransactions created.';
GO
-- SP9: Running balance (CTE)
CREATE OR ALTER PROCEDURE dbo.sp_RunningBalance
    @AccountId uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    WITH OrderedTransactions AS (
        SELECT Id, Reference, Type, Amount, CreatedAtUtc,
            ROW_NUMBER() OVER (ORDER BY CreatedAtUtc) AS RowNum
        FROM dbo.BankTransactions
        WHERE SourceAccountId = @AccountId OR DestinationAccountId = @AccountId
    ),
    RunningBalance AS (
        SELECT *,
            SUM(CASE WHEN Type IN (1, 3) THEN Amount ELSE -Amount END)
            OVER (ORDER BY RowNum) AS RunningTotal
        FROM OrderedTransactions
    )
    SELECT * FROM RunningBalance ORDER BY RowNum;
END;
GO
PRINT N'  + sp_RunningBalance created.';
GO
-- SP10: Transaction pivot
CREATE OR ALTER PROCEDURE dbo.sp_TransactionPivot
    @Year int = 2026
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM (
        SELECT
            MONTH(CreatedAtUtc) AS TxMonth,
            Type,
            Amount
        FROM dbo.BankTransactions
        WHERE YEAR(CreatedAtUtc) = @Year AND Status = 2
    ) AS Source
    PIVOT (
        SUM(Amount)
        FOR Type IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])
    ) AS PivotTable
    ORDER BY TxMonth;
END;
GO
PRINT N'  + sp_TransactionPivot created.';
GO
-- Scalar Functions
CREATE OR ALTER FUNCTION dbo.fn_FormatAccountNumber(@AccountNumber varchar(32))
RETURNS varchar(39)
AS
BEGIN
    RETURN STUFF(STUFF(STUFF(@AccountNumber, 5, 0, '-'), 10, 0, '-'), 15, 0, '-');
END;
GO
PRINT N'  + fn_FormatAccountNumber created.';
GO
CREATE OR ALTER FUNCTION dbo.fn_AccountAgeDays(@AccountId uniqueidentifier)
RETURNS int
AS
BEGIN
    DECLARE @Opened datetime2(3);
    SELECT @Opened = OpenedAtUtc FROM dbo.Accounts WHERE Id = @AccountId;
    IF @Opened IS NULL RETURN 0;
    RETURN DATEDIFF(DAY, @Opened, SYSUTCDATETIME());
END;
GO
PRINT N'  + fn_AccountAgeDays created.';
GO
CREATE OR ALTER FUNCTION dbo.fn_CustomerFullName(@CustomerId uniqueidentifier)
RETURNS nvarchar(200)
AS
BEGIN
    DECLARE @Name nvarchar(200);
    SELECT @Name = DisplayName FROM dbo.Customers WHERE Id = @CustomerId;
    RETURN ISNULL(@Name, N'نامشخص');
END;
GO
PRINT N'  + fn_CustomerFullName created.';
GO
CREATE OR ALTER FUNCTION dbo.fn_AccountSummary(@CustomerId uniqueidentifier)
RETURNS TABLE
AS
RETURN
(
    SELECT
        a.AccountNumber,
        a.Type,
        a.Status,
        a.Balance,
        a.MinimumBalance,
        dbo.fn_FormatAccountNumber(a.AccountNumber) AS FormattedNumber,
        DATEDIFF(DAY, a.OpenedAtUtc, SYSUTCDATETIME()) AS AgeDays
    FROM dbo.Accounts a
    WHERE a.CustomerId = @CustomerId
);
GO
PRINT N'  + fn_AccountSummary created.';
GO
CREATE OR ALTER FUNCTION dbo.fn_MonthlyTransactionSummary(@Year int, @Month int)
RETURNS @Summary TABLE (
    TransactionType tinyint,
    TransactionCount int,
    TotalAmount decimal(19,4),
    AverageAmount decimal(19,4),
    MinAmount decimal(19,4),
    MaxAmount decimal(19,4)
)
AS
BEGIN
    INSERT INTO @Summary
    SELECT
        Type,
        COUNT(*) AS TransactionCount,
        SUM(Amount) AS TotalAmount,
        AVG(Amount) AS AverageAmount,
        MIN(Amount) AS MinAmount,
        MAX(Amount) AS MaxAmount
    FROM dbo.BankTransactions
    WHERE YEAR(CreatedAtUtc) = @Year AND MONTH(CreatedAtUtc) = @Month AND Status = 2
    GROUP BY Type;
    RETURN;
END;
GO
PRINT N'  + fn_MonthlyTransactionSummary created.';
GO
-- Views
CREATE OR ALTER VIEW dbo.vw_CustomerDashboard
AS
SELECT
    c.Id AS CustomerId,
    c.CustomerNumber,
    c.DisplayName,
    c.Type,
    c.Status,
    COUNT(DISTINCT a.Id) AS AccountCount,
    ISNULL(SUM(a.Balance), 0) AS TotalBalance,
    COUNT(DISTINCT t.Id) AS TransactionCount,
    MAX(t.CreatedAtUtc) AS LastTransactionDate
FROM dbo.Customers c
LEFT JOIN dbo.Accounts a ON a.CustomerId = c.Id
LEFT JOIN dbo.BankTransactions t ON t.SourceAccountId = a.Id OR t.DestinationAccountId = a.Id
GROUP BY c.Id, c.CustomerNumber, c.DisplayName, c.Type, c.Status;
GO
PRINT N'  + vw_CustomerDashboard created.';
GO
CREATE OR ALTER VIEW dbo.vw_TransactionDetails
AS
SELECT
    t.Id,
    t.Reference,
    t.Type,
    t.Amount,
    t.Fee,
    t.Status,
    t.Description,
    t.CreatedAtUtc,
    src.AccountNumber AS SourceAccount,
    src.DisplayName AS SourceCustomer,
    dst.AccountNumber AS DestAccount,
    dst.DisplayName AS DestCustomer
FROM dbo.BankTransactions t
LEFT JOIN (
    SELECT a.Id AS AccountId, a.AccountNumber, c.DisplayName
    FROM dbo.Accounts a INNER JOIN dbo.Customers c ON c.Id = a.CustomerId
) src ON src.AccountId = t.SourceAccountId
LEFT JOIN (
    SELECT a.Id AS AccountId, a.AccountNumber, c.DisplayName
    FROM dbo.Accounts a INNER JOIN dbo.Customers c ON c.Id = a.CustomerId
) dst ON dst.AccountId = t.DestinationAccountId;
GO
PRINT N'  + vw_TransactionDetails created.';
GO
CREATE OR ALTER VIEW dbo.vw_DailyTransactionSummary
AS
SELECT
    CAST(CreatedAtUtc AS date) AS TransactionDate,
    Type,
    COUNT(*) AS TransactionCount,
    SUM(Amount) AS TotalAmount,
    SUM(Fee) AS TotalFee,
    COUNT(CASE WHEN Status = 2 THEN 1 END) AS CompletedCount,
    COUNT(CASE WHEN Status = 3 THEN 1 END) AS FailedCount
FROM dbo.BankTransactions
GROUP BY CAST(CreatedAtUtc AS date), Type;
GO
PRINT N'  + vw_DailyTransactionSummary created.';
GO
-- Triggers
CREATE OR ALTER TRIGGER trg_AccountBalanceAudit
ON dbo.Accounts
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.AuditLogs (Id, Action, EntityType, EntityId, Details, OccurredAtUtc, MachineName, UserName)
    SELECT
        NEWID(),
        'BalanceChanged',
        'Account',
        i.Id,
        CONCAT('Balance: ', CAST(d.Balance AS nvarchar(20)), ' -> ', CAST(i.Balance AS nvarchar(20)),
               ', Version: ', CAST(d.Version AS nvarchar(10)), ' -> ', CAST(i.Version AS nvarchar(10))),
        SYSUTCDATETIME(),
        HOST_NAME(),
        SYSTEM_USER
    FROM inserted i
    INNER JOIN deleted d ON d.Id = i.Id
    WHERE i.Balance <> d.Balance OR i.Status <> d.Status;
END;
GO
PRINT N'  + trg_AccountBalanceAudit created.';
GO
CREATE OR ALTER TRIGGER trg_PreventDeleteSystemRole
ON dbo.Roles
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted WHERE IsSystem = 1)
    BEGIN
        RAISERROR('نقش‌های سیستمی قابل حذف نیستند.', 16, 1);
        RETURN;
    END
    DELETE FROM dbo.Roles WHERE Id IN (SELECT Id FROM deleted WHERE IsSystem = 0);
END;
GO
PRINT N'  + trg_PreventDeleteSystemRole created.';
GO
CREATE OR ALTER TRIGGER trg_CustomerUpdatedAt
ON dbo.Customers
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE c SET UpdatedAtUtc = SYSUTCDATETIME()
    FROM dbo.Customers c
    INNER JOIN inserted i ON c.Id = i.Id;
END;
GO
PRINT N'  + trg_CustomerUpdatedAt created.';

PRINT N'[3/3] Educational objects completed.';
GO
