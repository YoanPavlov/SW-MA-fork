USE CrunchyrollDB;
GO

/* ---------------------------------------------------------------------
   Тригер 1: не допуска застъпващи се (неотменени) абонаменти за един и същ потребител.
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.trg_Subscriptions_NoOverlap
ON dbo.Subscriptions
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.Subscriptions s
          ON s.UserID = i.UserID
         AND s.SubscriptionID <> i.SubscriptionID
        WHERE i.Status <> N'Cancelled'
          AND s.Status <> N'Cancelled'
          AND i.StartDate <= ISNULL(s.EndDate, '9999-12-31')
          AND s.StartDate <= ISNULL(i.EndDate, '9999-12-31')
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50101, N'Потребителят вече има абонамент за този период.', 1;
    END
END
GO

/* ---------------------------------------------------------------------
   Тригер 2: одит на плащанията (вкл. възстановени суми) в AuditLog.
   --------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.trg_Payments_Audit
ON dbo.Payments
AFTER INSERT, UPDATE
AS
BEGIN
    INSERT INTO dbo.AuditLog (TableName, Action, RecordID, Details)
    SELECT N'Payments',
           CASE WHEN d.PaymentID IS NULL THEN N'INSERT' ELSE N'UPDATE' END,
           i.PaymentID,
           CONCAT(N'Amount=', i.Amount, N'; Status=',
                  CASE WHEN d.PaymentID IS NULL THEN i.Status
                       ELSE CONCAT(d.Status, N' -> ', i.Status) END)
    FROM inserted i
    LEFT JOIN deleted d ON d.PaymentID = i.PaymentID;
END
GO
