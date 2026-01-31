-- CET321 Final Project - Tuğba Aslandere

USE master;
GO

IF DB_ID(N'CET321_Final_Tugba') IS NOT NULL
BEGIN
    ALTER DATABASE CET321_Final_Tugba SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CET321_Final_Tugba;
END
GO

CREATE DATABASE CET321_Final_Tugba;
GO
USE CET321_Final_Tugba;
GO


-- 1) TABLES (DDL #1 = CREATE)


CREATE TABLE dbo.Student (
    student_id     INT IDENTITY(1,1) PRIMARY KEY,
    student_name   NVARCHAR(100) NOT NULL,
    student_email  NVARCHAR(150) NOT NULL UNIQUE,
    created_at     DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);

CREATE TABLE dbo.Course (
    course_id      INT IDENTITY(1,1) PRIMARY KEY,
    course_name    NVARCHAR(120) NOT NULL,
    department     NVARCHAR(120) NULL
);

CREATE TABLE dbo.[Plan] (
    plan_id        INT IDENTITY(1,1) PRIMARY KEY,
    plan_name      NVARCHAR(80) NOT NULL,
    price          DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    max_questions  INT NOT NULL CHECK (max_questions >= 0),
    duration_days  INT NOT NULL CHECK (duration_days > 0)
);

CREATE TABLE dbo.Transcript (
    transcript_id  INT IDENTITY(1,1) PRIMARY KEY,
    student_id     INT NOT NULL UNIQUE,
    file_url       NVARCHAR(300) NULL,
    status         NVARCHAR(30) NOT NULL DEFAULT 'uploaded',
    verified_at    DATETIME2 NULL,
    CONSTRAINT FK_Transcript_Student FOREIGN KEY (student_id)
        REFERENCES dbo.Student(student_id)
);

CREATE TABLE dbo.Subscription (
    subscription_id INT IDENTITY(1,1) PRIMARY KEY,
    student_id      INT NOT NULL,
    plan_id         INT NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    status          NVARCHAR(20) NOT NULL,
    CONSTRAINT CK_Subscription_Dates CHECK (end_date > start_date),
    CONSTRAINT CK_Subscription_Status CHECK (status IN ('active','inactive','expired','cancelled')),
    CONSTRAINT FK_Subscription_Student FOREIGN KEY (student_id)
        REFERENCES dbo.Student(student_id),
    CONSTRAINT FK_Subscription_Plan FOREIGN KEY (plan_id)
        REFERENCES dbo.[Plan](plan_id)
);

CREATE UNIQUE INDEX UX_Subscription_OneActive
ON dbo.Subscription(student_id)
WHERE status = 'active';
GO

CREATE TABLE dbo.Note (
    note_id       INT IDENTITY(1,1) PRIMARY KEY,
    student_id    INT NOT NULL,
    course_id     INT NOT NULL,
    title         NVARCHAR(150) NOT NULL,
    file_url      NVARCHAR(300) NULL,
    price         DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    published_at  DATETIME2 NULL,
    note_description NVARCHAR(300) NULL,
    CONSTRAINT FK_Note_Student FOREIGN KEY (student_id)
        REFERENCES dbo.Student(student_id),
    CONSTRAINT FK_Note_Course FOREIGN KEY (course_id)
        REFERENCES dbo.Course(course_id)
);

CREATE TABLE dbo.Question (
    question_id          INT IDENTITY(1,1) PRIMARY KEY,
    student_id           INT NOT NULL,
    course_id            INT NOT NULL,
    original_question_id INT NULL,
    title                NVARCHAR(150) NOT NULL,
    content              NVARCHAR(MAX) NOT NULL,
    status               NVARCHAR(30) NOT NULL DEFAULT 'open',
    created_at           DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Question_Status CHECK (status IN ('open','closed','archived')),
    CONSTRAINT FK_Question_Student FOREIGN KEY (student_id)
        REFERENCES dbo.Student(student_id),
    CONSTRAINT FK_Question_Course FOREIGN KEY (course_id)
        REFERENCES dbo.Course(course_id),
    CONSTRAINT FK_Question_Original FOREIGN KEY (original_question_id)
        REFERENCES dbo.Question(question_id)
);

CREATE TABLE dbo.Answer (
    answer_id      INT IDENTITY(1,1) PRIMARY KEY,
    question_id    INT NOT NULL,
    student_id     INT NOT NULL,
    content        NVARCHAR(MAX) NOT NULL,
    reward_amount  DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (reward_amount >= 0),
    status         NVARCHAR(30) NOT NULL DEFAULT 'pending',
    created_at     DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Answer_Status CHECK (status IN ('pending','verified','rejected')),
    CONSTRAINT FK_Answer_Question FOREIGN KEY (question_id)
        REFERENCES dbo.Question(question_id),
    CONSTRAINT FK_Answer_Student FOREIGN KEY (student_id)
        REFERENCES dbo.Student(student_id)
);

CREATE TABLE dbo.Pass (
    pass_id        INT IDENTITY(1,1) PRIMARY KEY,
    transcript_id  INT NOT NULL,
    course_id      INT NOT NULL,
    student_id     INT NOT NULL,
    pass_record    NVARCHAR(50) NULL,     -- e.g., grade/letter
    status         NVARCHAR(20) NOT NULL DEFAULT 'pending',
    verified_at    DATETIME2 NULL,
    CONSTRAINT CK_Pass_Status CHECK (status IN ('pending','verified','rejected')),
     CONSTRAINT FK_Pass_student_id FOREIGN KEY (student_id)
        REFERENCES dbo.Transcript(student_id),
    CONSTRAINT FK_Pass_Transcript FOREIGN KEY (transcript_id)
        REFERENCES dbo.Transcript(transcript_id),
    CONSTRAINT FK_Pass_Course FOREIGN KEY (course_id)
        REFERENCES dbo.Course(course_id)
);

CREATE TABLE dbo.Purchase (
    purchase_id    INT IDENTITY(1,1) PRIMARY KEY,
    student_id     INT NOT NULL,   -- buyer
    note_id        INT NOT NULL,
    purchase_date  DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    price          DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    CONSTRAINT FK_Purchase_Student FOREIGN KEY (student_id)
        REFERENCES dbo.Student(student_id),
    CONSTRAINT FK_Purchase_Note FOREIGN KEY (note_id)
        REFERENCES dbo.Note(note_id)
);

CREATE TABLE dbo.SubscriptionUsage (
    usage_id        INT IDENTITY(1,1) PRIMARY KEY,
    subscription_id INT NOT NULL,
    question_id     INT NOT NULL,
    used_at         DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    remaining_quota INT NOT NULL CHECK (remaining_quota >= 0),
    CONSTRAINT FK_Usage_Subscription FOREIGN KEY (subscription_id)
        REFERENCES dbo.Subscription(subscription_id),
    CONSTRAINT FK_Usage_Question FOREIGN KEY (question_id)
        REFERENCES dbo.Question(question_id)
);

CREATE TABLE dbo.NoteRating (
    note_rating_id  INT IDENTITY(1,1) PRIMARY KEY,
    student_id      INT NOT NULL,
    note_id         INT NOT NULL,
    score           INT NOT NULL CHECK (score BETWEEN 1 AND 5),
    optional_comment NVARCHAR(300) NULL,
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_NoteRating_Student FOREIGN KEY (student_id)
        REFERENCES dbo.Student(student_id),
    CONSTRAINT FK_NoteRating_Note FOREIGN KEY (note_id)
        REFERENCES dbo.Note(note_id),
    CONSTRAINT UQ_NoteRating_OnePerStudent UNIQUE (student_id, note_id)
);

CREATE TABLE dbo.AnswerRating (
    answer_rating_id INT IDENTITY(1,1) PRIMARY KEY,
    student_id       INT NOT NULL,
    answer_id        INT NOT NULL,
    score            INT NOT NULL CHECK (score BETWEEN 1 AND 5),
    optional_comment NVARCHAR(300) NULL,
    created_at       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_AnswerRating_Student FOREIGN KEY (student_id)
        REFERENCES dbo.Student(student_id),
    CONSTRAINT FK_AnswerRating_Answer FOREIGN KEY (answer_id)
        REFERENCES dbo.Answer(answer_id),
    CONSTRAINT UQ_AnswerRating_OnePerStudent UNIQUE (student_id, answer_id)
);

CREATE TABLE dbo.Payment (
    payment_id      INT IDENTITY(1,1) PRIMARY KEY,
    student_id      INT NOT NULL,
    payment_type    NVARCHAR(30) NOT NULL,  -- subscription / note_purchase / note_payout / answer_payout
    amount          DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    status          NVARCHAR(20) NOT NULL DEFAULT 'paid',
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    subscription_id INT NULL,
    purchase_id     INT NULL,
    answer_id       INT NULL,

    CONSTRAINT CK_Payment_SourceOne CHECK (
        (subscription_id IS NOT NULL AND purchase_id IS NULL AND answer_id IS NULL)
        OR (subscription_id IS NULL AND purchase_id IS NOT NULL AND answer_id IS NULL)
        OR (subscription_id IS NULL AND purchase_id IS NULL AND answer_id IS NOT NULL)
    ),

    CONSTRAINT FK_Payment_Student FOREIGN KEY (student_id)
        REFERENCES dbo.Student(student_id),
    CONSTRAINT FK_Payment_Subscription FOREIGN KEY (subscription_id)
        REFERENCES dbo.Subscription(subscription_id),
    CONSTRAINT FK_Payment_Purchase FOREIGN KEY (purchase_id)
        REFERENCES dbo.Purchase(purchase_id),
    CONSTRAINT FK_Payment_Answer FOREIGN KEY (answer_id)
        REFERENCES dbo.Answer(answer_id)
);

CREATE UNIQUE INDEX UX_Payment_Subscription
ON dbo.Payment(subscription_id)
WHERE subscription_id IS NOT NULL;

CREATE UNIQUE INDEX UX_Payment_Answer
ON dbo.Payment(answer_id)
WHERE answer_id IS NOT NULL;
GO


-- 2) VIEWS (2 meaningful views)


