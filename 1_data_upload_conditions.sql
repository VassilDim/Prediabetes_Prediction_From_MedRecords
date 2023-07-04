-- Set global environment to process large files
-- Server restart required
SET GLOBAL max_allowed_packet = 100800949;
SET GLOBAL max_execution_time = 60000;
SET GLOBAL wait_timeout = 360000;

USE prediabetes;

#######################################################
############## PROCEDURES AND FUNCTIONS ###############
#######################################################

-- change data types:
DROP PROCEDURE IF EXISTS modify_table_types;
DELIMITER //
CREATE PROCEDURE modify_table_types()
BEGIN

	ALTER TABLE conditions_new
	CHANGE PATIENT patient_id VARCHAR(50),
	CHANGE ENCOUNTER encounter_conditions VARCHAR(50),
	CHANGE CODE encounter_code_conditions VARCHAR(20),
	CHANGE DESCRIPTION description_conditions VARCHAR(200);

END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- Remove rows that do not conform to column criteria
DROP PROCEDURE IF EXISTS delete_rows;
DELIMITER //
CREATE PROCEDURE delete_rows()
BEGIN    

	DELETE FROM conditions_new -- appropriate patient ID
	WHERE PATIENT NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
	LIMIT 700000;
	DELETE FROM conditions_new -- appropriate encounter ID
	WHERE ENCOUNTER NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
	LIMIT 700000;
	DELETE FROM conditions_new -- appropriate CODE for encounter
	WHERE CODE NOT REGEXP '^[1-9][0-9]*$'
	LIMIT 700000;
	DELETE FROM conditions_new -- appropriate start date
	WHERE START NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
	LIMIT 700000;
	DELETE FROM conditions_new -- appropriate stop death
	WHERE STOP NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND STOP != ''
	LIMIT 700000;

END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Extract only first occurance of BRITHDATE
DROP PROCEDURE IF EXISTS date_first;
DELIMITER //
CREATE PROCEDURE date_first()
BEGIN
	UPDATE conditions_new
	SET START = SUBSTRING(START, 1, 10)
	WHERE START IS NOT NULL AND START REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
	LIMIT 700000;
	UPDATE conditions_new
	SET STOP = SUBSTRING(STOP, 1, 10)
	WHERE STOP IS NOT NULL AND STOP REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
	LIMIT 700000;
END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Convert date to type DATE, add to new columns and delete old ones
DROP PROCEDURE IF EXISTS text2date;
DELIMITER //
CREATE PROCEDURE text2date()
BEGIN
		
	ALTER TABLE conditions_new
	ADD COLUMN start_date_conditions DATE;
	-- Update the values for start date
	UPDATE conditions_new
	SET start_date_conditions = CASE
		WHEN START = '' THEN NULL
		ELSE STR_TO_DATE(START, '%Y-%m-%d')
		END
	LIMIT 700000;
	-- Remove START column
	ALTER TABLE conditions_new
	DROP COLUMN START;

	-- add a new column of type DATE to hold the stop date
	ALTER TABLE conditions_new
	ADD COLUMN stop_date_conditions DATE;
	-- Update the values for date_of_birth
	UPDATE conditions_new
		SET stop_date_conditions = CASE
			WHEN STOP = '' THEN NULL
			ELSE STR_TO_DATE(STOP, '%Y-%m-%d')
		END
		LIMIT 700000;
	-- Remove birthdate column
	ALTER TABLE conditions_new
	DROP COLUMN STOP;

END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Fix new uploaded patients table by using established procedures
-- and concatinate to existing patients table
DROP PROCEDURE IF EXISTS clean_mergeNdrop;
DELIMITER //
CREATE PROCEDURE clean_mergeNdrop()
BEGIN
	CALL date_first();
    CALL date_first();
	CALL delete_rows();
	CALL modify_table_types();
	CALL text2date();
	INSERT INTO conditions
	SELECT *
	FROM conditions_new;
END //
DELIMITER ;


################################################################
## LOAD TABLES AND CONSOLIDATE INTO A SINGLE TABLE ALLERGIES #
################################################################

###################### Load conditions table from output 1 ###################

-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM conditions;
-- Remove rows that do not conform to column criteria
DELETE FROM conditions -- appropriate patient ID
WHERE PATIENT NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
LIMIT 500000;
DELETE FROM conditions -- appropriate encounter ID
WHERE ENCOUNTER NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
LIMIT 500000;
DELETE FROM conditions -- appropriate CODE for encounter
WHERE CODE NOT REGEXP '^[1-9][0-9]*$'
LIMIT 500000;
DELETE FROM conditions -- appropriate start date
WHERE START NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
LIMIT 500000;
DELETE FROM conditions -- appropriate stop death
WHERE STOP NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND STOP != ''
LIMIT 500000;

