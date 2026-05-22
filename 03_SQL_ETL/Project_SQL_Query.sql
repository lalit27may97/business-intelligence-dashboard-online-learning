#MielStone1

#CREATE_DATABASE

CREATE DATABASE online_learning;
USE online_learning;

#USERS_TABLE

CREATE TABLE users (
    user_id INT PRIMARY KEY,
    name VARCHAR(100),
    age INT,
    country VARCHAR(50),
    signup_date DATE,
    user_type VARCHAR(10)
);

ALTER TABLE users
ALTER COLUMN signup_date VARCHAR(20);

ALTER TABLE users
ALTER COLUMN country VARCHAR(100);

#COURSES_TABLE

CREATE TABLE courses (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(100),
    category VARCHAR(50),
    difficulty VARCHAR(20),
    price INT
);

#ENROLLMENTS_TABLE

CREATE TABLE enrollments (
    enrollment_id INT PRIMARY KEY,
    user_id INT,
    course_id INT,
    enrollment_date DATE,
    completion_status VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);
ALTER TABLE enrollments
ALTER COLUMN enrollment_date VARCHAR(20);

#ACTIVITY_TABLE

CREATE TABLE activity (
    activity_id INT PRIMARY KEY,
    user_id INT,
    course_id INT,
    date DATE,
    watch_time INT,
    quiz_attempts INT,
    login_count INT,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);

ALTER TABLE activity
ALTER COLUMN date VARCHAR(20);

#PAYMENTS_TABLE

CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    user_id INT,
    amount INT,
    payment_date DATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

ALTER TABLE payments
ALTER COLUMN payment_date VARCHAR(20);

DELETE FROM users;

#DATA_IMPORT

BULK INSERT users
FROM 'C:\Users\lalit\Downloads\Major Project 1.0\users.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

BULK INSERT courses
FROM 'C:\Users\lalit\Downloads\Major Project 1.0\courses.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

BULK INSERT enrollments
FROM 'C:\Users\lalit\Downloads\Major Project 1.0\enrollments.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

BULK INSERT activity
FROM 'C:\Users\lalit\Downloads\Major Project 1.0\activity.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

BULK INSERT payments
FROM 'C:\Users\lalit\Downloads\Major Project 1.0\payments.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);


SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM courses;
SELECT COUNT(*) FROM enrollments;
SELECT COUNT(*) FROM activity;
SELECT COUNT(*) FROM payments;

ALTER TABLE users ADD signup_date_clean DATE;

UPDATE users
SET signup_date_clean = TRY_CONVERT(DATE, signup_date);

ALTER TABLE enrollments ADD enrollment_date_clean DATE;

UPDATE enrollments
SET enrollment_date_clean = TRY_CONVERT(DATE, enrollment_date);

ALTER TABLE activity ADD activity_date_clean DATE;

UPDATE activity
SET activity_date_clean = TRY_CONVERT(DATE, date);

ALTER TABLE payments ADD payment_date_clean DATE;

UPDATE payments
SET payment_date_clean = TRY_CONVERT(DATE, payment_date);

#MileStone2

#Check_Missing_Values

SELECT 
    COUNT(*) - COUNT(user_id) AS missing_user_id,
    COUNT(*) - COUNT(name) AS missing_name,
    COUNT(*) - COUNT(signup_date) AS missing_signup_date
FROM users;

SELECT 
    COUNT(*) - COUNT(course_id) AS missing_course_id,
    COUNT(*) - COUNT(course_name) AS missing_course_name
FROM courses;

SELECT 
    COUNT(*) - COUNT(user_id) AS missing_user_id,
    COUNT(*) - COUNT(course_id) AS missing_course_id
FROM enrollments;

SELECT 
    COUNT(*) - COUNT(user_id) AS missing_user_id,
    COUNT(*) - COUNT(course_id) AS missing_course_id
FROM activity;

SELECT 
    COUNT(*) - COUNT(user_id) AS missing_user_id,
    COUNT(*) - COUNT(amount) AS missing_amount
FROM payments;

#Handle_Missing_Values

UPDATE users
SET country = 'Unknown'
WHERE country IS NULL;

#Remove_Invalid_Age