-- View 1: Note rating summary (avg + count)
CREATE VIEW dbo.vw_NoteRatingSummary
AS
SELECT
    n.note_id,
    n.title,
    c.course_name,
    s.student_name AS uploader_name,
    n.price,
    AVG(CAST(nr.score AS DECIMAL(10,2))) AS avg_score,
    COUNT(nr.note_rating_id) AS rating_count
FROM dbo.Note n
JOIN dbo.Course c ON c.course_id = n.course_id
JOIN dbo.Student s ON s.student_id = n.student_id
LEFT JOIN dbo.NoteRating nr ON nr.note_id = n.note_id
GROUP BY n.note_id, n.title, c.course_name, s.student_name, n.price;
GO

-- View 2: Question + answer count
CREATE VIEW dbo.vw_QuestionAnswerSummary
AS
SELECT
    q.question_id,
    q.title,
    c.course_name,
    st.student_name AS asked_by,
    q.status,
    q.created_at,
    COUNT(a.answer_id) AS answer_count
FROM dbo.Question q
JOIN dbo.Course c ON c.course_id = q.course_id
JOIN dbo.Student st ON st.student_id = q.student_id
LEFT JOIN dbo.Answer a ON a.question_id = q.question_id
GROUP BY q.question_id, q.title, c.course_name, st.student_name, q.status, q.created_at;
GO


