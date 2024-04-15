# Useful functions for the project
import sqlite3

def get_next_ID(connection, cursor, table):
    cursor.execute(f"SELECT * FROM {table}")
    query = cursor.fetchall()

    if len(query) == 0: # Table is currently empty
        return 0
    
    return query[-1][0] + 1

def value_in_table_column(connection, cursor, table, column, value):
    cursor.execute(f"SELECT {column} FROM {table}")
    query = cursor.fetchall()

    if len(query) == 0:
        return False
    
    for result in query:
        if result[0] == value:
            return True
    
    return False

def get_query(connection, cursor, query):
    cursor.execute(query)
    return cursor.fetchall()

def get_row(connection, cursor, table, column, value):
    if value_in_table_column(connection, cursor, table, column, value) == False:
        print(f"Error - {column} {value} not found")
        return -1 # Error code

    cursor.execute(f"""
                    SELECT * FROM {table}
                    WHERE {column} = {value}
    """)
    return cursor.fetchall()

def execute_SQL(connection, cursor, file):
    """
    Desc: Executes an SQL file line by line

    connection: The connection to the sqlite database
    cursor:     The cursor (I'm not exactly sure what a cursor is lolll)
    file:       The SQL file we want to execute
    """
    
    command = "" # The SQL command we want to execute

    # Reads the SQL file
    with open(file, 'r') as file:
        for line in file:
            command += line.strip() + '\n'
    
    command = command.split(';') # Splits the commands instruction by instruction

    # Executes the SQL commands line by line
    for i in range(len(command)):
        cursor.execute(command[i])
    
    connection.commit()
    print(f"{file.name} Successful Executed")

# CODE FOR THE ACTIVITIES SECTION

def create_new_Ballots(connection, cursor, short_name: str, question_text: str, availability_ID: int, ballot_ID: int = -1):
    if ballot_ID == -1: # Just use the next available ballot_ID
        ballot_ID = get_next_ID(connection, cursor, "Ballots")
    
    cursor.execute(f"""
                    INSERT INTO Ballots
                    VALUES ({ballot_ID}, '{short_name}', '{question_text}', '{availability_ID}');
    """)

    connection.commit()

    # If the availability_ID isn't currently in the Ballots_Availability table, it'll create a new entry
    if value_in_table_column(connection, cursor, "Ballots_Availability", "availability_ID", availability_ID) == False:
        print("New availability_ID detected. Please input data for the ballot's availability.")
        start_time = str(input("start_time: (EX: 2023-10-28 08:00:00)"))
        end_time = str(input("end_time: (EX: 2023-11-08 20:00:00)"))

        # Inserts new Ballots_Availability data
        create_new_Ballots_Availability(connection, cursor, start_time, end_time, availability_ID)

def create_new_Ballots_Availability(connection, cursor, start_time: str, end_time: str, availability_ID: int = -1):
    if availability_ID == -1: # Just use the next available availability_ID
        availability_ID = get_next_ID(connection, cursor, "Ballots_Availability")
    
    cursor.execute(f"""
                    INSERT INTO Ballots_Availability
                    VALUES ({availability_ID}, '{start_time}', '{end_time}');
    """)

    connection.commit()

def create_new_Voting_Registry(connection, cursor, identifier: int, voting_date: str, ballot_ID: int, voting_center_ID: int, voting_reg_ID: int = -1):
    if voting_reg_ID == -1: # Just use the next available voting_reg_ID
        voting_reg_ID = get_next_ID(connection, cursor, "Voting_Registry")
    
    cursor.execute(f"""
                    INSERT INTO Voting_Registry
                    VALUES ({voting_reg_ID}, {identifier}, '{voting_date}', {ballot_ID}, {voting_center_ID})
    """)

    connection.commit()

def modify_ballot_availability(connection, cursor, ballot_ID: int, start_time: str, end_time: str):
    if value_in_table_column(connection, cursor, "Ballots", "ballot_ID", ballot_ID) == False:
        print(f"Error - ballot_ID {ballot_ID} not found")
        return -1 # Error code
    
    availability_ID = get_row(connection, cursor, "Ballots", "ballot_ID", ballot_ID)[0][-1]

    if value_in_table_column(connection, cursor, "Ballots_Availability", "availability_ID", availability_ID) == False:
        print(f"Error - availability_ID {availability_ID} not found")
        return -1 # Error code
    
    cursor.execute(f"""
                    UPDATE Ballots_Availability
                    SET start_time = '{start_time}', end_time = '{end_time}'
                    WHERE availability_ID = {availability_ID};
    """)

    connection.commit()

