-- 1. List the name, city and email (any single email suffices) of all folks.
SELECT first_name AS 'First Name', last_name AS 'Last Name', city AS 'City', email AS 'Email' FROM Folks
JOIN Folks_Name ON Folks.name_ID = Folks_Name.name_ID
JOIN Folks_Emails ON Folks.emails_ID = Folks_Emails.emails_ID
JOIN (
    SELECT * FROM Places
    JOIN Places_Residences ON Places.place_ID = Places_Residences.place_ID
    JOIN Places_Address ON Places.address_ID = Places_Address.address_ID
)
GROUP BY Folks.personal_ID;

-- 2. List the city, state, and the number of residences of each city in Wonderland (skip cities with no residents) in decreasing order of number of residents.
SELECT city AS 'City', state AS 'State', COUNT(city) AS 'Number of Residences in State' FROM Places
JOIN Places_Residences ON Places.place_ID = Places_Residences.place_ID
JOIN Folks ON Folks.residence_ID = Places_Residences.place_ID
JOIN Places_Address ON Places.address_ID = Places_Address.address_ID
ORDER BY COUNT(city) DESC;

-- 3. List each state together with its number of currently inhabited places (include states with no inhabited places) in increasing alphabetical order.
SELECT state AS 'State', COUNT(Folks.residence_ID) AS 'Num Residences' FROM Places
LEFT JOIN Folks ON Folks.residence_ID = Places.place_ID
JOIN Places_Address ON Places.address_ID = Places_Address.address_ID
GROUP BY Places.address_ID
ORDER BY State

-- 4. Find the distinct identifiers of folks registered at a given voting center within a given time period.
SELECT DISTINCT identifier FROM ( 
    SELECT identifier, voting_date, first_name, last_name, voting_reg_ID, Places_Voting_Center.acronym FROM Voting_Registry
    JOIN Places_Voting_Center ON Voting_Registry.voting_center_ID = Places_Voting_Center.place_ID
    JOIN Folks ON Folks.personal_ID = Voting_Registry.identifier
    JOIN Folks_Name ON Folks.name_ID = Folks_Name.name_ID
    -- start_time and end_time is the DATETIME input that came from the user
    WHERE (voting_date BETWEEN '{start_time}' AND '{end_time}') AND (Places_Voting_Center.place_ID = {voting_center_ID})
    ORDER BY voting_date
)

-- 5. Find for a given month, the number of unique registrations at any voting center which is within 5 miles from the center of Megapolis, except for voting centers in a given (exclusion) list of voting centers.
SELECT Places.place_ID, x_coord, y_coord FROM Places
JOIN Places_Voting_Center ON Places.place_ID = Places_Voting_Center.place_ID
JOIN Places_Coordinates ON Places.coordinates_ID = Places_Coordinates.coordinates_ID

SELECT voting_center_ID, COUNT(voting_center_ID) FROM Voting_Registry
-- month indicates the month we want to find the unique registrations of
WHERE strftime('%m', voting_date) = '{month}' AND voting_center_ID IN {nearby_voting_centers} AND voting_center_ID NOT IN {excluded_voting_center_IDs}
GROUP BY voting_center_ID

-- 6. Find the most popular voting center(s) (in terms of total number of registrations) in a given time period among those in a given city.
SELECT voting_center_ID, COUNT(voting_center_ID) FROM Voting_Registry
JOIN (
    SELECT Places.place_ID FROM Places
    JOIN Places_Voting_Center ON Places.place_ID = Places_Voting_Center.place_ID
    JOIN Places_Address ON Places.address_ID = Places_Address.address_ID
    -- city is a user input that tells us which city we want to get results from
    WHERE city = '{city}'
) AS subquery ON Voting_Registry.voting_center_ID = subquery.place_ID
-- again, start_time and end_time are user inputs that tells us the DATETIME interval
WHERE voting_date BETWEEN '{start_time}' AND '{end_time}'
GROUP BY voting_center_ID
ORDER BY COUNT(voting_center_ID) DESC

-- 7. Find the unique folk that have valid registrations with every voting center on a given state.
INSERT INTO Voting_Registry
VALUES ({get_next_ID(conn, c, 'Voting_Registry')}, 1, '2023-10-28', 4, 2);

INSERT INTO Voting_Registry
VALUES ({get_next_ID(conn, c, 'Voting_Registry')}, 1, '2023-10-28', 4, 3);

