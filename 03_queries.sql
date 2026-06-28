-- Telemetry Analysis Queries

-- Users Queries

-- Who are our top 10 most active users over the last 90 days, measured by total session time?
SELECT TOP 10 u.user_id, u.first_name, u.Last_name, username, SUM(DATEDIFF(SECOND, s.start_time, s.end_time)) AS TOTAL_DURATION_SECONDS
FROM users u
JOIN devices d
	ON u.user_id = d.user_id
JOIN sessions s
	ON d.device_id = s.device_id
GROUP BY u.user_id, u.first_name, u.Last_name, username
ORDER BY TOTAL_DURATION_SECONDS DESC;

-- What percentage of users have been active at least once in the last 30 days? (Monthly Active Users)
SELECT COUNT(DISTINCT u.user_id) AS ACTIVE_USERS_30_DAYS, (SELECT COUNT(*) FROM users) AS TOTAL_USERS, COUNT(DISTINCT u.user_id) * 100.0 /
    (SELECT COUNT(*) FROM users) AS ACTIVE_USER_PERCENTAGE
FROM users u
JOIN devices d
	ON u.user_id = d.user_id
JOIN sessions s
	ON d.device_id = s.device_id
WHERE s.start_time >= DATEADD(DAY,-30, GETDATE());

--Which users registered but have never recorded a session — potential churn or failed onboarding?
SELECT u.username 
FROM users u
LEFT JOIN devices d
	ON u.user_id = d.user_id
LEFT JOIN sessions s
	ON d.device_id = s.device_id
WHERE s.session_id is NULL;


--How does average session duration differ between weekdays and weekends across all users?
WITH session_durations AS (
    SELECT
        DATEDIFF(SECOND, s.start_time, s.end_time) AS duration_seconds,
        CASE
            WHEN DATENAME(WEEKDAY, s.start_time) IN ('Saturday', 'Sunday')
            THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type
    FROM sessions s
)
SELECT
    day_type,
    AVG(duration_seconds) AS avg_duration_seconds,
    AVG(duration_seconds) / 60 AS avg_duration_minutes
FROM session_durations
GROUP BY day_type;

--Feature Queries

--Which features are used by the most users and what is the average usage count per user for each feature?
SELECT f.feature_name, COUNT(DISTINCT f.user_id) AS USERS_USING_FEATURE, AVG(CAST(usage_count AS DECIMAL(10,2))) AS AVG_USAGE_PER_USER,SUM(usage_count) AS TOTAL_USAGE
FROM feature_usage f 
GROUP BY f.feature_name
ORDER BY USERS_USING_FEATURE DESC;

--Which features are barely being used (Bottom 5) — candidates for deprecation or improvement?
SELECT TOP 5 f.feature_name, COUNT(DISTINCT f.user_id) AS USERS_USING_FEATURE, AVG(CAST(usage_count AS DECIMAL(10,2))) AS AVG_USAGE_PER_USER,SUM(usage_count) AS TOTAL_USAGE
FROM feature_usage f 
GROUP BY f.feature_name
ORDER BY USERS_USING_FEATURE ASC;

--Is there a correlation between the number of features a user uses and their total session time?
SELECT u.username, COUNT(DISTINCT f.feature_name) AS TOTAL_DISTINCT_FEATURES_USED, SUM(DATEDIFF(SECOND, s.start_time, s.end_time)) AS TOTAL_DURATION_SECONDS  
FROM feature_usage f
JOIN users u
    ON f.user_id = u.user_id
JOIN devices d
    ON u.user_id = d.user_id
JOIN sessions s
    ON d.device_id = s.device_id
GROUP BY u.username
ORDER BY TOTAL_DISTINCT_FEATURES_USED DESC;

--Session Queries 

--What is the breakdown of sessions by device type, and which device type drives the longest average session?
SELECT d.device_type, COUNT(s.session_id) AS TOTAL_SESSIONS_PER_DEVICE, AVG(DATEDIFF(SECOND, s.start_time, s.end_time)) AS AVG_TOTAL_SESSION_TIME
FROM sessions s
JOIN devices d
    ON s.device_id = d.device_id
GROUP BY d.device_type
ORDER BY AVG_TOTAL_SESSION_TIME DESC;


