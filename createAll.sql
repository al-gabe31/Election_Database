-- SCRIPT TO CREATE ALL TABLES

-- Creates Places related tables
-- 3.4. Places_Coordinates
CREATE TABLE Places_Coordinates (
	coordinates_ID INT PRIMARY KEY,
    x_coord INT NOT NULL,
    y_coord INT NOT NULL
);

-- 3.5. Places_Address
CREATE TABLE Places_Address (
	address_ID INT PRIMARY KEY,
    street_number VARCHAR(30) NOT NULL,
    street_name VARCHAR(30) NOT NULL,
    city VARCHAR(30) NOT NULL,
    zip_code VARCHAR(30) NOT NULL,
    state VARCHAR(30) NOT NULL
);

-- 3. Places
CREATE TABLE Places (
	place_ID INT PRIMARY KEY,
    address_ID INT NOT NULL,
    coordinates_ID INT NOT NULL,
    role VARCHAR(20) CHECK(role IN ("Residences", "Voting Center")) NOT NULL,
    UNIQUE (address_ID, coordinates_ID),
    FOREIGN KEY (address_ID) REFERENCES Places_Address(address_ID),
    FOREIGN KEY (coordinates_ID) REFERENCES Places_Coordinates(coordinates_ID)
);

-- 3.1. Places_Residences
CREATE TABLE Places_Residences (
	place_ID INT PRIMARY KEY,
    FOREIGN KEY (place_ID) REFERENCES Places(place_ID)
);

-- 3.2. Places_Voting_Center
CREATE TABLE Places_Voting_Center (
	place_ID INT PRIMARY KEY,
    acronym VARCHAR(4) NOT NULL UNIQUE,
    op_ID INT NOT NULL UNIQUE,
    FOREIGN KEY (place_ID) REFERENCES Places(place_ID)
);

-- 3.3. Places_Operating_Periods
CREATE TABLE Places_Operating_Periods (
	op_ID INT,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    CHECK (start_time < end_time),
    FOREIGN KEY (op_ID) REFERENCES Places_Voting_Center(op_ID) 
);

-- Creates Folks related tables
-- 1. Folks
CREATE TABLE Folks (
	personal_ID INT PRIMARY KEY,
    name_ID INT UNIQUE NOT NULL,
    DOB DATE NOT NULL,
    primary_tel VARCHAR(10) NOT NULL,
    secondary_tel VARCHAR(10) NOT NULL,
    emails_ID INT UNIQUE NOT NULL,
    residence_ID INT NOT NULL,
    FOREIGN KEY (residence_ID) REFERENCES Places_Residences(place_ID)
);

CREATE INDEX index_DOB ON Folks (DOB);

-- 1.1. Folks_Emails
CREATE TABLE Folks_Emails (
	emails_ID INT,
    email VARCHAR(30) NOT NULL,
    FOREIGN KEY (emails_ID) REFERENCES Folks(emails_ID)
);

-- 1.2. Folks_Name
CREATE TABLE Folks_Name (
	name_ID INT PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    nickname VARCHAR(30) NOT NULL,
    FOREIGN KEY (name_ID) REFERENCES Folks(name_ID)
);

-- Creates Election_Staff related tables
-- 2. Election_Staff
CREATE TABLE Election_Staff (
	staff_ID INT PRIMARY KEY,
    work_location_ID INT NOT NULL,
    shift_ID INT UNIQUE,
    role VARCHAR(20) CHECK(role in ("Clerk", "Monitor")) NOT NULL,
    FOREIGN KEY (work_location_ID) REFERENCES Places_Voting_Center(place_ID)
);

-- 2.1. Election_Staff_Monitor
CREATE TABLE Election_Staff_Monitor (
	staff_ID INT PRIMARY KEY,
    FOREIGN KEY (staff_ID) REFERENCES Election_Staff(staff_ID)
);

-- 2.2. Election_Staff_Clerk
CREATE TABLE Election_Staff_Clerk (
	staff_ID INT PRIMARY KEY,
    FOREIGN KEY (staff_ID) REFERENCES Election_Staff(staff_ID)
);

-- 2.3. Election_Staff_Shift
CREATE TABLE Election_Staff_Shift (
	shift_ID INT PRIMARY KEY,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    CHECK (start_time < end_time),
    FOREIGN KEY (shift_ID) REFERENCES Election_Staff(shift_ID)
);

-- Creates Ballots related tables
-- 4. Ballots
CREATE TABLE Ballots (
	ballot_ID INT PRIMARY KEY,
    short_name VARCHAR(4) NOT NULL,
    question_text VARCHAR(200) NOT NULL,
    availability_ID INT NOT NULL UNIQUE
);

-- 4.1. Ballots_Availability
CREATE TABLE Ballots_Availability (
	availability_ID INT PRIMARY KEY,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    CHECK (start_time < end_time),
    FOREIGN KEY (availability_ID) REFERENCES Ballots(availability_ID)
);

-- Creates Voting_Registry related tables
-- 5. Voting_Registry
CREATE TABLE Voting_Registry (
	voting_reg_ID INT PRIMARY KEY,
    identifier INT NOT NULL,
    voting_date DATE NOT NULL,
    ballot_ID INT NOT NULL,
    voting_center_ID INT NOT NULL,
    FOREIGN KEY (identifier) REFERENCES Folks(personal_ID),
    FOREIGN KEY (ballot_ID) REFERENCES Ballots(ballot_ID),
    FOREIGN KEY (voting_center_ID) REFERENCES Places_Voting_Center(place_ID)
);

-- Creates Cast_Votes related tables
-- 6. Cast_Votes
CREATE TABLE Cast_Votes (
	cast_vote_ID INT PRIMARY KEY,
    voter_ID INT NOT NULL,
    voting_reg_ID INT NOT NULL UNIQUE,
    ballot_ID INT NOT NULL,
    monitor_ID INT NOT NULL,
    vote_time DATETIME NOT NULL,
    vote VARCHAR(20) CHECK(vote in ("YES", "NO", "ABSTAIN")),
    FOREIGN KEY (voter_ID) REFERENCES Folks(personal_ID),
    FOREIGN KEY (voting_reg_ID) REFERENCES Voting_Registry(voting_reg_ID),
    FOREIGN KEY (ballot_ID) REFERENCES Ballots(ballot_ID),
    FOREIGN KEY (monitor_ID) REFERENCES Election_Staff_Monitor(staff_ID)
);