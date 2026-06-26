
USE TelemetryAnalyticsDB;
GO

CREATE TABLE regions (
	region_id INT IDENTITY(1,1) PRIMARY KEY,
	-- using IDENTITY feature so that SQL can track the unique region ID's
    country VARCHAR(100) NOT NULL,
    region_code VARCHAR(10),
    timezone VARCHAR(50),

	CONSTRAINT UQ_regions_region_code UNIQUE (region_code)
	-- ensuring no region code is duplicated
);

CREATE TABLE users (
	user_id INT IDENTITY(1,1) PRIMARY KEY,
	-- using IDENTITY feature so that SQL can track the unique users ID's for me
	first_name VARCHAR(40),
	-- first_name and last_name can be null as for telemetry purposes, these are not key vaules, the username and user_id is key
	last_name VARCHAR(40),
	username VARCHAR(40) NOT NULL,
	email VARCHAR(255) NOT NULL,
	created_at DATETIME2 NOT NULL,
	-- using DATETIME2
	region_id INT NOT NULL,

	CONSTRAINT UQ_users_username UNIQUE (username),
	-- ensuring the username is unique and there are no duplicates by setting up a constraint
	CONSTRAINT UQ_users_email UNIQUE (email),
	-- ensuring the email is unique and there are no duplicates by setting up a constraint
	CONSTRAINT FK_users_regions
		FOREIGN KEY (region_id)
		REFERENCES regions(region_id)
	-- setting up the connection to the regions table here due to the 1 region to many users relationship
);

CREATE TABLE feature_usage (
	feature_usage_id INT IDENTITY(1,1) PRIMARY KEY,
	-- USING IDENTITY feature so that SQL Server tracks the ID's manually
	user_id INT NOT NULL,
	feature_name VARCHAR(100) NOT NULL,
	usage_count INT NOT NULL,

	CONSTRAINT UQ_user_feature UNIQUE (user_id, feature_name),
	-- Prevent duplicate feature rows per user

	CONSTRAINT FK_feature_usage_users
		FOREIGN KEY (user_id)
		REFERENCES users(user_id),
    -- setting up the connection between the feature_usage and users table through a foreign key, 1 user using many features

	CONSTRAINT CK_feature_usage_count
		CHECK (usage_count >= 0)
	-- checking the feature count is more than 0
);

CREATE TABLE user_activity_daily (
	activity_id INT IDENTITY(1,1) PRIMARY KEY,
	user_id INT NOT NULL,
	activity_date DATE NOT NULL,
	session_count INT NOT NULL,
	total_duration_minutes INT NOT NULL,


	CONSTRAINT FK_user_activity_daily_users
		FOREIGN KEY (user_id)
		REFERENCES users(user_id),

	CONSTRAINT UQ_user_activity_date UNIQUE (user_id, activity_date),
	-- Ensuring no duplicates are made for the same user and day

	CONSTRAINT CK_user_activity_session_count
		CHECK (session_count >= 0),
	-- Session needs to be at least one otherwise the insert in invalid

	CONSTRAINT CK_user_activity_duration
	CHECK (total_duration_minutes >= 0)
	-- Activity needs to be larger than zero otherwise the acitivty was not actually carried out
);

CREATE TABLE devices (
	device_id INT IDENTITY(1,1) PRIMARY KEY,
	user_id INT NOT NULL,
	device_identifier_external VARCHAR(255),
	-- External/app identifier for distinguishing actual devices
	device_type VARCHAR(60) NOT NULL,
	-- Laptop, Mobile, Tablet, Desktop
	OS VARCHAR(255) NOT NULL,
	manufacturer VARCHAR(100),
	-- Dell, Apple, Samsung
	model VARCHAR(100),
	-- XPS 13, Galaxy S24, iPhone 15
	registered_at DATETIME2 NOT NULL,


	CONSTRAINT FK_devices_user 
		FOREIGN KEY (user_id)
		REFERENCES users(user_id),

	CONSTRAINT UQ_devices_identifier
		UNIQUE (device_identifier_external)

);

CREATE TABLE sessions (
	session_id INT IDENTITY(1,1) PRIMARY KEY,
	device_id INT NOT NULL,
	start_time DATETIME2 NOT NULL,
	end_time DATETIME2 NOT NULL,


	CONSTRAINT FK_sessions_devices
		FOREIGN KEY (device_id)
		REFERENCES devices(device_id),

	CONSTRAINT CK_sessions_time_order
		CHECK (
			end_time >= start_time
			-- Not allowing session end times to be before start times
		)

-- Keep in mind that sessions cannot overlap for the same device and time slots and so should be managed at application level
		
);

CREATE TABLE event_types (
	event_type_id INT IDENTITY(1,1) PRIMARY KEY,
	event_name VARCHAR(255) NOT NULL,

	CONSTRAINT UQ_event_types_event_name
		UNIQUE (event_name)
	-- ensuring the event names are unique
);

CREATE TABLE events (
	event_id INT IDENTITY(1,1) PRIMARY KEY,
	session_id INT NOT NULL,
	event_type_id INT NOT NULL,
	event_time DATETIME2 NOT NULL,

	CONSTRAINT FK_events_sessions
		FOREIGN KEY (session_id)
		REFERENCES sessions(session_id),


	CONSTRAINT FK_events_event_types
		FOREIGN KEY (event_type_id)
		REFERENCES event_types(event_type_id)	
);


CREATE TABLE event_metadata (
	metadata_id INT IDENTITY(1,1) PRIMARY KEY,
	event_id INT NOT NULL,
	meta_key VARCHAR(50),
	meta_value VARCHAR(50),
	
	CONSTRAINT FK_event_meta_data_event
		FOREIGN KEY (event_id)
		REFERENCES events(event_id)

);