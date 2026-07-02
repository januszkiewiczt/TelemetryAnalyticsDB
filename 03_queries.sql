-- Telemetry Analysis Queries v1.0

-- Users Queries

--Which users have the highest session counts but the lowest total duration — are they bouncing in and out, suggesting a poor experience?
WITH top_user_session AS(
    SELECT TOP 30 u.username, SUM(DATEDIFF(SECOND, s.start_time, s.end_time)) AS TOTAL_DURATION_SECONDS,COUNT(DISTINCT s.session_id) AS TOTAL_SESSIONS, (SUM(DATEDIFF(SECOND, s.start_time, s.end_time))/ NULLIF(COUNT(DISTINCT s.session_id), 0)) AS SECONDS_PER_SESSION
FROM sessions s
JOIN devices d
    ON s.device_id = d.device_id
JOIN users u
    ON d.user_id = u.user_id
GROUP BY u.username
ORDER BY TOTAL_SESSIONS DESC
)
SELECT username,TOTAL_DURATION_SECONDS, TOTAL_SESSIONS, SECONDS_PER_SESSION
FROM top_user_session
ORDER BY SECONDS_PER_SESSION ASC; 

SELECT TOP 20
    u.username,
    SUM(DATEDIFF(SECOND, s.start_time, s.end_time)) AS TOTAL_DURATION_SECONDS,
    COUNT(DISTINCT s.session_id) AS TOTAL_SESSIONS,
    SUM(DATEDIFF(SECOND, s.start_time, s.end_time)) / NULLIF(COUNT(DISTINCT s.session_id), 0) AS SECONDS_PER_SESSION
FROM sessions s
JOIN devices d
    ON s.device_id = d.device_id
JOIN users u
    ON d.user_id = u.user_id
GROUP BY u.username
ORDER BY SECONDS_PER_SESSION ASC;





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


--Device Queries

--Which operating systems are most common across our user base?
SELECT d.OS, COUNT(d.OS) AS TOTAL_OS_DEPLOYMENTS, CAST(COUNT(d.OS) * 100.0 / (SELECT COUNT(*) FROM devices) AS DECIMAL(5,2)) AS PERCENTAGE_OF_DEVICES
FROM devices d
GROUP BY d.OS
ORDER BY TOTAL_OS_DEPLOYMENTS DESC;

-- Event Queries
--Which regions generate the most activity, measured by total events fired?
SELECT r.country, COUNT(e.event_id) AS EVENT_TOTAL, CAST(COUNT(e.event_ID) * 100.0 / (SELECT COUNT(*) FROM events) AS DECIMAL(5,2)) AS EVENT_PERECENTAGE
FROM events e
JOIN sessions s
    ON e.session_id = s.session_id
JOIN devices d
    ON s.device_id = d.device_id
JOIN users u
    ON d.user_id = u.user_id
JOIN regions r
    ON u.region_id = r.region_id
GROUP BY r.country
ORDER BY EVENT_TOTAL DESC;

--Which region has the highest average daily active users relative to its total user count?
WITH daily_active AS (
	SELECT r.country, uad.activity_date, COUNT(DISTINCT uad.user_id) AS ACTIVE_USERS
	FROM user_activity_daily uad
	JOIN users u
		ON uad.user_id = u.user_id
	JOIN regions r
		ON u.region_id = r.region_id
	GROUP BY r.country, uad.activity_date
	
)
SELECT country, AVG(ACTIVE_USERS) AS AVG_DAILY_ACTIVE_USERS
FROM daily_active
GROUP BY country;
	
--What are the most frequently fired events,
SELECT event_name, COUNT(*) AS total_events
FROM events e
JOIN event_types et ON e.event_type_id = et.event_type_id
GROUP BY event_name
ORDER BY total_events DESC;

---and how has that trended over the last 90 days?

SELECT et.event_name, CAST(e.event_time AS DATE) AS EVENT_DATE, COUNT(et.event_type_id) AS TOTAL_EVENTS_PER_DAY
FROM event_types et
JOIN events e
    ON et.event_type_id = e.event_type_id
GROUP BY et.event_name, CAST(e.event_time AS DATE)
ORDER BY EVENT_DATE DESC;

--What is the 7-day rolling average of daily active users across the entire platform?
WITH daily_activity AS (
    SELECT activity_date, COUNT(DISTINCT user_id) AS ACTIVE_USERS
    FROM user_activity_daily
    GROUP BY activity_date
)
SELECT
    activity_date,
    active_users,
    AVG(ACTIVE_USERS) OVER (
     ORDER BY activity_date
     ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ROLLING_7_DAY_AVERAGE
FROM daily_activity
ORDER BY activity_date;

-- Event Metadata queries

--Which event types appear most in the metadata — what context (meta key) are users generating the most?
SELECT et.event_name, em.meta_key, COUNT(em.event_id) AS TOTAL_EVENTS
FROM event_types et
JOIN events e
    ON et.event_type_id = e.event_type_id
JOIN event_metadata em
    ON e.event_id = em.event_id
GROUP BY et.event_name, em.meta_key
ORDER BY TOTAL_EVENTS DESC;