-- 3) STORED PROCEDURES (2 meaningful procedures)


-- Procedure 1: Subscribe a student (creates subscription + payment)
CREATE OR ALTER PROCEDURE dbo.sp_SubscribeStudent
    @student_id INT,
    @plan_id INT,
    @start_date DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @start_date IS NULL
        SET @start_date = CAST(GETDATE() AS DATE);

    -- rule: only 1 active at a time
    IF EXISTS (SELECT 1 FROM dbo.Subscription WHERE student_id = @student_id AND status = 'active')
        THROW 50001, 'Student already has an active subscription.', 1;

    DECLARE @duration INT = (SELECT duration_days FROM dbo.[Plan] WHERE plan_id = @plan_id);
    IF @duration IS NULL
        THROW 50002, 'Plan not found.', 1;

    DECLARE @end_date DATE = DATEADD(DAY, @duration, @start_date);

    INSERT INTO dbo.Subscription(student_id, plan_id, start_date, end_date, status)
    VALUES (@student_id, @plan_id, @start_date, @end_date, 'active');

    DECLARE @sub_id INT = SCOPE_IDENTITY();
    DECLARE @price DECIMAL(10,2) = (SELECT price FROM dbo.[Plan] WHERE plan_id = @plan_id);

    INSERT INTO dbo.Payment(student_id, payment_type, amount, status, subscription_id)
    VALUES (@student_id, 'subscription', @price, 'paid', @sub_id);
