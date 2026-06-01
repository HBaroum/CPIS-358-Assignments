-- Optional manual database setup script for StudySyncDB_FinalProject_Clean.
-- The ASP.NET website also creates this database and tables automatically when the site runs.

IF DB_ID(N'StudySyncDB_FinalProject_Clean') IS NULL
    CREATE DATABASE StudySyncDB_FinalProject_Clean;
GO

USE StudySyncDB_FinalProject_Clean;
GO

IF OBJECT_ID('dbo.Users', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Users
    (
        UserId INT IDENTITY(1,1) PRIMARY KEY,
        FullName NVARCHAR(100) NOT NULL,
        StudentId NVARCHAR(20) NOT NULL,
        Email NVARCHAR(100) NOT NULL UNIQUE,
        Course NVARCHAR(50) NOT NULL,
        StudyGoal NVARCHAR(100) NOT NULL,
        AvailableTime NVARCHAR(100) NOT NULL,
        StudyLevel NVARCHAR(30) NOT NULL DEFAULT N'Beginner',
        PreferredMode NVARCHAR(30) NOT NULL,
        Password NVARCHAR(100) NOT NULL,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO

IF COL_LENGTH('dbo.Users', 'StudyLevel') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD StudyLevel NVARCHAR(30) NOT NULL CONSTRAINT DF_Users_StudyLevel DEFAULT N'Beginner';
END
GO

IF OBJECT_ID('dbo.StudySessions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.StudySessions
    (
        SessionId INT IDENTITY(1,1) PRIMARY KEY,
        UserId INT NOT NULL,
        Course NVARCHAR(50) NOT NULL,
        StudyGoal NVARCHAR(100) NOT NULL,
        AvailableTime NVARCHAR(100) NOT NULL,
        PreferredMode NVARCHAR(30) NOT NULL,
        Notes NVARCHAR(250) NULL,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_StudySessions_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId)
    );
END
GO

IF OBJECT_ID('dbo.SessionParticipants', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SessionParticipants
    (
        ParticipantId INT IDENTITY(1,1) PRIMARY KEY,
        SessionId INT NOT NULL,
        UserId INT NOT NULL,
        JoinedAt DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_Participants_Session FOREIGN KEY (SessionId) REFERENCES dbo.StudySessions(SessionId) ON DELETE CASCADE,
        CONSTRAINT FK_Participants_User FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId),
        CONSTRAINT UQ_SessionUser UNIQUE (SessionId, UserId)
    );
END
GO

-- Make every session creator appear as a participant in their own session.
INSERT INTO dbo.SessionParticipants (SessionId, UserId)
SELECT s.SessionId, s.UserId
FROM dbo.StudySessions s
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.SessionParticipants p
    WHERE p.SessionId = s.SessionId
      AND p.UserId = s.UserId
);
GO
