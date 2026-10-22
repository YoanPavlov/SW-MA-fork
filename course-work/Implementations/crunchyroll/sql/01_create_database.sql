USE master;
GO

IF DB_ID(N'CrunchyrollDB') IS NOT NULL
BEGIN
    ALTER DATABASE CrunchyrollDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CrunchyrollDB;
END
GO

CREATE DATABASE CrunchyrollDB;
GO

USE CrunchyrollDB;
GO

/* Countries */
CREATE TABLE dbo.Countries (
    CountryID   INT IDENTITY(1,1) CONSTRAINT PK_Countries PRIMARY KEY,
    Name        NVARCHAR(100) NOT NULL CONSTRAINT UQ_Countries_Name UNIQUE,
    IsoCode     CHAR(2)       NOT NULL CONSTRAINT UQ_Countries_Iso UNIQUE,
    Region      NVARCHAR(50)  NOT NULL
);
GO

/* Users */
CREATE TABLE dbo.Users (
    UserID           INT IDENTITY(1,1) CONSTRAINT PK_Users PRIMARY KEY,
    Username         NVARCHAR(50)  NOT NULL CONSTRAINT UQ_Users_Username UNIQUE,
    Email            NVARCHAR(255) NOT NULL CONSTRAINT UQ_Users_Email UNIQUE,
    PasswordHash     VARBINARY(64) NOT NULL,
    DateOfBirth      DATE          NOT NULL,
    CountryID        INT           NOT NULL
        CONSTRAINT FK_Users_Countries REFERENCES dbo.Countries(CountryID),
    RegistrationDate DATETIME2(0)  NOT NULL CONSTRAINT DF_Users_RegDate DEFAULT SYSDATETIME(),
    IsActive         BIT           NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT 1,
    CONSTRAINT CK_Users_Email CHECK (Email LIKE '%_@_%._%'),
    CONSTRAINT CK_Users_DOB   CHECK (DateOfBirth > '1900-01-01')
);
GO

/* SubscriptionPlans */
CREATE TABLE dbo.SubscriptionPlans (
    PlanID          INT IDENTITY(1,1) CONSTRAINT PK_SubscriptionPlans PRIMARY KEY,
    Name            NVARCHAR(50)  NOT NULL CONSTRAINT UQ_Plans_Name UNIQUE,
    MonthlyPrice    DECIMAL(6,2)  NOT NULL CONSTRAINT CK_Plans_Price CHECK (MonthlyPrice >= 0),
    MaxStreams      TINYINT       NOT NULL CONSTRAINT CK_Plans_Streams CHECK (MaxStreams BETWEEN 1 AND 10),
    OfflineViewing  BIT           NOT NULL,
    AdFree          BIT           NOT NULL,
    PremiumAccess   BIT           NOT NULL 
);
GO

/* Subscriptions */
CREATE TABLE dbo.Subscriptions (
    SubscriptionID  INT IDENTITY(1,1) CONSTRAINT PK_Subscriptions PRIMARY KEY,
    UserID          INT          NOT NULL
        CONSTRAINT FK_Subscriptions_Users REFERENCES dbo.Users(UserID),
    PlanID          INT          NOT NULL
        CONSTRAINT FK_Subscriptions_Plans REFERENCES dbo.SubscriptionPlans(PlanID),
    StartDate       DATE         NOT NULL,
    EndDate         DATE         NULL,
    Status          NVARCHAR(20) NOT NULL CONSTRAINT DF_Subscriptions_Status DEFAULT N'Active',
    AutoRenew       BIT          NOT NULL CONSTRAINT DF_Subscriptions_AutoRenew DEFAULT 1,
    CONSTRAINT CK_Subscriptions_Status CHECK (Status IN (N'Active', N'Cancelled', N'Expired')),
    CONSTRAINT CK_Subscriptions_Dates  CHECK (EndDate IS NULL OR EndDate >= StartDate)
);
GO

/* Payments */
CREATE TABLE dbo.Payments (
    PaymentID       INT IDENTITY(1,1) CONSTRAINT PK_Payments PRIMARY KEY,
    SubscriptionID  INT           NOT NULL
        CONSTRAINT FK_Payments_Subscriptions REFERENCES dbo.Subscriptions(SubscriptionID),
    Amount          DECIMAL(8,2)  NOT NULL CONSTRAINT CK_Payments_Amount CHECK (Amount >= 0),
    PaymentDate     DATETIME2(0)  NOT NULL CONSTRAINT DF_Payments_Date DEFAULT SYSDATETIME(),
    Method          NVARCHAR(20)  NOT NULL,
    Status          NVARCHAR(20)  NOT NULL CONSTRAINT DF_Payments_Status DEFAULT N'Completed',
    CONSTRAINT CK_Payments_Method CHECK (Method IN (N'Card', N'PayPal', N'GiftCard', N'AppStore', N'GooglePlay')),
    CONSTRAINT CK_Payments_Status CHECK (Status IN (N'Completed', N'Failed', N'Refunded'))
);
GO

