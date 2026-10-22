USE CrunchyrollDB;
GO

/* ---------------------------------------------------------------------
   Функция 1: възраст на потребител към дадена дата
   --------------------------------------------------------------------- */
CREATE OR ALTER FUNCTION dbo.fn_GetUserAge
(
    @UserID INT,
    @AsOf   DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @DOB DATE = (SELECT DateOfBirth FROM dbo.Users WHERE UserID = @UserID);
    IF @DOB IS NULL RETURN NULL;

    RETURN DATEDIFF(YEAR, @DOB, @AsOf)
         - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, @DOB, @AsOf), @DOB) > @AsOf THEN 1 ELSE 0 END;
END
GO

/* ---------------------------------------------------------------------
   Функция 2: общо изгледано време на потребител в минути
   --------------------------------------------------------------------- */
CREATE OR ALTER FUNCTION dbo.fn_GetUserWatchMinutes
(
    @UserID INT
)
RETURNS DECIMAL(12,1)
AS
BEGIN
    RETURN ISNULL((SELECT SUM(ProgressSeconds) / 60.0
                   FROM dbo.WatchHistory
                   WHERE UserID = @UserID), 0);
END
GO