def create_new_Cast_Votes(connection, cursor, voter_ID: int, voting_reg_ID: int, ballot_ID: int, monitor_ID: int, vote_time: str, vote: str, cast_vote_ID: int = -1):
    if cast_vote_ID == -1: # Just use the next available cast_vote_ID
        cast_vote_ID = get_next_ID(connection, cursor, "Cast_Votes")

    # In order for a folk to cast a vote, all these conditions have to be met:
    #   1. voter_ID exists
    #   2. voting_reg_ID exists
    #   3. the corresponding identifier from a voting_reg_ID has to match the voter_ID
    #   4. ballot_ID exists
    #   5. monitor_ID exists
    #   6. vote_time matches the vote_time on the Voting_Registry for this voter_ID
    #   7. voting_reg_ID isn't currently in Cast_Votes
    # A flag being True means it has passed that verification
    flag_1 = value_in_table_column(connection, cursor, "Folks", "personal_ID", voter_ID)
    flag_2 = value_in_table_column(connection, cursor, "Voting_Registry", "voting_reg_ID", voting_reg_ID)
    flag_3 = get_row(connection, cursor, "Folks", "personal_ID", voter_ID)[0][0] == get_row(connection, cursor, "Voting_Registry", "voting_reg_ID", voting_reg_ID)[0][1]
    flag_4 = value_in_table_column(connection, cursor, "Ballots", "ballot_ID", ballot_ID)
    flag_5 = value_in_table_column(connection, cursor, "Election_Staff_Monitor", "staff_ID", monitor_ID)
    flag_6 = vote_time[:10] == get_row(connection, cursor, "Voting_Registry", "voting_reg_ID", voting_reg_ID)[0][2]
    flag_7 = value_in_table_column(connection, cursor, "Cast_Votes", "voting_reg_ID", 25) == False

    # Performs a transaction here
    try:
        if flag_1 == False:
            raise TypeError(f"personal_ID {voter_ID} doesn't exist in Folks table")
        elif flag_2 == False:
            raise TypeError(f"voting_reg_ID {voting_reg_ID} doesn't exist in Voting_Registry table")
        elif flag_3 == False:
            raise TypeError(f"voting_reg_ID {get_row(connection, cursor, 'Folks', 'personal_ID', voter_ID)[0][0]} doesn't match voter_ID {get_row(connection, cursor, 'Voting_Registry', 'voting_reg_ID', voting_reg_ID)[0][1]}")
        elif flag_4 == False:
            raise TypeError(f"ballot_ID {ballot_ID} doesn't exist in Ballots table")
        elif flag_5 == False:
            raise TypeError(f"monitor_ID {monitor_ID} doesn't exist in Election_Staff_Monitor table")
        elif flag_6 == False:
            raise TypeError(f"vote_time {vote_time[:10]} doesn't match vote_date {get_row(connection, cursor, 'Voting_Registry', 'voting_reg_ID', voting_reg_ID)[0][2]} from Voting_Registry")
        elif flag_7 == False:
            raise TypeError(f"voting_reg_ID {voting_reg_ID} has already casted a vote")
        
        cursor.execute("BEGIN TRANSACTION")
        cursor.execute(f"""
                        INSERT INTO Cast_Votes
                        VALUES ({cast_vote_ID}, {voter_ID}, {voting_reg_ID}, {ballot_ID}, {monitor_ID}, '{vote_time[:10]}', '{vote}')
        """)
        cursor.execute("COMMIT")
    except TypeError as e:
        print(f"ERROR - {e}")
    except Exception as e:
        cursor.execute("ROLLBACK")
        print(f"ERROR - {e}")
    finally:
        connection.commit()

def remove_folk(connection, cursor, personal_ID: int):
    # First verify that the Folk we want to remoev even exists
    if value_in_table_column(connection, cursor, "Folks", "personal_ID", personal_ID) == False:
        print("ERROR - Folk with {personal_ID} doesn't exist")
        return -1 # Error code
    
    query = get_row(connection, cursor, "Folks", "personal_ID", personal_ID) # Contains info about the Folk we want to remove
    name_ID = query[0][1]
    emails_ID = query[0][5]

    print(f"name_ID = {name_ID}")
    print(f"emails_ID = {emails_ID}")
    
    # When we're deleting a Folk, we have to first delete its corresponding:
    #   1. Folks_Emails
    #   2. Folks_Name
    #   3. Cast_Votes
    #   4. Voting_Registry
    cursor.execute(f"DELETE FROM Folks_Emails WHERE emails_ID = {emails_ID}")
    cursor.execute(f"DELETE FROM Folks_Name WHERE name_ID = {name_ID}")
    cursor.execute(f"DELETE FROM Cast_Votes WHERE voter_ID = {personal_ID}")
    cursor.execute(f"DELETE FROM Voting_Registry WHERE identifier = {personal_ID}")

    # Now, delete the Folk from the Folks table
    cursor.execute(f"DELETE FROM Folks WHERE personal_ID = {personal_ID}")

    connection.commit()

    pass

def print_table(connection, cursor, column_names, command, col_space = 8, bold_col_names = False):
    query = get_query(connection, cursor, command)

    if column_names == [] and len(query) > 0: # Defaults to just calling it "COLUMN #"
        for i in range(len(query[0])):
            column_names.append(f"COLUMN #{i + 1}")

    if bold_col_names:
        column_names = [col_name.upper() for col_name in column_names]
    
    table = ""

    # First adds the column names
    for col in column_names:
        table += col + (" " * col_space)
    table += "\n"
    
    column_lengths = [len(column_name) for column_name in column_names]
    column_indexes = [table.index(column_name) for column_name in column_names]

    # Adds the rows to the table
    for row_index in range(len(query)):
        for col_index in range(len(query[row_index])):
            data = str(query[row_index][col_index])
            table += data + (" " * (column_lengths[col_index] + col_space - len(data)))
        table += "\n"
    
    print(table)

def format_tuple(list):
    result = "("
    
    for i in range(len(list)):
        if i == 0:
            result += str(list[i])
        else:
            result += ", " + str(list[i])
    
    result += ")"
    
    return result


# End of file