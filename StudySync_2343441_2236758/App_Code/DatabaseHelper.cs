using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Text;

public class StudyUser
{
    public int UserId { get; set; }
    public string FullName { get; set; }
    public string Email { get; set; }
}

public static class DatabaseHelper
{
    private const string DatabaseName = "StudySyncDB_FinalProject_Clean";

    // ── Password Hashing ──────────────────────────────────────────────────
    public static string HashPassword(string password)
    {
        using (SHA256 sha256 = SHA256.Create())
        {
            byte[] bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            StringBuilder sb = new StringBuilder();
            foreach (byte b in bytes)
                sb.Append(b.ToString("x2"));
            return sb.ToString();
        }
    }

    private static string ConnectionString
    {
        get { return ConfigurationManager.ConnectionStrings["StudySyncDb"].ConnectionString; }
    }

    private static string MasterConnectionString
    {
        get { return @"Data Source=(LocalDB)\MSSQLLocalDB;Initial Catalog=master;Integrated Security=True"; }
    }

    public static void Initialize()
    {
        EnsureDatabaseExists();
        EnsureTablesExist();
    }

    private static void EnsureDatabaseExists()
    {
        using (SqlConnection connection = new SqlConnection(MasterConnectionString))
        {
            connection.Open();
            string sql = "IF DB_ID(N'" + DatabaseName + "') IS NULL CREATE DATABASE [" + DatabaseName + "]";

            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                command.ExecuteNonQuery();
            }
        }
    }

    private static void EnsureTablesExist()
    {
        using (SqlConnection connection = new SqlConnection(ConnectionString))
        {
            connection.Open();

            string createUsersTable = @"
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
    )
END";

            string createSessionsTable = @"
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
    )
END";

            string createParticipantsTable = @"
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
    )