DELETE FROM users
WHERE age < 10 OR age > 100;

#Remove_Duplicate

WITH cte AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY user_id) AS rn
    FROM users
)
DELETE FROM cte WHERE rn > 1;

WITH cte AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY course_id ORDER BY course_id) AS rn
    FROM courses
)
DELETE FROM cte WHERE rn > 1;

WITH cte AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY enrollment_id ORDER BY enrollment_id) AS rn
    FROM enrollments
)
DELETE FROM cte WHERE rn > 1;

WITH cte AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY activity_id ORDER BY activity_id) AS rn
    FROM activity
)
DELETE FROM cte WHERE rn > 1;

WITH cte AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY payment_id ORDER BY payment_id) AS rn
    FROM payments
)
DELETE FROM cte WHERE rn > 1;

#Standardise_Category

UPDATE courses
SET category = UPPER(category);

#Fix_Negative_Values

UPDATE activity
SET watch_time = 0
WHERE watch_time < 0;

#Remove_Invalid_Amount

DELETE FROM payments
WHERE amount <= 0;

#Add_Indexes

CREATE INDEX idx_user_id ON enrollments(user_id);
CREATE INDEX idx_course_id ON enrollments(course_id);
CREATE INDEX idx_activity_user ON activity(user_id);

#Feature_Engineering
#Engagement_Core

ALTER TABLE activity ADD engagement_score FLOAT;
UPDATE activity
SET engagement_score =
    (watch_time * 0.6) +
    (quiz_attempts * 0.3) +
    (login_count * 0.1);

#User_Total_Engagement

CREATE VIEW user_engagement AS
SELECT 
    user_id,
    SUM(engagement_score) AS total_engagement
FROM activity
GROUP BY user_id;

#Course_Completion_Rate

CREATE VIEW course_completion AS
SELECT 
    course_id,
    SUM(CASE WHEN completion_status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS completion_rate
FROM enrollments
GROUP BY course_id;

#Active_Users_(Last_7_Days)
CREATE VIEW active_users AS
SELECT COUNT(DISTINCT user_id) AS active_users
FROM activity
WHERE activity_date_clean >= DATEADD(DAY, -7, GETDATE());

#Revenue_per_User
CREATE VIEW revenue_per_user AS
SELECT 
    user_id,
    SUM(amount) AS total_revenue
FROM payments
GROUP BY user_id;

#User_Segmentation_(High_Value_Users)
ALTER TABLE users ADD user_segment VARCHAR(20);

UPDATE users
SET user_segment = 
    CASE 
        WHEN user_id IN (
            SELECT user_id 
            FROM payments 
            GROUP BY user_id 
            HAVING SUM(amount) > 5000
        ) THEN 'High Value'
        ELSE 'Normal'
    END;

#Course_Popularity

CREATE VIEW course_popularity AS
SELECT 
    course_id,
    COUNT(*) AS total_enrollments
FROM enrollments
GROUP BY course_id;

#Average_Watch_Time_per_Course

CREATE VIEW avg_watch_time AS
SELECT 
    course_id,
    AVG(watch_time) AS avg_watch_time
FROM activity
GROUP BY course_id;

#VALIDATION

SELECT TOP 10 * FROM user_engagement;
SELECT TOP 10 * FROM course_completion;
SELECT TOP 10 * FROM revenue_per_user;


#Milestone3

#Create_Dimension_Table

CREATE TABLE dim_user (
    user_key INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT,
    name VARCHAR(100),
    country VARCHAR(50),
    user_type VARCHAR(20),
    user_segment VARCHAR(20)
);

ALTER TABLE dim_user
ALTER COLUMN country VARCHAR(100);

INSERT INTO dim_user (user_id, name, country, user_type, user_segment)
SELECT DISTINCT user_id, name, country, user_type, user_segment
FROM users;

CREATE TABLE dim_course (
    course_key INT IDENTITY(1,1) PRIMARY KEY,
    course_id INT,
    course_name VARCHAR(100),
    category VARCHAR(50),
    difficulty VARCHAR(20),
    price FLOAT
);

INSERT INTO dim_course
SELECT DISTINCT course_id, course_name, category, difficulty, price
FROM courses;

CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE,
    year INT,
    month INT,
    day INT,
    weekday VARCHAR(10)
);

