# TelemetryAnalyticsDB

## Overview

TelemetryAnalyticsDB is a relational database schema designed for collecting and analysing application telemetry data. It captures user behaviour across devices and sessions, tracking feature usage, daily activity, and granular event data with optional key-value metadata.

The schema is built for SQL Server and uses native features including `IDENTITY` for surrogate key generation, `DATETIME2` for high-precision timestamps, and declarative constraints to enforce data integrity at the database level.

---

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

**event_metadata as EAV**
The `event_metadata` table uses a key-value (Entity-Attribute-Value) pattern to attach flexible, schema-free attributes to events. This avoids wide sparse tables when event attributes vary significantly by event type.

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
  README.md         -- This file
```

---

## Status

Schema refinement complete. Currently in initial build phase.

---