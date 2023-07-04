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

	ALTER TABLE careplans_new
	CHANGE ID id_careplans VARCHAR(50),
	CHANGE PATIENT patient_id VARCHAR(50),
	CHANGE ENCOUNTER encounter_careplans VARCHAR(50),
	CHANGE CODE encounter_code_careplans VARCHAR(20),
	CHANGE DESCRIPTION description_careplans VARCHAR(200),
	CHANGE REASONCODE reason_code_careplans VARCHAR(20),
	CHANGE REASONDESCRIPTION reason_description_careplans VARCHAR(200);

END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- Remove rows that do not conform to column criteria
DROP PROCEDURE IF EXISTS delete_rows;
DELIMITER //
CREATE PROCEDURE delete_rows()
BEGIN    

	DELETE FROM careplans_new -- appropriate patient ID
	WHERE PATIENT NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
	LIMIT 1000000;
	DELETE FROM careplans_new -- appropriate careplan ID
	WHERE ID NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
	LIMIT 1000000;
	DELETE FROM careplans_new -- appropriate encounter ID
	WHERE ENCOUNTER NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
	LIMIT 1000000;
	DELETE FROM careplans_new -- appropriate CODE for encounter
	WHERE CODE NOT REGEXP '^[1-9][0-9]*$'
	LIMIT 1000000;
	DELETE FROM careplans_new -- appropriate start date
	WHERE START NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
	LIMIT 1000000;
	DELETE FROM careplans_new -- appropriate stop death
	WHERE STOP NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND STOP != ''
	LIMIT 1000000;

END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Extract only first occurance of BRITHDATE
DROP PROCEDURE IF EXISTS date_first;
DELIMITER //
CREATE PROCEDURE date_first()
BEGIN
	UPDATE careplans_new
	SET START = SUBSTRING(START, 1, 10)
	WHERE START IS NOT NULL AND START REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
	LIMIT 1000000;
	UPDATE careplans_new
	SET STOP = SUBSTRING(STOP, 1, 10)
	WHERE STOP IS NOT NULL AND STOP REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
	LIMIT 1000000;
END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Convert date to type DATE, add to new columns and delete old ones
DROP PROCEDURE IF EXISTS text2date;
DELIMITER //
CREATE PROCEDURE text2date()
BEGIN
		
	ALTER TABLE careplans_new
	ADD COLUMN start_date_careplans DATE;
	-- Update the values for start date
	UPDATE careplans_new
	SET start_date_careplans = CASE
		WHEN START = '' THEN NULL
		ELSE STR_TO_DATE(START, '%Y-%m-%d')
		END
	LIMIT 1000000;
	-- Remove START column
	ALTER TABLE careplans_new
	DROP COLUMN START;

	-- add a new column of type DATE to hold the stop date
	ALTER TABLE careplans_new
	ADD COLUMN stop_date_careplans DATE;
	-- Update the values for date_of_birth
	UPDATE careplans_new
		SET stop_date_careplans = CASE
			WHEN STOP = '' THEN NULL
			ELSE STR_TO_DATE(STOP, '%Y-%m-%d')
		END
		LIMIT 1000000;
	-- Remove birthdate column
	ALTER TABLE careplans_new
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
	INSERT INTO careplans
	SELECT *
	FROM careplans_new;
END //
DELIMITER ;


################################################################
## LOAD TABLES AND CONSOLIDATE INTO A SINGLE TABLE CAREPLANS  ##
################################################################

###################### Load conditions table from output 1 ###################

-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM careplans; -- 796,057
-- Remove rows that do not conform to column criteria
DELETE FROM careplans -- appropriate patient ID
WHERE PATIENT NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
LIMIT 1000000;
DELETE FROM careplans -- appropriate careplan ID
WHERE ID NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
LIMIT 1000000;
DELETE FROM careplans -- appropriate encounter ID
WHERE ENCOUNTER NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
LIMIT 1000000;
DELETE FROM careplans -- appropriate CODE for encounter
WHERE CODE NOT REGEXP '^[1-9][0-9]*$'
LIMIT 1000000;
DELETE FROM careplans -- appropriate start date
WHERE START NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
LIMIT 1000000;
DELETE FROM careplans -- appropriate stop death
WHERE STOP NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND STOP != ''
LIMIT 1000000;