INSERT INTO dim_date
SELECT DISTINCT 
    CONVERT(INT, FORMAT(date_val, 'yyyyMMdd')),
    date_val,
    YEAR(date_val),
    MONTH(date_val),
    DAY(date_val),
    DATENAME(WEEKDAY, date_val)
FROM (
    SELECT activity_date_clean AS date_val FROM activity
    UNION
    SELECT enrollment_date_clean FROM enrollments
    UNION
    SELECT payment_date_clean FROM payments
) d
WHERE date_val IS NOT NULL;

#Create_Fact_Table

CREATE TABLE fact_enrollment (
    enrollment_key INT IDENTITY(1,1) PRIMARY KEY,
    user_key INT,
    course_key INT,
    date_key INT,
    completion_status VARCHAR(20)
);

INSERT INTO fact_enrollment (user_key, course_key, date_key, completion_status)
SELECT 
    du.user_key,
    dc.course_key,
    CONVERT(INT, FORMAT(e.enrollment_date_clean, 'yyyyMMdd')),
    e.completion_status
FROM enrollments e
JOIN dim_user du ON e.user_id = du.user_id
JOIN dim_course dc ON e.course_id = dc.course_id;

CREATE TABLE fact_activity (
    activity_key INT IDENTITY(1,1) PRIMARY KEY,
    user_key INT,
    course_key INT,
    date_key INT,
    watch_time FLOAT,
    quiz_attempts INT,
    login_count INT,
    engagement_score FLOAT
);

INSERT INTO fact_activity
SELECT 
    du.user_key,
    dc.course_key,
    CONVERT(INT, FORMAT(a.activity_date_clean, 'yyyyMMdd')),
    a.watch_time,
    a.quiz_attempts,
    a.login_count,
    a.engagement_score
FROM activity a
JOIN dim_user du ON a.user_id = du.user_id
JOIN dim_course dc ON a.course_id = dc.course_id;

CREATE TABLE fact_payment (
    payment_key INT IDENTITY(1,1) PRIMARY KEY,
    user_key INT,
    date_key INT,
    amount FLOAT
);

INSERT INTO fact_payment
SELECT 
    du.user_key,
    CONVERT(INT, FORMAT(p.payment_date_clean, 'yyyyMMdd')),
    p.amount
FROM payments p
JOIN dim_user du ON p.user_id = du.user_id;

SELECT COUNT(*) FROM dim_user;
SELECT COUNT(*) FROM fact_activity;
SELECT COUNT(*) FROM fact_payment;

INSERT INTO dim_date
VALUES (0, '1900-01-01', 1900, 1, 1, 'Unknown');

UPDATE fact_enrollment
SET date_key = 0
WHERE date_key IS NULL;

UPDATE fact_activity
SET date_key = 0
WHERE date_key IS NULL;

UPDATE fact_payment
SET date_key = 0
WHERE date_key IS NULL;

INSERT INTO fact_enrollment (user_key, course_key, date_key, completion_status)
SELECT 
    du.user_key,
    dc.course_key,
    ISNULL(CONVERT(INT, FORMAT(e.enrollment_date_clean, 'yyyyMMdd')), 0),
    e.completion_status
FROM enrollments e
JOIN dim_user du ON e.user_id = du.user_id
JOIN dim_course dc ON e.course_id = dc.course_id;

INSERT INTO fact_activity
SELECT 
    du.user_key,
    dc.course_key,
    ISNULL(CONVERT(INT, FORMAT(a.activity_date_clean, 'yyyyMMdd')), 0),
    a.watch_time,
    a.quiz_attempts,
    a.login_count,
    a.engagement_score
FROM activity a
JOIN dim_user du ON a.user_id = du.user_id
JOIN dim_course dc ON a.course_id = dc.course_id;

INSERT INTO fact_payment
SELECT 
    du.user_key,
    ISNULL(CONVERT(INT, FORMAT(p.payment_date_clean, 'yyyyMMdd')), 0),
    p.amount