END
GO

-- Procedure 2: Purchase a note (creates Purchase; payments will be created by trigger)
CREATE OR ALTER PROCEDURE dbo.sp_PurchaseNote
    @buyer_student_id INT,
    @note_id INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @price DECIMAL(10,2) = (SELECT price FROM dbo.Note WHERE note_id = @note_id);
    IF @price IS NULL
        THROW 50003, 'Note not found.', 1;

    INSERT INTO dbo.Purchase(student_id, note_id, price)
    VALUES (@buyer_student_id, @note_id, @price);

END
GO

-- 4) TRIGGERS (2 meaningful triggers)


-- Trigger 1: Each purchase creates two payments (buyer + seller)
CREATE OR ALTER TRIGGER dbo.trg_Purchase_CreatePayments
ON dbo.Purchase
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Payment(student_id, payment_type, amount, status, purchase_id)
    SELECT
        i.student_id,
        'note_purchase',
        i.price,
        'paid',
        i.purchase_id
    FROM inserted i
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Payment p
        WHERE p.purchase_id = i.purchase_id AND p.payment_type = 'note_purchase' AND p.student_id = i.student_id
    );

    INSERT INTO dbo.Payment(student_id, payment_type, amount, status, purchase_id)
    SELECT
        n.student_id AS seller_student_id,
        'note_payout',
        i.price,
        'paid',
        i.purchase_id
    FROM inserted i
    JOIN dbo.Note n ON n.note_id = i.note_id
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Payment p
        WHERE p.purchase_id = i.purchase_id AND p.payment_type = 'note_payout' AND p.student_id = n.student_id
    );
END
GO

-- Trigger 2: Verified answer creates exactly one payment
CREATE OR ALTER TRIGGER dbo.trg_Answer_Verified_CreatePayment
ON dbo.Answer
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Payment(student_id, payment_type, amount, status, answer_id)
    SELECT
        i.student_id,
        'answer_payout',
        i.reward_amount,
        'paid',
        i.answer_id
    FROM inserted i
    JOIN deleted d ON d.answer_id = i.answer_id
    WHERE i.status = 'verified'
      AND d.status <> 'verified'
      AND NOT EXISTS (SELECT 1 FROM dbo.Payment p WHERE p.answer_id = i.answer_id);
END
GO


-- 5) SAMPLE DATA (INSERT INTO)


-- Students
INSERT INTO dbo.Student(student_name, student_email) VALUES
(N'Tuğba Aslandere', N'tugba@example.com'),
(N'Ayşe Demir',     N'ayse@example.com'),
(N'Mehmet Yılmaz',  N'mehmet@example.com');

-- Courses
INSERT INTO dbo.Course(course_name, department) VALUES
(N'Database Systems', N'CET'),
(N'Operating Systems', N'CET'),
(N'Linear Algebra', N'MATH');

-- Plans
INSERT INTO dbo.[Plan](plan_name, price, max_questions, duration_days) VALUES
(N'Basic',  49.90, 10, 30),
(N'Pro',    99.90, 30, 90);

-- Transcripts (1:1)
INSERT INTO dbo.Transcript(student_id, file_url, status, verified_at) VALUES
(1, N'link://tugba_transcript.pdf', N'verified', SYSDATETIME()),
(2, N'link://ayse_transcript.pdf',  N'uploaded', NULL),
(3, N'link://mehmet_transcript.pdf',N'verified', SYSDATETIME());

-- Pass records (derived from transcript)
INSERT INTO dbo.Pass(transcript_id, course_id, student_id, pass_record, status, verified_at) VALUES
(1, 1, 1, N'A', N'verified', SYSDATETIME()),
(1, 3, 1, N'B', N'verified', SYSDATETIME());