-- Keep only first for Start and Stop date
UPDATE conditions
SET START = SUBSTRING(START, 1, 10)
WHERE START IS NOT NULL AND START REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
LIMIT 500000;
UPDATE conditions
SET STOP = SUBSTRING(STOP, 1, 10)
WHERE STOP IS NOT NULL AND STOP REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
LIMIT 500000;

-- Convert text to date:
-- add a new column of type DATE to hold the date of birth
ALTER TABLE conditions
ADD COLUMN start_date_conditions DATE;
-- Update the values for start date
UPDATE conditions
SET start_date_conditions = CASE
	WHEN START = '' THEN NULL
	ELSE STR_TO_DATE(START, '%Y-%m-%d')
	END
LIMIT 500000;
-- Remove START column
ALTER TABLE conditions
DROP COLUMN START;

-- add a new column of type DATE to hold the stop date
ALTER TABLE conditions
ADD COLUMN stop_date_conditions DATE;
-- Update the values for date_of_birth
UPDATE conditions
	SET stop_date_conditions = CASE
		WHEN STOP = '' THEN NULL
		ELSE STR_TO_DATE(STOP, '%Y-%m-%d')
	END
	LIMIT 500000;
-- Remove birthdate column
ALTER TABLE conditions
DROP COLUMN STOP;

-- Change column types to reduce overall size:
ALTER TABLE conditions
CHANGE PATIENT patient_id VARCHAR(50),
CHANGE ENCOUNTER encounter_conditions VARCHAR(50),
CHANGE CODE encounter_code_conditions VARCHAR(20),
CHANGE DESCRIPTION description_conditions VARCHAR(200);

SELECT COUNT(*) FROM conditions; -- 483,462


###################### Load conditions table from output 2 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
-- Fix dates keeping only first occurrence
CALL date_first();
-- Delete entries with bad/inappropriate entries corresponding to each column
CALL delete_rows();
-- Transform dates from text to date format
CALL text2date();
-- Modify column data type and names:
CALL modify_table_types();
-- Merge to patients table and delete new
SELECT COUNT(*) FROM conditions; -- 483,462
SELECT COUNT(*) FROM conditions_new; -- 486,158
INSERT INTO conditions
SELECT *
FROM conditions_new;
SELECT COUNT(*) FROM conditions; -- 969,620
DROP TABLE conditions_new;

###################### Load conditions table from output 3 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM conditions; -- 969,620
SELECT COUNT(*) FROM conditions_new; -- 483,329

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM conditions; -- 1,452,949
SELECT COUNT(*) FROM conditions_new; -- 483,329
DROP TABLE conditions_new;

###################### Load conditions table from output 4 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM conditions; -- 1,452,949
SELECT COUNT(*) FROM conditions_new; -- 484,564

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM conditions; -- 1,937,513
DROP TABLE conditions_new;

###################### Load conditions table from output 5 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM conditions; -- 1,937,513
SELECT COUNT(*) FROM conditions_new; -- 485,284

-- Clean and merge:
CALL clean_mergeNdrop(); 	

SELECT COUNT(*) FROM conditions; -- 2,422,797
DROP TABLE conditions_new;

###################### Load conditions table from output 6 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM conditions; -- 2,422,797
SELECT COUNT(*) FROM conditions_new; -- 484,722

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM conditions; -- 2,907,519
DROP TABLE conditions_new;

###################### Load conditions table from output 7 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM conditions; -- 2,907,51
SELECT COUNT(*) FROM conditions_new; -- 482,052

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM conditions; -- 3,389,571
DROP TABLE conditions_new;

###################### Load conditions table from output 8 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM conditions; -- 3,389,571
SELECT COUNT(*) FROM conditions_new; -- 483,364

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM conditions; -- 3,872,935
DROP TABLE conditions_new;

###################### Load conditions table from output 9 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM conditions; -- 3,872,935
SELECT COUNT(*) FROM conditions_new; -- 484,938

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM conditions; -- 4,357,873
DROP TABLE conditions_new;

###################### Load conditions table from output 10 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM conditions; -- 4,357,873
SELECT COUNT(*) FROM conditions_new; -- 483,035

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM conditions; -- 4,840,908
DROP TABLE conditions_new;


###################### Load conditions table from output 11 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM conditions; -- 4,840,908
SELECT COUNT(*) FROM conditions_new; -- 484,349

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM conditions; -- 5,325,257
DROP TABLE conditions_new;

###################### Load conditions table from output 12 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM conditions; -- 5,325,257
SELECT COUNT(*) FROM conditions_new; -- 484,697

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM conditions; -- 5,809,954
DROP TABLE conditions_new;