FROM payments p
JOIN dim_user du ON p.user_id = du.user_id;

SELECT COUNT(*) FROM fact_enrollment WHERE date_key IS NULL;
SELECT COUNT(*) FROM fact_activity WHERE date_key IS NULL;
SELECT COUNT(*) FROM fact_payment WHERE date_key IS NULL;

#Milestone4

#STAGING_LAYER

USE online_learning;
GO

-- Staging tables
-- USERS
CREATE TABLE stg_users (
    user_id INT,
    name VARCHAR(100),
    age INT,
    country VARCHAR(150),
    signup_date VARCHAR(50),
    user_type VARCHAR(20)
);

-- COURSES
CREATE TABLE stg_courses (
    course_id INT,
    course_name VARCHAR(100),
    category VARCHAR(50),
    difficulty VARCHAR(20),
    price FLOAT
);

-- ENROLLMENTS
CREATE TABLE stg_enrollments (
    enrollment_id INT,
    user_id INT,
    course_id INT,
    enrollment_date VARCHAR(50),
    completion_status VARCHAR(20)
);

-- ACTIVITY
CREATE TABLE stg_activity (
    activity_id INT,
    user_id INT,
    course_id INT,
    activity_date VARCHAR(50),
    watch_time FLOAT,
    quiz_attempts INT,
    login_count INT
);

-- PAYMENTS
CREATE TABLE stg_payments (
    payment_id INT,
    user_id INT,
    amount FLOAT,
    payment_date VARCHAR(50)
);

#BULK_LOAD → STAGING

BULK INSERT stg_users
FROM 'C:\Users\lalit\Downloads\Major Project 1.0\users.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    TABLOCK
);

BULK INSERT stg_courses
FROM 'C:\Users\lalit\Downloads\Major Project 1.0\courses.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);

BULK INSERT stg_enrollments
FROM 'C:\Users\lalit\Downloads\Major Project 1.0\enrollments.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);

BULK INSERT stg_activity
FROM 'C:\Users\lalit\Downloads\Major Project 1.0\activity.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);

BULK INSERT stg_payments
FROM 'C:\Users\lalit\Downloads\Major Project 1.0\payments.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);

ALTER TABLE stg_users ADD load_dt DATETIME;
UPDATE stg_users SET load_dt = GETDATE();

ALTER TABLE stg_courses ADD load_dt DATETIME;
UPDATE stg_courses SET load_dt = GETDATE();

ALTER TABLE stg_enrollments ADD load_dt DATETIME;
UPDATE stg_enrollments SET load_dt = GETDATE();

ALTER TABLE stg_activity ADD load_dt DATETIME;
UPDATE stg_activity SET load_dt = GETDATE();

ALTER TABLE stg_payments ADD load_dt DATETIME;
UPDATE stg_payments SET load_dt = GETDATE();


#Transform_Layer

-- USERS CLEAN
CREATE OR ALTER VIEW vw_users_clean AS
SELECT
    user_id,
    name,
    ISNULL(NULLIF(country, ''), 'Unknown') AS country,
    ISNULL(age, 25) AS age,
    TRY_CONVERT(DATE, signup_date) AS signup_date_clean,
    user_type,
    CASE WHEN user_type = 'Paid' THEN 'High Value' ELSE 'Normal' END AS user_segment
FROM stg_users;

-- COURSES CLEAN
CREATE OR ALTER VIEW vw_courses_clean AS
SELECT DISTINCT
    course_id, course_name, category, difficulty, price
FROM stg_courses;

-- ENROLLMENTS CLEAN
CREATE OR ALTER VIEW vw_enrollments_clean AS
SELECT
    enrollment_id, user_id, course_id,
    TRY_CONVERT(DATE, enrollment_date) AS enrollment_date_clean,
    completion_status
FROM stg_enrollments;

-- ACTIVITY CLEAN + FEATURE
CREATE OR ALTER VIEW vw_activity_clean AS
SELECT
    activity_id, user_id, course_id,
    TRY_CONVERT(DATE, activity_date) AS activity_date_clean,
    watch_time, quiz_attempts, login_count,
    (watch_time * 0.5 + quiz_attempts * 2 + login_count * 1.5) AS engagement_score