/* Studios */
CREATE TABLE dbo.Studios (
    StudioID     INT IDENTITY(1,1) CONSTRAINT PK_Studios PRIMARY KEY,
    Name         NVARCHAR(100) NOT NULL CONSTRAINT UQ_Studios_Name UNIQUE,
    CountryID    INT           NOT NULL
        CONSTRAINT FK_Studios_Countries REFERENCES dbo.Countries(CountryID),
    FoundedYear  SMALLINT      NULL CONSTRAINT CK_Studios_Year CHECK (FoundedYear BETWEEN 1900 AND 2100),
    Website      NVARCHAR(255) NULL
);
GO

/* Anime */
CREATE TABLE dbo.Anime (
    AnimeID        INT IDENTITY(1,1) CONSTRAINT PK_Anime PRIMARY KEY,
    Title          NVARCHAR(200) NOT NULL,
    OriginalTitle  NVARCHAR(200) NULL,
    StudioID       INT           NOT NULL
        CONSTRAINT FK_Anime_Studios REFERENCES dbo.Studios(StudioID),
    ReleaseYear    SMALLINT      NOT NULL CONSTRAINT CK_Anime_Year CHECK (ReleaseYear BETWEEN 1950 AND 2100),
    AgeRating      NVARCHAR(10)  NOT NULL,
    Synopsis       NVARCHAR(MAX) NULL,
    Status         NVARCHAR(20)  NOT NULL CONSTRAINT DF_Anime_Status DEFAULT N'Ongoing',
    AvgRating      DECIMAL(3,2)  NULL,      
    RatingCount    INT           NOT NULL CONSTRAINT DF_Anime_RatingCount DEFAULT 0,
    CONSTRAINT CK_Anime_AgeRating CHECK (AgeRating IN (N'G', N'PG', N'13+', N'16+', N'18+')),
    CONSTRAINT CK_Anime_Status    CHECK (Status IN (N'Ongoing', N'Completed', N'Upcoming'))
);
GO

/* Genres */
CREATE TABLE dbo.Genres (
    GenreID      INT IDENTITY(1,1) CONSTRAINT PK_Genres PRIMARY KEY,
    Name         NVARCHAR(50)  NOT NULL CONSTRAINT UQ_Genres_Name UNIQUE,
    Description  NVARCHAR(255) NULL
);
GO

/* AnimeGenres */
CREATE TABLE dbo.AnimeGenres (
    AnimeID  INT NOT NULL CONSTRAINT FK_AnimeGenres_Anime  REFERENCES dbo.Anime(AnimeID)  ON DELETE CASCADE,
    GenreID  INT NOT NULL CONSTRAINT FK_AnimeGenres_Genres REFERENCES dbo.Genres(GenreID) ON DELETE CASCADE,
    CONSTRAINT PK_AnimeGenres PRIMARY KEY (AnimeID, GenreID)
);
GO

/* Seasons */
CREATE TABLE dbo.Seasons (
    SeasonID      INT IDENTITY(1,1) CONSTRAINT PK_Seasons PRIMARY KEY,
    AnimeID       INT           NOT NULL
        CONSTRAINT FK_Seasons_Anime REFERENCES dbo.Anime(AnimeID) ON DELETE CASCADE,
    SeasonNumber  TINYINT       NOT NULL,
    Title         NVARCHAR(200) NULL,
    ReleaseDate   DATE          NOT NULL,
    CONSTRAINT UQ_Seasons_Anime_Number UNIQUE (AnimeID, SeasonNumber)
);
GO

/* Episodes */
CREATE TABLE dbo.Episodes (
    EpisodeID        INT IDENTITY(1,1) CONSTRAINT PK_Episodes PRIMARY KEY,
    SeasonID         INT           NOT NULL
        CONSTRAINT FK_Episodes_Seasons REFERENCES dbo.Seasons(SeasonID) ON DELETE CASCADE,
    EpisodeNumber    SMALLINT      NOT NULL,
    Title            NVARCHAR(200) NOT NULL,
    DurationSeconds  INT           NOT NULL CONSTRAINT CK_Episodes_Duration CHECK (DurationSeconds > 0),
    AirDate          DATE          NOT NULL,
    IsPremium        BIT           NOT NULL CONSTRAINT DF_Episodes_IsPremium DEFAULT 0,
    CONSTRAINT UQ_Episodes_Season_Number UNIQUE (SeasonID, EpisodeNumber)
);
GO

