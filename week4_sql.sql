-- Drop existing tables
DROP TABLE IF EXISTS Allotments;
DROP TABLE IF EXISTS UnallotedStudents;
DROP TABLE IF EXISTS StudentPreference;
DROP TABLE IF EXISTS SubjectDetails;
DROP TABLE IF EXISTS StudentDetails;

-- Create tables
CREATE TABLE StudentDetails (
    StudentId INT PRIMARY KEY,
    StudentName VARCHAR(100),
    GPA FLOAT,
    Branch VARCHAR(10),
    Section CHAR(1)
);

CREATE TABLE SubjectDetails (
    SubjectId VARCHAR(10) PRIMARY KEY,
    SubjectName VARCHAR(100),
    MaxSeats INT,
    RemainingSeats INT
);

CREATE TABLE StudentPreference (
    StudentId INT,
    SubjectId VARCHAR(10),
    Preference INT CHECK (Preference BETWEEN 1 AND 5),
    PRIMARY KEY (StudentId, Preference),
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId)
);

CREATE TABLE Allotments (
    SubjectId VARCHAR(10),
    StudentId INT,
    PRIMARY KEY (SubjectId, StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId),
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId)
);

CREATE TABLE UnallotedStudents (
    StudentId INT PRIMARY KEY,
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId)
);

-- Insert sample data
INSERT INTO StudentDetails VALUES
(159103036, 'Mohit Agarwal', 8.9, 'CCE', 'A'),
(159103037, 'Rohit Agarwal', 5.2, 'CCE', 'A'),
(159103038, 'Shohit Garg', 7.1, 'CCE', 'B'),
(159103039, 'Mrinal Malhotra', 7.9, 'CCE', 'A'),
(159103040, 'Mehreet Singh', 5.6, 'CCE', 'A'),
(159103041, 'Arjun Tehlan', 9.2, 'CCE', 'B');

INSERT INTO SubjectDetails VALUES
('PO1491', 'Basics of Political Science', 60, 2),
('PO1492', 'Basics of Accounting', 120, 119),
('PO1493', 'Basics of Financial Markets', 90, 90),
('PO1494', 'Eco philosophy', 60, 50),
('PO1495', 'Automotive Trends', 60, 60);

INSERT INTO StudentPreference VALUES
(159103036, 'PO1491', 1),
(159103036, 'PO1492', 2),
(159103036, 'PO1493', 3),
(159103036, 'PO1494', 4),
(159103036, 'PO1495', 5);

-- Add more preferences for testing (optional)
INSERT INTO StudentPreference VALUES
(159103037, 'PO1493', 1),
(159103037, 'PO1494', 2),
(159103037, 'PO1495', 3),
(159103037, 'PO1491', 4),
(159103037, 'PO1492', 5);

-- Add preferences for all students...

-- Step 1: Drop procedure if it exists
DROP PROCEDURE IF EXISTS AllocateOpenElectives;
GO

-- Step 2: Create the procedure
CREATE PROCEDURE AllocateOpenElectives
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM Allotments;
    DELETE FROM UnallotedStudents;

    DECLARE student_cursor CURSOR FOR
    SELECT StudentId FROM StudentDetails ORDER BY GPA DESC;

    DECLARE @StudentId INT;
    OPEN student_cursor;
    FETCH NEXT FROM student_cursor INTO @StudentId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Preference INT = 1;
        DECLARE @SubjectId VARCHAR(10);
        DECLARE @Found BIT = 0;

        WHILE @Preference <= 5 AND @Found = 0
        BEGIN
            SELECT @SubjectId = SubjectId
            FROM StudentPreference
            WHERE StudentId = @StudentId AND Preference = @Preference;

            IF @SubjectId IS NOT NULL
            BEGIN
                DECLARE @Seats INT;
                SELECT @Seats = RemainingSeats FROM SubjectDetails WHERE SubjectId = @SubjectId;

                IF @Seats > 0
                BEGIN
                    INSERT INTO Allotments (SubjectId, StudentId)
                    VALUES (@SubjectId, @StudentId);

                    UPDATE SubjectDetails
                    SET RemainingSeats = RemainingSeats - 1
                    WHERE SubjectId = @SubjectId;

                    SET @Found = 1;
                END
            END

            SET @Preference = @Preference + 1;
        END

        IF @Found = 0
        BEGIN
            INSERT INTO UnallotedStudents (StudentId)
            VALUES (@StudentId);
        END

        FETCH NEXT FROM student_cursor INTO @StudentId;
    END

    CLOSE student_cursor;
    DEALLOCATE student_cursor;
END;
GO

-- Step 3: Call the procedure separately after creation
EXEC AllocateOpenElectives;

-- Step 4: View results
SELECT * FROM Allotments;
SELECT * FROM UnallotedStudents;