-- Keep only first for Start and Stop date
UPDATE careplans
SET START = SUBSTRING(START, 1, 10)
WHERE START IS NOT NULL AND START REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
LIMIT 1000000;
UPDATE careplans
SET STOP = SUBSTRING(STOP, 1, 10)
WHERE STOP IS NOT NULL AND STOP REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
LIMIT 1000000;

-- Convert text to date:
-- add a new column of type DATE to hold the date of birth
ALTER TABLE careplans
ADD COLUMN start_date_careplans DATE;
-- Update the values for start date
UPDATE careplans
SET start_date_careplans = CASE
	WHEN START = '' THEN NULL
	ELSE STR_TO_DATE(START, '%Y-%m-%d')
	END
LIMIT 1000000;
-- Remove START column
ALTER TABLE careplans
DROP COLUMN START;

-- add a new column of type DATE to hold the stop date
ALTER TABLE careplans
ADD COLUMN stop_date_careplans DATE;
-- Update the values for date_of_birth
UPDATE careplans
	SET stop_date_careplans = CASE
		WHEN STOP = '' THEN NULL
		ELSE STR_TO_DATE(STOP, '%Y-%m-%d')
	END
	LIMIT 1000000;
-- Remove birthdate column
ALTER TABLE careplans
DROP COLUMN STOP;

-- Change column types to reduce overall size:
ALTER TABLE careplans
CHANGE ID id_careplans VARCHAR(50),
CHANGE PATIENT patient_id VARCHAR(50),
CHANGE ENCOUNTER encounter_careplans VARCHAR(50),
CHANGE CODE encounter_code_careplans VARCHAR(20),
CHANGE DESCRIPTION description_careplans VARCHAR(200),
CHANGE REASONCODE reason_code_careplans VARCHAR(20),
CHANGE REASONDESCRIPTION reason_description_careplans VARCHAR(200);


SELECT * FROM careplans LIMIT 4;
SELECT COUNT(*) FROM careplans; -- 796,057

###################### Load careplans table from output 2 ###################
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
SELECT COUNT(*) FROM careplans; -- 796,057
SELECT COUNT(*) FROM careplans_new; -- 798,986
INSERT INTO careplans
SELECT *
FROM careplans_new;
SELECT COUNT(*) FROM careplans; -- 1,595,043
DROP TABLE careplans_new;

###################### Load careplans table from output 3 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM careplans; -- 1,595,043
SELECT COUNT(*) FROM careplans_new; -- 793,686

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM careplans; -- 2,388,911
SELECT COUNT(*) FROM careplans_new; -- 793,868
DROP TABLE careplans_new;

###################### Load careplans table from output 4 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM careplans; -- 2,388,911
SELECT COUNT(*) FROM careplans_new; -- 795,442

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM careplans; -- 3,184,353
DROP TABLE careplans_new;

###################### Load careplans table from output 5 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM careplans; -- 3,184,353
SELECT COUNT(*) FROM careplans_new; -- 797,496

-- Clean and merge:
CALL clean_mergeNdrop(); 	

SELECT COUNT(*) FROM careplans; -- 3,981,849
DROP TABLE careplans_new;

###################### Load careplans table from output 6 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM careplans; -- 3,981,849
SELECT COUNT(*) FROM careplans_new; -- 796,311

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM careplans; -- 4,778,160
DROP TABLE careplans_new;

###################### Load careplans table from output 7 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM careplans; -- 4,778,160
SELECT COUNT(*) FROM careplans_new; -- 792,513

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM careplans; -- 5,570,673
DROP TABLE careplans_new;

###################### Load careplans table from output 8 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM careplans; -- 5,570,673
SELECT COUNT(*) FROM careplans_new; -- 798,982

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM careplans; -- 6,369,655
DROP TABLE careplans_new;

###################### Load careplans table from output 9 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM careplans; -- 6,369,655
SELECT COUNT(*) FROM careplans_new; -- 798,549

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM careplans; -- 7,168,204
DROP TABLE careplans_new;

###################### Load careplans table from output 10 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM careplans; -- 7,168,204
SELECT COUNT(*) FROM careplans_new; -- 795,362

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM careplans; -- 7,963,566
DROP TABLE careplans_new;


###################### Load careplans table from output 11 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM careplans; -- 7,963,566
SELECT COUNT(*) FROM careplans_new; -- 799,279

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM careplans; -- 8,762,836
DROP TABLE careplans_new;

###################### Load careplans table from output 12 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM careplans; -- 8,762,836
SELECT COUNT(*) FROM careplans_new; -- 795,823

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM careplans; -- 9,558,659
DROP TABLE careplans_new;