-- Notes
INSERT INTO dbo.Note(student_id, course_id, title, file_url, price, published_at, note_description) VALUES
(1, 1, N'Normalization Cheat Sheet', N'link://note1.pdf', 25.00, SYSDATETIME(), N'1NF-2NF-3NF-BCNF'),
(2, 1, N'SQL Joins Summary',         N'link://note2.pdf', 30.00, SYSDATETIME(), N'JOIN examples'),
(3, 3, N'Linear Algebra Notes',      N'link://note3.pdf', 20.00, SYSDATETIME(), N'Matrices and vectors');

-- Questions
INSERT INTO dbo.Question(student_id, course_id, original_question_id, title, content, status) VALUES
(1, 1, NULL, N'What is BCNF?', N'Can someone explain BCNF with example?', 'open'),
(2, 1, NULL, N'LEFT JOIN vs INNER JOIN', N'What is the difference?', 'open');

-- Answers
INSERT INTO dbo.Answer(question_id, student_id, content, reward_amount, status) VALUES
(1, 2, N'BCNF is a stronger form of 3NF...', 10.00, 'pending'),
(2, 3, N'LEFT JOIN keeps all rows from left table...', 5.00, 'pending');

-- Subscribe student (procedure creates subscription + payment)
EXEC dbo.sp_SubscribeStudent @student_id = 1, @plan_id = 2;

-- Usage records
INSERT INTO dbo.SubscriptionUsage(subscription_id, question_id, remaining_quota) VALUES
(1, 1, 29),
(1, 2, 28);

-- Ratings
INSERT INTO dbo.NoteRating(student_id, note_id, score, optional_comment) VALUES
(3, 1, 5, N'Very useful'),
(1, 2, 4, N'Good summary');

INSERT INTO dbo.AnswerRating(student_id, answer_id, score, optional_comment) VALUES
(1, 1, 5, N'Clear explanation');

-- Purchase note (procedure inserts Purchase; trigger creates 2 payments)
EXEC dbo.sp_PurchaseNote @buyer_student_id = 1, @note_id = 3;

-- Verify an answer (trigger creates answer payout payment)
UPDATE dbo.Answer
SET status = 'verified'
WHERE answer_id = 1;
GO


-- 6) SELECT QUERIES (4 functional, multi-table)


-- SELECT 1: A student’s questions + answers
SELECT s.student_name, q.title AS question_title, a.content AS answer_content
FROM dbo.Student s
JOIN dbo.Question q ON q.student_id = s.student_id
LEFT JOIN dbo.Answer a ON a.question_id = q.question_id
WHERE s.student_id = 1;

-- SELECT 2: Active subscription details + plan
SELECT s.student_name, p.plan_name, p.max_questions, sub.start_date, sub.end_date, sub.status
FROM dbo.Student s
JOIN dbo.Subscription sub ON sub.student_id = s.student_id
JOIN dbo.[Plan] p ON p.plan_id = sub.plan_id
WHERE sub.status = 'active';

-- SELECT 3: Notes in a course + avg rating
SELECT *
FROM dbo.vw_NoteRatingSummary
WHERE course_name = N'Database Systems';

-- SELECT 4: Purchases + payments (buyer side)
SELECT s.student_name, n.title, pr.purchase_date, pay.payment_type, pay.amount
FROM dbo.Purchase pr
JOIN dbo.Student s ON s.student_id = pr.student_id
JOIN dbo.Note n ON n.note_id = pr.note_id
JOIN dbo.Payment pay ON pay.purchase_id = pr.purchase_id
WHERE pr.student_id = 1
ORDER BY pr.purchase_date DESC;


-- 7) REQUIRED UPDATE / DELETE EXAMPLES (Functional)


-- UPDATE #1: change student email
UPDATE dbo.Student
SET student_email = N'tugba_updated@example.com'
WHERE student_id = 1;

-- UPDATE #2: change note price
UPDATE dbo.Note
SET price = price + 5
WHERE note_id = 1;

-- DELETE #1 (safe demo): delete a note rating then rollback
BEGIN TRAN;
    DELETE FROM dbo.NoteRating
    WHERE student_id = 3 AND note_id = 1;
ROLLBACK;

-- DELETE #2 (safe demo): delete a usage record then rollback
BEGIN TRAN;
    DELETE FROM dbo.SubscriptionUsage
    WHERE usage_id = 1;
ROLLBACK;
GO