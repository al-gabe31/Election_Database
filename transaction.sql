-- The following transaction was performed using the SQLITE version of how to do a transaction. That is, using try-except-finally blocks where you might use cursor.execute("ROLLBACK")

-- try:
--     if flag_1 == False:
--         raise TypeError(f"personal_ID {voter_ID} doesn't exist in Folks table")
--     elif flag_2 == False:
--         raise TypeError(f"voting_reg_ID {voting_reg_ID} doesn't exist in Voting_Registry table")
--     elif flag_3 == False:
--         raise TypeError(f"voting_reg_ID {get_row(connection, cursor, 'Folks', 'personal_ID', voter_ID)[0][0]} doesn't match voter_ID {get_row(connection, cursor, 'Voting_Registry', 'voting_reg_ID', voting_reg_ID)[0][1]}")
--     elif flag_4 == False:
--         raise TypeError(f"ballot_ID {ballot_ID} doesn't exist in Ballots table")
--     elif flag_5 == False:
--         raise TypeError(f"monitor_ID {monitor_ID} doesn't exist in Election_Staff_Monitor table")
--     elif flag_6 == False:
--         raise TypeError(f"vote_time {vote_time[:10]} doesn't match vote_date {get_row(connection, cursor, 'Voting_Registry', 'voting_reg_ID', voting_reg_ID)[0][2]} from Voting_Registry")
--     elif flag_7 == False:
--         raise TypeError(f"voting_reg_ID {voting_reg_ID} has already casted a vote")
    
--     cursor.execute("BEGIN TRANSACTION")
--     cursor.execute(f"""
--                     INSERT INTO Cast_Votes
--                     VALUES ({cast_vote_ID}, {voter_ID}, {voting_reg_ID}, {ballot_ID}, {monitor_ID}, '{vote_time[:10]}', '{vote}')
--     """)
--     cursor.execute("COMMIT")
-- except TypeError as e:
--     print(f"ERROR - {e}")
-- except Exception as e:
--     cursor.execute("ROLLBACK")
--     print(f"ERROR - {e}")
-- finally:
--     connection.commit()

BEGIN TRANSACTION

-- both vote_time[:10] and vote came from user inputs
INSERT INTO Cast_Votes
VALUES ({cast_vote_ID}, {voter_ID}, {voting_reg_ID}, {ballot_ID}, {monitor_ID}, '{vote_time[:10]}', '{vote}')

COMMIT



-- the following code occurs when there was an exception raised at any point
ROLLBACK