SELECT subquery2.identifier FROM (
    SELECT DISTINCT identifier, subquery.place_ID, Num_Voting_Centers FROM Voting_Registry
    JOIN (
        SELECT Places_Voting_Center.place_ID, count.Num_Voting_Centers FROM Places
        JOIN Places_Voting_Center ON Places.place_ID = Places_Voting_Center.place_ID
        JOIN Places_Address ON Places.address_ID = Places_Address.address_ID
        CROSS JOIN (
            SELECT COUNT(*) AS 'Num_Voting_Centers' FROM Places
            JOIN Places_Voting_Center ON Places.place_ID = Places_Voting_Center.place_ID
            JOIN Places_Address ON Places.address_ID = Places_Address.address_ID
            -- state is user input that tells us what state we're looking for
            WHERE state = '{state}'
        ) AS count
        -- same thing as above (user input again)
        WHERE state = '{state}'
    ) AS subquery ON Voting_Registry.voting_center_ID = subquery.place_ID
    ORDER BY identifier
) AS subquery2
GROUP BY identifier
HAVING COUNT(subquery2.identifier) = Num_Voting_Centers

-- 8. Find folks that registered at a voting center that is farther away than the voting center closest to their residence (break ties alphabetically by center's acronym).
SELECT Places.place_ID, role, x_coord, y_coord, acronym FROM Places
JOIN Places_Coordinates ON Places.coordinates_ID = Places_Coordinates.coordinates_ID
LEFT JOIN Places_Voting_Center ON Places.place_ID = Places_Voting_Center.place_ID

CREATE TABLE Temp_Closest_Data (
    residence_ID INT,
    voting_center_ID INT
)

INSERT INTO Temp_Closest_Data
VALUES ({place_ID}, {residences[place_ID]['closest_voting_center_ID']})

SELECT DISTINCT Voting_Registry.identifier, Folks_Name.first_name, Folks_Name.last_name FROM Voting_Registry
JOIN Folks ON Voting_Registry.identifier = Folks.personal_ID
JOIN Temp_Closest_Data ON Temp_Closest_Data.residence_ID = Folks.residence_ID AND Temp_Closest_Data.voting_center_ID != Voting_Registry.voting_center_ID
JOIN Places_Voting_Center ON Places_Voting_Center.place_ID = Voting_Registry.voting_center_ID
JOIN Folks_Name ON Folks.name_ID = Folks_Name.name_ID
ORDER BY Voting_Registry.identifier

DROP TABLE IF EXISTS TEMP_Closest_Data; 

-- 9. Write a SQL function that returns the acronym of the voting center closest to the residence of a given folk among those whose operating period(s) contain a given date (return NULL if no such center exists; break ties at alphabetically by acronym).
SELECT * FROM (
    SELECT Places_Voting_Center.acronym FROM Places
    JOIN Places_Voting_Center ON Places.place_ID = Places_Voting_Center.place_ID
    JOIN Places_Operating_Periods ON Places_Voting_Center.op_ID = Places_Operating_Periods.op_ID
    JOIN Places_Coordinates ON Places.coordinates_ID = Places_Coordinates.coordinates_ID
    JOIN (
        SELECT Places_Coordinates.x_coord, Places_Coordinates.y_coord FROM Folks
        JOIN Places_Residences ON Folks.residence_ID = Places_Residences.place_ID
        JOIN Places ON Places.place_ID = Places_Residences.place_ID
        JOIN Places_Coordinates ON Places.coordinates_ID = Places_Coordinates.coordinates_ID
        WHERE Folks.personal_ID = {folk_ID}
    ) AS subquery
    -- date is a user input of the DATETIME we want to check
    WHERE '{date}' BETWEEN start_time AND end_time
    ORDER BY Places_Voting_Center.acronym
    LIMIT 1
)

-- folk_ID is user input. same thing earlier with date (user input). as for result[0][0], that's just the data we'll be working with to make the user defined function to work.
SELECT find_closest_voting_center({folk_ID}, '{date}', '{result[0][0]}')

-- 10. For a given ballot, construct a cross-tabulation of voting centers (acronym) as rows, unique ballot answers (options) as columns, and cells indicating number of cast votes at the row's center with the column's option.
SELECT Places_Voting_Center.acronym, vote FROM Cast_Votes
JOIN Voting_Registry ON Cast_Votes.voting_reg_ID = Voting_Registry.voting_reg_ID
JOIN Places_Voting_Center ON Voting_Registry.voting_center_ID = Places_Voting_Center.place_ID
-- ballot_ID is user input
WHERE Cast_Votes.ballot_ID = {ballot_ID}
ORDER BY Places_Voting_Center.acronym, vote DESC

CREATE TABLE Temp_Tabulation (
    voting_center_acronym VARCHAR(4),
    YES_count INT,
    NO_count INT,
    ABSTAIN_count INT
)

INSERT INTO Temp_Tabulation
-- acronym is user input
VALUES ('{acronym}', {tabulation[acronym]['YES']}, {tabulation[acronym]['NO']}, {tabulation[acronym]['ABSTAIN']})

SELECT * FROM Temp_Tabulation

DROP TABLE IF EXISTS Temp_Tabulation; 