END";

            using (SqlCommand command = new SqlCommand(createUsersTable, connection))
                command.ExecuteNonQuery();

            using (SqlCommand command = new SqlCommand(createSessionsTable, connection))
                command.ExecuteNonQuery();

            using (SqlCommand command = new SqlCommand(createParticipantsTable, connection))
                command.ExecuteNonQuery();

            EnsureUsersStudyLevelColumn(connection);
            EnsureSessionCreatorsAreParticipants(connection);
        }
    }

    private static void EnsureUsersStudyLevelColumn(SqlConnection connection)
    {
        string sql = @"
IF COL_LENGTH('dbo.Users', 'StudyLevel') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD StudyLevel NVARCHAR(30) NOT NULL CONSTRAINT DF_Users_StudyLevel DEFAULT N'Beginner'
END";

        using (SqlCommand command = new SqlCommand(sql, connection))
        {
            command.ExecuteNonQuery();
        }
    }

    private static void EnsureSessionCreatorsAreParticipants(SqlConnection connection)
    {
        string sql = @"
IF OBJECT_ID('dbo.SessionParticipants', 'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.SessionParticipants (SessionId, UserId)
    SELECT s.SessionId, s.UserId
    FROM dbo.StudySessions s
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.SessionParticipants p
        WHERE p.SessionId = s.SessionId
          AND p.UserId = s.UserId
    )
END";

        using (SqlCommand command = new SqlCommand(sql, connection))
        {
            command.ExecuteNonQuery();
        }
    }

    private static void InitializeDatabaseOnly()
    {
        EnsureDatabaseExists();
        EnsureTablesExist();
    }

    public static int AddUser(string fullName, string studentId, string email, string course, string studyGoal, string availableTime, string studyLevel, string preferredMode, string password)
    {
        InitializeDatabaseOnly();

        using (SqlConnection connection = new SqlConnection(ConnectionString))
        {
            string sql = @"
INSERT INTO dbo.Users (FullName, StudentId, Email, Course, StudyGoal, AvailableTime, StudyLevel, PreferredMode, Password)
VALUES (@FullName, @StudentId, @Email, @Course, @StudyGoal, @AvailableTime, @StudyLevel, @PreferredMode, @Password);
SELECT SCOPE_IDENTITY();";

            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                command.Parameters.AddWithValue("@FullName", fullName);
                command.Parameters.AddWithValue("@StudentId", studentId);
                command.Parameters.AddWithValue("@Email", email);
                command.Parameters.AddWithValue("@Course", course);
                command.Parameters.AddWithValue("@StudyGoal", studyGoal);
                command.Parameters.AddWithValue("@AvailableTime", availableTime);
                command.Parameters.AddWithValue("@StudyLevel", studyLevel);
                command.Parameters.AddWithValue("@PreferredMode", preferredMode);
                command.Parameters.AddWithValue("@Password", HashPassword(password));

                connection.Open();
                return Convert.ToInt32(command.ExecuteScalar());
            }
        }
    }

    public static StudyUser ValidateUser(string email, string password)
    {
        InitializeDatabaseOnly();

        using (SqlConnection connection = new SqlConnection(ConnectionString))
        {
            string sql = "SELECT UserId, FullName, Email FROM dbo.Users WHERE Email = @Email AND Password = @Password";

            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                command.Parameters.AddWithValue("@Email", email);
                command.Parameters.AddWithValue("@Password", HashPassword(password));
                connection.Open();

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        StudyUser user = new StudyUser();
                        user.UserId = Convert.ToInt32(reader["UserId"]);
                        user.FullName = reader["FullName"].ToString();
                        user.Email = reader["Email"].ToString();
                        return user;
                    }
                }
            }
        }

        return null;
    }


    public static bool ResetPassword(string email, string studentId, string newPassword)
    {
        InitializeDatabaseOnly();

        using (SqlConnection connection = new SqlConnection(ConnectionString))
        {
            string sql = @"
UPDATE dbo.Users
SET Password = @Password
WHERE Email = @Email
  AND StudentId = @StudentId";

            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                command.Parameters.AddWithValue("@Email", email);
                command.Parameters.AddWithValue("@StudentId", studentId);
                command.Parameters.AddWithValue("@Password", HashPassword(newPassword));

                connection.Open();
                int affectedRows = command.ExecuteNonQuery();
                return affectedRows > 0;
            }
        }
    }

    public static void AddStudySession(int userId, string course, string studyGoal, string availableTime, string preferredMode, string notes)
    {
        InitializeDatabaseOnly();

        using (SqlConnection connection = new SqlConnection(ConnectionString))
        {
            connection.Open();

            string insertSessionSql = @"
INSERT INTO dbo.StudySessions (UserId, Course, StudyGoal, AvailableTime, PreferredMode, Notes)
VALUES (@UserId, @Course, @StudyGoal, @AvailableTime, @PreferredMode, @Notes);
SELECT SCOPE_IDENTITY();";

            int newSessionId;

            using (SqlCommand command = new SqlCommand(insertSessionSql, connection))
            {
                command.Parameters.AddWithValue("@UserId", userId);
                command.Parameters.AddWithValue("@Course", course);
                command.Parameters.AddWithValue("@StudyGoal", studyGoal);
                command.Parameters.AddWithValue("@AvailableTime", availableTime);
                command.Parameters.AddWithValue("@PreferredMode", preferredMode);
                command.Parameters.AddWithValue("@Notes", notes);

                newSessionId = Convert.ToInt32(command.ExecuteScalar());
            }

            string insertCreatorSql = @"
IF NOT EXISTS (SELECT 1 FROM dbo.SessionParticipants WHERE SessionId = @SessionId AND UserId = @UserId)
BEGIN
    INSERT INTO dbo.SessionParticipants (SessionId, UserId)
    VALUES (@SessionId, @UserId)
END";

            using (SqlCommand command = new SqlCommand(insertCreatorSql, connection))
            {
                command.Parameters.AddWithValue("@SessionId", newSessionId);
                command.Parameters.AddWithValue("@UserId", userId);
                command.ExecuteNonQuery();
            }
        }
    }

    public static void UpdateStudySession(int sessionId, int userId, string course, string studyGoal, string availableTime, string preferredMode, string notes)
    {
        InitializeDatabaseOnly();

        using (SqlConnection connection = new SqlConnection(ConnectionString))
        {
            string sql = @"
UPDATE dbo.StudySessions
SET Course = @Course,
    StudyGoal = @StudyGoal,
    AvailableTime = @AvailableTime,
    PreferredMode = @PreferredMode,
    Notes = @Notes
WHERE SessionId = @SessionId
  AND UserId = @UserId";

            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                command.Parameters.AddWithValue("@SessionId", sessionId);
                command.Parameters.AddWithValue("@UserId", userId);
                command.Parameters.AddWithValue("@Course", course);
                command.Parameters.AddWithValue("@StudyGoal", studyGoal);
                command.Parameters.AddWithValue("@AvailableTime", availableTime);
                command.Parameters.AddWithValue("@PreferredMode", preferredMode);
                command.Parameters.AddWithValue("@Notes", notes);

                connection.Open();
                command.ExecuteNonQuery();
            }
        }
    }

    public static void DeleteStudySession(int sessionId, int userId)
    {
        InitializeDatabaseOnly();

        using (SqlConnection connection = new SqlConnection(ConnectionString))
        {
            string sql = "DELETE FROM dbo.StudySessions WHERE SessionId = @SessionId AND UserId = @UserId";

            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                command.Parameters.AddWithValue("@SessionId", sessionId);
                command.Parameters.AddWithValue("@UserId", userId);

                connection.Open();
                command.ExecuteNonQuery();
            }
        }
    }

    public static DataTable GetMyStudySessions(int userId, string keyword)
    {
        InitializeDatabaseOnly();

        using (SqlConnection connection = new SqlConnection(ConnectionString))
        {
            string sql = @"
SELECT s.SessionId,
       u.FullName,
       s.Course,
       s.StudyGoal,
       s.AvailableTime,
       s.PreferredMode,
       s.Notes,
       ISNULL(STUFF((
            SELECT ', ' + u2.FullName
            FROM dbo.SessionParticipants p2
            INNER JOIN dbo.Users u2 ON p2.UserId = u2.UserId
            WHERE p2.SessionId = s.SessionId
            ORDER BY u2.FullName
            FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, ''), 'No students yet') AS JoinedStudents,
       CONVERT(VARCHAR(19), s.CreatedAt, 120) AS CreatedAt
FROM dbo.StudySessions s
INNER JOIN dbo.Users u ON s.UserId = u.UserId
WHERE s.UserId = @UserId
  AND (@Keyword = '' OR s.Course LIKE @Search OR s.StudyGoal LIKE @Search OR s.PreferredMode LIKE @Search OR u.FullName LIKE @Search)
ORDER BY s.CreatedAt DESC";

            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                string cleanKeyword = keyword == null ? "" : keyword.Trim();

                command.Parameters.AddWithValue("@UserId", userId);
                command.Parameters.AddWithValue("@Keyword", cleanKeyword);
                command.Parameters.AddWithValue("@Search", "%" + cleanKeyword + "%");

                using (SqlDataAdapter adapter = new SqlDataAdapter(command))
                {
                    DataTable table = new DataTable();
                    adapter.Fill(table);
                    return table;
                }
            }
        }
    }

    public static DataTable GetStudySessionById(int sessionId, int userId)
    {
        InitializeDatabaseOnly();

        using (SqlConnection connection = new SqlConnection(ConnectionString))
        {
            string sql = @"
SELECT SessionId, Course, StudyGoal, AvailableTime, PreferredMode, Notes
FROM dbo.StudySessions
WHERE SessionId = @SessionId
  AND UserId = @UserId";

            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                command.Parameters.AddWithValue("@SessionId", sessionId);
                command.Parameters.AddWithValue("@UserId", userId);

                using (SqlDataAdapter adapter = new SqlDataAdapter(command))
                {
                    DataTable table = new DataTable();
                    adapter.Fill(table);
                    return table;
                }
            }
        }
    }

    public static DataTable GetAvailableStudySessions(int currentUserId, string keyword)
    {
        InitializeDatabaseOnly();

        using (SqlConnection connection = new SqlConnection(ConnectionString))
        {
            string sql = @"
DECLARE @UserCourse NVARCHAR(50);
DECLARE @UserGoal NVARCHAR(100);

SELECT @UserCourse = Course,
       @UserGoal = StudyGoal
FROM dbo.Users
WHERE UserId = @CurrentUserId;

SELECT s.SessionId,
       s.UserId AS OwnerUserId,
       u.FullName AS CreatedBy,
       s.Course,
       s.StudyGoal,
       s.AvailableTime,
       s.PreferredMode,
       s.Notes,
       CASE
            WHEN s.Course = @UserCourse AND s.StudyGoal = @UserGoal THEN 'Matched'
            ELSE 'Open'
       END AS MatchStatus,
       CASE
            WHEN EXISTS (SELECT 1 FROM dbo.SessionParticipants p WHERE p.SessionId = s.SessionId AND p.UserId = @CurrentUserId) THEN 'Yes'
            ELSE 'No'
       END AS AlreadyJoined,
       ISNULL(STUFF((
            SELECT ', ' + u2.FullName
            FROM dbo.SessionParticipants p2
            INNER JOIN dbo.Users u2 ON p2.UserId = u2.UserId
            WHERE p2.SessionId = s.SessionId
            ORDER BY u2.FullName
            FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, ''), 'No students yet') AS JoinedStudents,
       (SELECT COUNT(*) FROM dbo.SessionParticipants p3 WHERE p3.SessionId = s.SessionId) AS JoinedCount,
       CONVERT(VARCHAR(19), s.CreatedAt, 120) AS CreatedAt
FROM dbo.StudySessions s
INNER JOIN dbo.Users u ON s.UserId = u.UserId
WHERE (@Keyword = '' OR s.Course LIKE @Search OR s.StudyGoal LIKE @Search OR s.PreferredMode LIKE @Search OR u.FullName LIKE @Search)
ORDER BY
       CASE WHEN s.Course = @UserCourse AND s.StudyGoal = @UserGoal THEN 0 ELSE 1 END,
       s.CreatedAt DESC";

            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                string cleanKeyword = keyword == null ? "" : keyword.Trim();

                command.Parameters.AddWithValue("@CurrentUserId", currentUserId);
                command.Parameters.AddWithValue("@Keyword", cleanKeyword);
                command.Parameters.AddWithValue("@Search", "%" + cleanKeyword + "%");

                using (SqlDataAdapter adapter = new SqlDataAdapter(command))
                {
                    DataTable table = new DataTable();
                    adapter.Fill(table);
                    return table;
                }
            }
        }
    }

    public static bool JoinSession(int sessionId, int userId)
    {
        InitializeDatabaseOnly();

        using (SqlConnection connection = new SqlConnection(ConnectionString))
        {
            connection.Open();

            string checkOwnerSql = "SELECT COUNT(1) FROM dbo.StudySessions WHERE SessionId = @SessionId AND UserId = @UserId";

            using (SqlCommand command = new SqlCommand(checkOwnerSql, connection))
            {
                command.Parameters.AddWithValue("@SessionId", sessionId);
                command.Parameters.AddWithValue("@UserId", userId);

                int isOwner = Convert.ToInt32(command.ExecuteScalar());
                if (isOwner > 0)
                {
                    return false;
                }
            }

            string insertSql = @"
IF NOT EXISTS (SELECT 1 FROM dbo.SessionParticipants WHERE SessionId = @SessionId AND UserId = @UserId)
BEGIN
    INSERT INTO dbo.SessionParticipants (SessionId, UserId)
    VALUES (@SessionId, @UserId)
END";

            using (SqlCommand command = new SqlCommand(insertSql, connection))
            {
                command.Parameters.AddWithValue("@SessionId", sessionId);
                command.Parameters.AddWithValue("@UserId", userId);
                command.ExecuteNonQuery();
            }
        }

        return true;
    }

    public static bool IsUserJoined(int sessionId, int userId)
    {
        InitializeDatabaseOnly();

        using (SqlConnection connection = new SqlConnection(ConnectionString))
        {
            string sql = @"SELECT COUNT(1) FROM dbo.SessionParticipants WHERE SessionId = @SessionId AND UserId = @UserId";

            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                command.Parameters.AddWithValue("@SessionId", sessionId);
                command.Parameters.AddWithValue("@UserId", userId);

                connection.Open();
                int count = Convert.ToInt32(command.ExecuteScalar());
                return count > 0;
            }
        }
    }

    public static DataTable GetAllSessionsForHome()
    {
        InitializeDatabaseOnly();

        using (SqlConnection connection = new SqlConnection(ConnectionString))
        {
            string sql = @"
SELECT s.SessionId,
       s.UserId AS OwnerUserId,
       u.FullName AS CreatedBy,
       s.Course,
       s.StudyGoal,
       s.AvailableTime,
       s.PreferredMode,
       s.Notes,
       ISNULL(STUFF((
            SELECT ', ' + u2.FullName
            FROM dbo.SessionParticipants p2
            INNER JOIN dbo.Users u2 ON p2.UserId = u2.UserId
            WHERE p2.SessionId = s.SessionId
            ORDER BY u2.FullName
            FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, ''), 'No students yet') AS JoinedStudents,
       (SELECT COUNT(*) FROM dbo.SessionParticipants p3 WHERE p3.SessionId = s.SessionId) AS StudentCount,
       CONVERT(VARCHAR(19), s.CreatedAt, 120) AS CreatedAt
FROM dbo.StudySessions s
INNER JOIN dbo.Users u ON s.UserId = u.UserId
ORDER BY s.CreatedAt DESC";

            using (SqlCommand command = new SqlCommand(sql, connection))
            {
                using (SqlDataAdapter adapter = new SqlDataAdapter(command))
                {
                    DataTable table = new DataTable();
                    adapter.Fill(table);
                    return table;
                }
            }
        }
    }

    public static bool LeaveSession(int sessionId, int userId)
    {
        InitializeDatabaseOnly();

        using (SqlConnection connection = new SqlConnection(ConnectionString))
        {
            connection.Open();

            string checkOwnerSql = "SELECT COUNT(1) FROM dbo.StudySessions WHERE SessionId = @SessionId AND UserId = @UserId";

            using (SqlCommand command = new SqlCommand(checkOwnerSql, connection))
            {
                command.Parameters.AddWithValue("@SessionId", sessionId);
                command.Parameters.AddWithValue("@UserId", userId);

                int isOwner = Convert.ToInt32(command.ExecuteScalar());
                if (isOwner > 0)
                {
                    return false;
                }
            }

            string deleteSql = "DELETE FROM dbo.SessionParticipants WHERE SessionId = @SessionId AND UserId = @UserId";

            using (SqlCommand command = new SqlCommand(deleteSql, connection))
            {
                command.Parameters.AddWithValue("@SessionId", sessionId);
                command.Parameters.AddWithValue("@UserId", userId);
                command.ExecuteNonQuery();
            }
        }

        return true;
    }

}
