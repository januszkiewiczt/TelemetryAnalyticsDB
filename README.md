\# Telemetry Analytics Database (SQL Server)



\## Overview



This project is a SQL Server-based telemetry and analytics database designed to model and analyse user behaviour through structured relational data. It simulates a real-world event tracking system commonly used in software products to understand user activity, feature usage, and regional distribution.



The database is built with a normalised relational schema and enforced data integrity using primary keys, foreign keys, and unique constraints.



\---



\## Database Design



The schema is structured around a core user analytics flow:



\- regions — stores geographic segmentation data

\- users — stores user identity and profile information

\- feature\_usage — tracks aggregated feature interaction per user



\### Relationships

\- Each user belongs to a region

\- Each feature usage record is linked to a user



\---



\## Tech Stack



\- SQL Server (SSMS)

\- T-SQL

\- Relational database design principles



\---



\## Key Features



\- Normalised relational database design

\- Primary key and foreign key constraints

\- Unique constraints for data integrity

\- Default timestamping using GETDATE()

\- Scalable structure suitable for analytics expansion



\---



\## Project Structure



TelemetryAnalyticsDB/

├── 01\_schema.sql        # Database schema (tables + constraints)

├── 03\_queries.sql       # Analytical queries (in progress)

├── README.md            # Project documentation



\---



\## Future Improvements



\- Add session and event-level tracking tables

\- Introduce device-level tracking

\- Build advanced analytics queries (DAU, retention, funnels)

\- Add sample dataset for testing and analysis



\---



\## Purpose



The goal of this project is to demonstrate practical SQL Server skills, including database design, relational modelling, and preparation for analytics workloads similar to real-world telemetry systems used in software engineering and data analysis roles.