FROM stg_activity;

-- PAYMENTS CLEAN
CREATE OR ALTER VIEW vw_payments_clean AS
SELECT
    payment_id, user_id, amount,
    TRY_CONVERT(DATE, payment_date) AS payment_date_clean
FROM stg_payments;


#Load_Layer
-- DIM_USER
MERGE dim_user AS tgt
USING (
    SELECT DISTINCT user_id, name, country, user_type, user_segment
    FROM vw_users_clean
) AS src
ON tgt.user_id = src.user_id
WHEN MATCHED THEN
    UPDATE SET
        name = src.name,
        country = src.country,
        user_type = src.user_type,
        user_segment = src.user_segment
WHEN NOT MATCHED THEN
    INSERT (user_id, name, country, user_type, user_segment)
    VALUES (src.user_id, src.name, src.country, src.user_type, src.user_segment);

-- DIM_COURSE
MERGE dim_course AS tgt
USING (
    SELECT DISTINCT course_id, course_name, category, difficulty, price
    FROM vw_courses_clean
) AS src
ON tgt.course_id = src.course_id
WHEN MATCHED THEN
    UPDATE SET
        course_name = src.course_name,
        category = src.category,
        difficulty = src.difficulty,
        price = src.price
WHEN NOT MATCHED THEN
    INSERT (course_id, course_name, category, difficulty, price)
    VALUES (src.course_id, src.course_name, src.category, src.difficulty, src.price);


#DIM_DATE (FULL_REFRESH)
TRUNCATE TABLE dim_date;

INSERT INTO dim_date
SELECT DISTINCT
    CONVERT(INT, FORMAT(d, 'yyyyMMdd')) AS date_key,
    d AS full_date,
    YEAR(d) AS year,
    MONTH(d) AS month,
    DAY(d) AS day,
    DATENAME(WEEKDAY, d) AS weekday
FROM (
    SELECT activity_date_clean d FROM vw_activity_clean
    UNION
    SELECT enrollment_date_clean FROM vw_enrollments_clean
    UNION
    SELECT payment_date_clean FROM vw_payments_clean
) x
WHERE d IS NOT NULL;

-- default unknown
IF NOT EXISTS (SELECT 1 FROM dim_date WHERE date_key = 0)
INSERT INTO dim_date VALUES (0, '1900-01-01', 1900, 1, 1, 'Unknown');

-- FACT_ACTIVITY
INSERT INTO fact_activity (user_key, course_key, date_key, watch_time, quiz_attempts, login_count, engagement_score)
SELECT
    du.user_key,
    dc.course_key,
    ISNULL(CONVERT(INT, FORMAT(a.activity_date_clean, 'yyyyMMdd')), 0),
    a.watch_time, a.quiz_attempts, a.login_count, a.engagement_score
FROM vw_activity_clean a
JOIN dim_user du ON a.user_id = du.user_id
JOIN dim_course dc ON a.course_id = dc.course_id
WHERE NOT EXISTS (
    SELECT 1 FROM fact_activity f
    WHERE f.user_key = du.user_key
      AND f.course_key = dc.course_key
      AND f.date_key = ISNULL(CONVERT(INT, FORMAT(a.activity_date_clean, 'yyyyMMdd')), 0)
      AND f.watch_time = a.watch_time
);

-- FACT_ENROLLMENT
INSERT INTO fact_enrollment (user_key, course_key, date_key, completion_status)
SELECT
    du.user_key,
    dc.course_key,
    ISNULL(CONVERT(INT, FORMAT(e.enrollment_date_clean, 'yyyyMMdd')), 0),
    e.completion_status
FROM vw_enrollments_clean e
JOIN dim_user du ON e.user_id = du.user_id
JOIN dim_course dc ON e.course_id = dc.course_id
WHERE NOT EXISTS (
    SELECT 1 FROM fact_enrollment f
    WHERE f.user_key = du.user_key
      AND f.course_key = dc.course_key
      AND f.date_key = ISNULL(CONVERT(INT, FORMAT(e.enrollment_date_clean, 'yyyyMMdd')), 0)
);

