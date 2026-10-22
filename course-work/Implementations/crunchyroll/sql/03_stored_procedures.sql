USE CrunchyrollDB;
GO

/* ---------------------------------------------------------------------
   Процедура 1: регистрация на нов потребител.
   Хешира паролата (SHA2_256), създава безплатен абонамент и връща UserID.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_RegisterUser
    @Username    NVARCHAR(50),
    @Email       NVARCHAR(255),
    @Password    NVARCHAR(128),
    @DateOfBirth DATE,
    @CountryIso  CHAR(2),
    @NewUserID   INT OUTPUT
AS
BEGIN
    SET XACT_ABORT ON;

    DECLARE @CountryID INT = (SELECT CountryID FROM dbo.Countries WHERE IsoCode = @CountryIso);
    IF @CountryID IS NULL
        THROW 50001, N'Непозната държава (ISO код).', 1;

    IF EXISTS (SELECT 1 FROM dbo.Users WHERE Username = @Username OR Email = @Email)
        THROW 50002, N'Потребителско име или имейл вече съществуват.', 1;

    IF DATEADD(YEAR, 13, @DateOfBirth) > CAST(GETDATE() AS DATE)
        THROW 50003, N'Потребителят трябва да е поне на 13 години.', 1;

    BEGIN TRAN;
        INSERT INTO dbo.Users (Username, Email, PasswordHash, DateOfBirth, CountryID)
        VALUES (@Username, @Email, HASHBYTES('SHA2_256', @Password), @DateOfBirth, @CountryID);

        SET @NewUserID = SCOPE_IDENTITY();

        INSERT INTO dbo.Subscriptions (UserID, PlanID, StartDate, EndDate, Status, AutoRenew)
        SELECT @NewUserID, PlanID, CAST(GETDATE() AS DATE), NULL, N'Active', 0
        FROM dbo.SubscriptionPlans
        WHERE Name = N'Free';
    COMMIT;
END
GO

/* ---------------------------------------------------------------------
   Процедура 2: записване на гледане на епизод.
   Автоматично маркира епизода като изгледан при >= 90 % прогрес.
   Пример: EXEC dbo.sp_RecordWatch 5, 120, 1380, N'Web';
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_RecordWatch
    @UserID          INT,
    @EpisodeID       INT,
    @ProgressSeconds INT,
    @DeviceType      NVARCHAR(20)
AS
BEGIN
    DECLARE @Duration INT = (SELECT DurationSeconds FROM dbo.Episodes WHERE EpisodeID = @EpisodeID);
    IF @Duration IS NULL
        THROW 50020, N'Несъществуващ епизод.', 1;

    IF @ProgressSeconds > @Duration SET @ProgressSeconds = @Duration;

    INSERT INTO dbo.WatchHistory (UserID, EpisodeID, ProgressSeconds, IsCompleted, DeviceType)
    VALUES (@UserID, @EpisodeID, @ProgressSeconds,
            CASE WHEN @ProgressSeconds >= 0.9 * @Duration THEN 1 ELSE 0 END,
            @DeviceType);
END
GO