/* Languages */
CREATE TABLE dbo.Languages (
    LanguageID  INT IDENTITY(1,1) CONSTRAINT PK_Languages PRIMARY KEY,
    Name        NVARCHAR(50) NOT NULL CONSTRAINT UQ_Languages_Name UNIQUE,
    Code        VARCHAR(10)  NOT NULL CONSTRAINT UQ_Languages_Code UNIQUE
);
GO

/* EpisodeLanguages */
CREATE TABLE dbo.EpisodeLanguages (
    EpisodeID   INT         NOT NULL CONSTRAINT FK_EpLang_Episodes  REFERENCES dbo.Episodes(EpisodeID) ON DELETE CASCADE,
    LanguageID  INT         NOT NULL CONSTRAINT FK_EpLang_Languages REFERENCES dbo.Languages(LanguageID),
    TrackType   NVARCHAR(5) NOT NULL,
    CONSTRAINT PK_EpisodeLanguages PRIMARY KEY (EpisodeID, LanguageID, TrackType),
    CONSTRAINT CK_EpLang_TrackType CHECK (TrackType IN (N'Sub', N'Dub'))
);
GO

/* WatchHistory */
CREATE TABLE dbo.WatchHistory (
    WatchID          BIGINT IDENTITY(1,1) CONSTRAINT PK_WatchHistory PRIMARY KEY,
    UserID           INT          NOT NULL CONSTRAINT FK_Watch_Users    REFERENCES dbo.Users(UserID),
    EpisodeID        INT          NOT NULL CONSTRAINT FK_Watch_Episodes REFERENCES dbo.Episodes(EpisodeID),
    WatchedAt        DATETIME2(0) NOT NULL CONSTRAINT DF_Watch_WatchedAt DEFAULT SYSDATETIME(),
    ProgressSeconds  INT          NOT NULL CONSTRAINT CK_Watch_Progress CHECK (ProgressSeconds >= 0),
    IsCompleted      BIT          NOT NULL CONSTRAINT DF_Watch_Completed DEFAULT 0,
    DeviceType       NVARCHAR(20) NOT NULL,
    CONSTRAINT CK_Watch_Device CHECK (DeviceType IN (N'Web', N'Android', N'iOS', N'SmartTV', N'Console'))
);
GO

/* Ratings */
CREATE TABLE dbo.Ratings (
    UserID      INT            NOT NULL CONSTRAINT FK_Ratings_Users REFERENCES dbo.Users(UserID),
    AnimeID     INT            NOT NULL CONSTRAINT FK_Ratings_Anime REFERENCES dbo.Anime(AnimeID) ON DELETE CASCADE,
    Score       TINYINT        NOT NULL CONSTRAINT CK_Ratings_Score CHECK (Score BETWEEN 1 AND 5),
    ReviewText  NVARCHAR(2000) NULL,
    RatedAt     DATETIME2(0)   NOT NULL CONSTRAINT DF_Ratings_RatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Ratings PRIMARY KEY (UserID, AnimeID)
);
GO

/* Watchlist */
CREATE TABLE dbo.Watchlist (
    UserID   INT          NOT NULL CONSTRAINT FK_Watchlist_Users REFERENCES dbo.Users(UserID),
    AnimeID  INT          NOT NULL CONSTRAINT FK_Watchlist_Anime REFERENCES dbo.Anime(AnimeID) ON DELETE CASCADE,
    AddedAt  DATETIME2(0) NOT NULL CONSTRAINT DF_Watchlist_AddedAt DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Watchlist PRIMARY KEY (UserID, AnimeID)
);
GO

/* AuditLog */
CREATE TABLE dbo.AuditLog (
    AuditID     BIGINT IDENTITY(1,1) CONSTRAINT PK_AuditLog PRIMARY KEY,
    TableName   SYSNAME        NOT NULL,
    Action      NVARCHAR(10)   NOT NULL,
    RecordID    INT            NOT NULL,
    Details     NVARCHAR(1000) NULL,
    ChangedAt   DATETIME2(0)   NOT NULL CONSTRAINT DF_AuditLog_ChangedAt DEFAULT SYSDATETIME(),
    ChangedBy   SYSNAME        NOT NULL CONSTRAINT DF_AuditLog_ChangedBy DEFAULT SUSER_SNAME()
);
GO