-- FACT_PAYMENT
INSERT INTO fact_payment (user_key, date_key, amount)
SELECT
    du.user_key,
    ISNULL(CONVERT(INT, FORMAT(p.payment_date_clean, 'yyyyMMdd')), 0),
    p.amount
FROM vw_payments_clean p
JOIN dim_user du ON p.user_id = du.user_id
WHERE NOT EXISTS (
    SELECT 1 FROM fact_payment f
    WHERE f.user_key = du.user_key
      AND f.date_key = ISNULL(CONVERT(INT, FORMAT(p.payment_date_clean, 'yyyyMMdd')), 0)
      AND f.amount = p.amount
);

#ETL_LOGGING

CREATE TABLE etl_log (
    run_id INT IDENTITY(1,1),
    step_name VARCHAR(100),
    status VARCHAR(20),
    records_processed INT,
    run_time DATETIME DEFAULT GETDATE()
);

INSERT INTO etl_log (step_name, status, records_processed)
SELECT 'LOAD_FACT_ACTIVITY', 'SUCCESS', @@ROWCOUNT;


CREATE OR ALTER PROCEDURE sp_run_etl
AS
BEGIN
    SET NOCOUNT ON;

    -- Run all your MERGE + INSERT queries here

    INSERT INTO etl_log (step_name, status, records_processed)
    VALUES ('ETL_COMPLETE', 'SUCCESS', 0);
END;

EXEC sp_run_etl;


DECLARE @rows INT;

INSERT INTO fact_activity (user_key, course_key, date_key, watch_time, quiz_attempts, login_count, engagement_score)
SELECT
    du.user_key,
    dc.course_key,
    ISNULL(CONVERT(INT, FORMAT(a.activity_date_clean, 'yyyyMMdd')), 0),
    a.watch_time,
    a.quiz_attempts,
    a.login_count,
    a.engagement_score
FROM vw_activity_clean a
JOIN dim_user du ON a.user_id = du.user_id
JOIN dim_course dc ON a.course_id = dc.course_id;

-- ✅ NOW capture correct row count
SET @rows = @@ROWCOUNT;

-- ✅ Log correct value
INSERT INTO etl_log (step_name, status, records_processed)
VALUES ('FACT_ACTIVITY_LOAD', 'SUCCESS', @rows);

SELECT COUNT(*) FROM stg_users;
SELECT COUNT(*) FROM dim_user;
SELECT COUNT(*) FROM fact_activity;
SELECT COUNT(*) FROM fact_enrollment;
SELECT COUNT(*) FROM fact_payment;

-- Any missing dimension keys?
SELECT COUNT(*) 
FROM fact_activity f
LEFT JOIN dim_user u ON f.user_key = u.user_key
WHERE u.user_key IS NULL;

SELECT COUNT(*) 
FROM fact_activity f
LEFT JOIN dim_course c ON f.course_key = c.course_key
WHERE c.course_key IS NULL;

SELECT TOP 10 * FROM dim_date ORDER BY full_date DESC;

USE online_learning;

DELETE FROM fact_activity;
DELETE FROM fact_enrollment;
DELETE FROM fact_payment;

INSERT INTO fact_activity (user_key, course_key, date_key, watch_time, quiz_attempts, login_count, engagement_score)
SELECT 
    du.user_key,
    dc.course_key,
    CASE 
        WHEN a.activity_date_clean IS NULL THEN NULL
        ELSE CONVERT(INT, FORMAT(a.activity_date_clean, 'yyyyMMdd'))
    END AS date_key,
    a.watch_time,
    a.quiz_attempts,
    a.login_count,
    a.engagement_score
FROM vw_activity_clean a
JOIN dim_user du ON a.user_id = du.user_id
JOIN dim_course dc ON a.course_id = dc.course_id;

SELECT TOP 10 date_key FROM fact_activity;

SELECT COUNT(*) FROM fact_enrollment;
SELECT COUNT(*) FROM fact_payment;

INSERT INTO fact_enrollment (user_key, course_key, date_key, completion_status)
SELECT
    du.user_key,
    dc.course_key,
    CASE 
        WHEN e.enrollment_date_clean IS NULL THEN NULL
        ELSE CONVERT(INT, FORMAT(e.enrollment_date_clean, 'yyyyMMdd'))
    END,
    e.completion_status
