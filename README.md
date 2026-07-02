# TelemetryAnalyticsDB

## Overview

TelemetryAnalyticsDB is a relational database schema designed for collecting and analysing application telemetry data. It captures user behaviour across devices and sessions, tracking feature usage, daily activity, and granular event data with optional key-value metadata.

The schema is built for SQL Server and uses native features including `IDENTITY` for surrogate key generation, `DATETIME2` for high-precision timestamps, and declarative constraints to enforce data integrity at the database level.

The project includes a range of SQL queries designed to answer real-world telemetry questions across users, sessions, events, devices, regions, and feature usage. The analysis demonstrates the use of joins, Common Table Expressions (CTEs), subqueries, aggregate and window functions, conditional logic, and date functions to transform raw telemetry data into meaningful business insights.

A custom PowerBI report has been created with the use of the Telemetry Analytics Database in the background, with the objective of demonstrating the functionality of the DB within a business analytics environment.

## Schema Structure

### Tables

| Table | Description |
|---|---|
| `regions` | Reference table for geographic regions and timezones |
| `users` | Core user records linked to a region |
| `devices` | Devices registered to users |
| `sessions` | Individual sessions tied to a device |
| `events` | Events captured within a session |
| `event_types` | Lookup table for event type definitions |
| `event_metadata` | Key-value pairs providing additional context for events |
| `feature_usage` | Aggregate feature usage counts per user |
| `user_activity_daily` | Daily rollup of session count and total duration per user |

### Entity Relationships

```
regions
  └── users
        ├── devices
        │     └── sessions
        │           └── events
        │                 └── event_metadata
        │
        ├── feature_usage
        └── user_activity_daily

event_types
  └── events
```

---

## Design Decisions

**Surrogate keys via IDENTITY**
All tables use `INT IDENTITY(1,1)` primary keys. This keeps joins simple and avoids dependency on natural keys that may change over time.

**DATETIME2 over DATETIME**
`DATETIME2` is used throughout for higher precision and a wider date range, in line with current SQL Server best practice.

**Unique constraints on business keys**
- `regions.region_code` — prevents duplicate region codes
- `users.username` and `users.email` — enforces uniqueness at the database level rather than relying on the application layer
- `feature_usage(user_id, feature_name)` — prevents duplicate feature rows per user
- `user_activity_daily(user_id, activity_date)` — enforces one record per user per day
- `devices.device_identifier_external` — prevents the same physical device being registered twice

**CHECK constraints**
- `feature_usage.usage_count >= 0`
- `user_activity_daily.session_count >= 0`
- `user_activity_daily.total_duration_minutes >= 0`
- `sessions.end_time >= start_time`

**Session overlap handling**
Overlapping sessions for the same device are not enforced at the schema level, as this logic is better handled at the application layer where the full session context is available.

**Nullable personal fields**
`users.first_name` and `users.last_name` are nullable. For telemetry purposes `user_id` and `username` are the identifying values; personal name fields are optional.

---

## Prerequisites

- SQL Server 2016 or later (for full `DATETIME2` and `IDENTITY` support)
- An existing SQL Server instance with permission to create databases and objects

---

## File Structure

```
TelemetryAnalyticsDB/
  01_schema.sql        -- Full schema definition
  02_sample_data.sql   -- All data used for the database
  03_queries         -- All queries used for telemetry analytics
  04_dashboard      -- Custom created Power BI report showing DB connection and data analysis
  README.md         -- This file

```

## Queries

15 analytical queries are included in `03_queries.sql`, each addressing a realistic business question against the telemetry dataset. The queries are grouped by theme and progress in complexity from basic aggregation through to CTEs and window functions.

### User Behaviour
1. Top 10 most active users over the last 90 days, measured by total session time
2. Percentage of users active at least once in the last 30 days (Monthly Active Users)
3. Users who registered but have never recorded a session — potential churn or failed onboarding
4. Average session duration broken down by weekday vs weekend

### Feature Adoption
5. Features used by the most users, with average usage count per user
6. Least used features — candidates for deprecation or improvement
7. Correlation between number of distinct features used and total session time per user

### Device and Platform
8. Session breakdown by device type with average session duration per type
9. Operating system distribution across the user base

### Regional Insights
10. Total events fired per region, with percentage share of platform activity
11. Average daily active users per region relative to total regional user count

### Event and Product Analytics
12. Most frequently fired event types overall, and event volume trend over the last 90 days
13. 7-day rolling average of daily active users across the platform (window function)
14. Most common event metadata keys — what context users are generating most

### Engagement Quality
15. Users with the highest session counts but lowest average session duration — potential bounce or poor experience indicators

---

## Power BI Report

A Power BI report has been created using TelemetryAnalyticsDB as the live data source, with the objective of demonstrating the functionality of the database within a business analytics environment.

The [Overview](04_dashboard/screenshots/01_overview.png) page includes four headline KPI cards covering total users, sessions, events, and devices across the platform.

The [Users](04_dashboard/screenshots/02_users.png) page focuses on user analysis by country, total sessions per month, and the top 10 most active users by session time. A gauge visual determines whether the 94% monthly active user target is being met.

The [Devices](04_dashboard/screenshots/03_devices.png) page breaks down the device landscape by OS and manufacturer, shows the average number of devices per user, and maps device deployment by country.

The [Events](04_dashboard/screenshots/04_events.png) page covers daily average event volume, a breakdown of the most frequently fired event types, a daily event tracker, and event distribution by country.

The [Sessions](04_dashboard/screenshots/05_sessions.png) page tracks average sessions per user against a target gauge, average session duration with a benchmark, sessions by country, and total daily session volume across June 2026.
---

## Status

Schema, sample data, analytical queries, and Power BI report complete.

---
