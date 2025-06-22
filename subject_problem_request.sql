-- 1. Create Database
CREATE DATABASE SubjectChangeDB;
GO

USE SubjectChangeDB;
GO

-- 2. Create SubjectAllotments Table
CREATE TABLE SubjectAllotments (
    StudentID VARCHAR(50),
    SubjectID VARCHAR(50),
    Is_Valid BIT
);
GO

-- 3. Create SubjectRequest Table
CREATE TABLE SubjectRequest (
    StudentID VARCHAR(50),
    SubjectID VARCHAR(50)
);
GO

-- 4. Insert Sample Data into SubjectAllotments
INSERT INTO SubjectAllotments (StudentID, SubjectID, Is_Valid) VALUES
('159103036', 'PO1491', 1),
('159103036', 'PO1492', 0),
('159103036', 'PO1493', 0),
('159103036', 'PO1494', 0),
('159103036', 'PO1495', 0);
GO

-- 5. Insert Sample Data into SubjectRequest
INSERT INTO SubjectRequest (StudentID, SubjectID) VALUES
('159103036', 'PO1496'),  -- Change subject
('159103037', 'PO1498');  -- New student
GO

-- 6. Create Stored Procedure
CREATE PROCEDURE ProcessSubjectRequests
AS
BEGIN
    DECLARE @StudentID VARCHAR(50);
    DECLARE @RequestedSubjectID VARCHAR(50);
    DECLARE @CurrentSubjectID VARCHAR(50);

    DECLARE request_cursor CURSOR FOR
        SELECT StudentID, SubjectID FROM SubjectRequest;

    OPEN request_cursor;

    FETCH NEXT FROM request_cursor INTO @StudentID, @RequestedSubjectID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM SubjectAllotments WHERE StudentID = @StudentID
        )
        BEGIN
            -- New student: insert request as valid
            INSERT INTO SubjectAllotments (StudentID, SubjectID, Is_Valid)
            VALUES (@StudentID, @RequestedSubjectID, 1);
        END
        ELSE
        BEGIN
            -- Get current subject
            SELECT @CurrentSubjectID = SubjectID
            FROM SubjectAllotments
            WHERE StudentID = @StudentID AND Is_Valid = 1;

            IF @CurrentSubjectID != @RequestedSubjectID
            BEGIN
                -- Invalidate all existing records
                UPDATE SubjectAllotments
                SET Is_Valid = 0
                WHERE StudentID = @StudentID;

                -- Insert new valid record
                INSERT INTO SubjectAllotments (StudentID, SubjectID, Is_Valid)
                VALUES (@StudentID, @RequestedSubjectID, 1);
            END
            -- Else do nothing
        END

        FETCH NEXT FROM request_cursor INTO @StudentID, @RequestedSubjectID;
    END

    CLOSE request_cursor;
    DEALLOCATE request_cursor;
END;
GO

-- 7. Execute the Stored Procedure
EXEC ProcessSubjectRequests;
GO

-- 8. Final Output from SubjectAllotments
SELECT * FROM SubjectAllotments;
GO