FROM vw_enrollments_clean e
JOIN dim_user du ON e.user_id = du.user_id
JOIN dim_course dc ON e.course_id = dc.course_id;

INSERT INTO fact_payment (user_key, date_key, amount)
SELECT
    du.user_key,
    CASE 
        WHEN p.payment_date_clean IS NULL THEN NULL
        ELSE CONVERT(INT, FORMAT(p.payment_date_clean, 'yyyyMMdd'))
    END,
    p.amount
FROM vw_payments_clean p
JOIN dim_user du ON p.user_id = du.user_id;
select * from fact_payment;

ALTER DATABASE online_learning
SET MULTI_USER;

SELECT @@SERVERNAME;

SELECT user_type, COUNT(*) 
FROM dim_user
GROUP BY user_type;

SELECT u.user_type, AVG(a.engagement_score)
FROM fact_activity a
JOIN dim_user u ON a.user_key = u.user_key
GROUP BY u.user_type;

SELECT COUNT(*) FROM dim_user;
SELECT COUNT(*) FROM fact_activity;
SELECT COUNT(*) FROM fact_enrollment;
SELECT COUNT(*) FROM fact_payment;

SELECT COUNT(*) 
FROM fact_activity f
LEFT JOIN dim_user u ON f.user_key = u.user_key
WHERE u.user_key IS NULL;

SELECT SUM(amount) FROM fact_payment;

#Milestone5

USE online_learning;

-- Clear existing data
DELETE FROM fact_activity;
DELETE FROM fact_enrollment;
DELETE FROM fact_payment;

-- Insert into fact_activity
INSERT INTO fact_activity (user_key, course_key, date_key, watch_time, quiz_attempts, login_count, engagement_score)
SELECT 
    du.user_key,
    dc.course_key,
    CASE 
        WHEN a.activity_date_clean IS NULL THEN NULL
        ELSE CONVERT(INT, FORMAT(a.activity_date_clean, 'yyyyMMdd'))
    END AS date_key,
    a.watch_time,
    a.quiz_attempts,
    a.login_count,
    a.engagement_score
FROM vw_activity_clean a
JOIN dim_user du ON a.user_id = du.user_id
JOIN dim_course dc ON a.course_id = dc.course_id;

-- Insert into fact_enrollment
INSERT INTO fact_enrollment (user_key, course_key, date_key, completion_status)
SELECT
    du.user_key,
    dc.course_key,
    CASE 
        WHEN e.enrollment_date_clean IS NULL THEN NULL
        ELSE CONVERT(INT, FORMAT(e.enrollment_date_clean, 'yyyyMMdd'))
    END,
    e.completion_status
FROM vw_enrollments_clean e
JOIN dim_user du ON e.user_id = du.user_id
JOIN dim_course dc ON e.course_id = dc.course_id;

-- Insert into fact_payment
INSERT INTO fact_payment (user_key, date_key, amount)
SELECT
    du.user_key,
    CASE 
        WHEN p.payment_date_clean IS NULL THEN NULL
        ELSE CONVERT(INT, FORMAT(p.payment_date_clean, 'yyyyMMdd'))
    END,
    p.amount
FROM vw_payments_clean p
JOIN dim_user du ON p.user_id = du.user_id;


-- Check counts
SELECT COUNT(*) FROM dim_user;
SELECT COUNT(*) FROM fact_activity;
SELECT COUNT(*) FROM fact_enrollment;
SELECT COUNT(*) FROM fact_payment;

-- Validate referential integrity
SELECT COUNT(*) 
FROM fact_activity f
LEFT JOIN dim_user u ON f.user_key = u.user_key
WHERE u.user_key IS NULL;

-- Revenue validation
SELECT SUM(amount) FROM fact_payment;

-- User distribution
SELECT user_type, COUNT(*) 
FROM dim_user
GROUP BY user_type;

-- Engagement validation
SELECT u.user_type, AVG(a.engagement_score)
FROM fact_activity a
JOIN dim_user u ON a.user_key = u.user_key
GROUP BY u.user_type;