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
ALTER TABLE allergies_new
	CHANGE PATIENT patient_id VARCHAR(50),
	CHANGE ENCOUNTER encounter_allergy VARCHAR(50),
	CHANGE CODE encounter_code_allergy VARCHAR(20),
	CHANGE DESCRIPTION description_allergy VARCHAR(200);
END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- Remove rows that do not conform to column criteria
DROP PROCEDURE IF EXISTS delete_rows;
DELIMITER //
CREATE PROCEDURE delete_rows()
BEGIN    
	DELETE FROM allergies_new -- appropriate patient ID
	WHERE PATIENT NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
	LIMIT 450000;
	DELETE FROM allergies_new -- appropriate encounter ID
	WHERE ENCOUNTER NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
	LIMIT 450000;
	DELETE FROM allergies_new -- appropriate CODE for encounter
	WHERE CODE NOT REGEXP '^[1-9][0-9]*$'
	LIMIT 450000;
	DELETE FROM allergies_new -- appropriate start date
	WHERE START NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
	LIMIT 450000;
	DELETE FROM allergies_new -- appropriate stop death
	WHERE STOP NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND STOP != ''
	LIMIT 450000;
END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Extract only first occurance of BRITHDATE
DROP PROCEDURE IF EXISTS date_first;
DELIMITER //
CREATE PROCEDURE date_first()
BEGIN
	UPDATE allergies_new
	SET START = SUBSTRING(START, 1, 10)
	WHERE START IS NOT NULL AND START REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
	LIMIT 450000;
	UPDATE allergies_new
	SET STOP = SUBSTRING(STOP, 1, 10)
	WHERE STOP IS NOT NULL AND STOP REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
	LIMIT 450000;
END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Convert date to type DATE, add to new columns and delete old ones
DROP PROCEDURE IF EXISTS text2date;
DELIMITER //
CREATE PROCEDURE text2date()
BEGIN
	ALTER TABLE allergies_new
	ADD COLUMN start_date DATE;
	-- Update the values for start date
	UPDATE allergies_new
	SET start_date = CASE
	WHEN START = '' THEN NULL
	ELSE STR_TO_DATE(START, '%Y-%m-%d')
	END
	LIMIT 450000;
	-- Remove START column
	ALTER TABLE allergies_new
	DROP COLUMN START;

	-- add a new column of type DATE to hold the stop date
	ALTER TABLE allergies_new
	ADD COLUMN stop_date DATE;
	-- Update the values for date_of_birth
	UPDATE allergies_new
	SET stop_date = CASE
	WHEN STOP = '' THEN NULL
	ELSE STR_TO_DATE(STOP, '%Y-%m-%d')
	END
	LIMIT 450000;
	-- Remove birthdate column
	ALTER TABLE allergies_new
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
	INSERT INTO allergies
	SELECT *
	FROM allergies_new;
END //
DELIMITER ;


################################################################
## LOAD TABLES AND CONSOLIDATE INTO A SINGLE TABLE ALLERGIES #
################################################################

###################### Load allergy table from output 1 ###################

-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types

-- Remove rows that do not conform to column criteria
DELETE FROM allergies -- appropriate patient ID
WHERE PATIENT NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
LIMIT 450000;
DELETE FROM allergies -- appropriate encounter ID
WHERE ENCOUNTER NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
LIMIT 450000;
DELETE FROM allergies -- appropriate CODE for encounter
WHERE CODE NOT REGEXP '^[1-9][0-9]*$'
LIMIT 450000;
DELETE FROM allergies -- appropriate start date
WHERE START NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
LIMIT 450000;
DELETE FROM allergies -- appropriate stop death
WHERE STOP NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND STOP != ''
LIMIT 450000;

-- Keep only first for Start and Stop date
UPDATE allergies
SET START = SUBSTRING(START, 1, 10)
WHERE START IS NOT NULL AND START REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
LIMIT 450000;
UPDATE allergies
SET STOP = SUBSTRING(STOP, 1, 10)
WHERE STOP IS NOT NULL AND STOP REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
LIMIT 450000;

-- Convert text to date:
-- add a new column of type DATE to hold the date of birth
ALTER TABLE allergies
ADD COLUMN start_date DATE;
-- Update the values for start date
UPDATE allergies
SET start_date = CASE
	WHEN START = '' THEN NULL
	ELSE STR_TO_DATE(START, '%Y-%m-%d')
	END
LIMIT 450000;
-- Remove START column
ALTER TABLE allergies
DROP COLUMN START;

-- add a new column of type DATE to hold the stop date
ALTER TABLE allergies
ADD COLUMN stop_date DATE;
-- Update the values for date_of_birth
UPDATE allergies
	SET stop_date = CASE
		WHEN STOP = '' THEN NULL
		ELSE STR_TO_DATE(STOP, '%Y-%m-%d')
	END
	LIMIT 450000;
-- Remove birthdate column
ALTER TABLE allergies
DROP COLUMN STOP;

-- Change column types to reduce overall size:
ALTER TABLE allergies
CHANGE PATIENT patient_id VARCHAR(50),
CHANGE ENCOUNTER encounter_allergy VARCHAR(50),
CHANGE CODE encounter_code_allergy VARCHAR(20),
CHANGE DESCRIPTION description_allergy VARCHAR(200);

SELECT COUNT(*) FROM allergies; -- 51,739


###################### Load medications table from output 2 ###################

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
SELECT COUNT(*) FROM allergies; -- 51,739
SELECT COUNT(*) FROM allergies_new; -- 51,896
INSERT INTO allergies
SELECT *
FROM allergies_new;
SELECT COUNT(*) FROM allergies; -- 103,635
DROP TABLE allergies_new;

###################### Load medications table from output 3 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM allergies; -- 103,635
SELECT COUNT(*) FROM allergies_new; -- 52,400

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM allergies; -- 156,035
DROP TABLE allergies_new;

###################### Load medications table from output 4 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM allergies; -- 156,035
SELECT COUNT(*) FROM allergies_new; -- 52,487

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM allergies; -- 208,522
DROP TABLE allergies_new;

###################### Load medications table from output 5 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM allergies; -- 208,5225
SELECT COUNT(*) FROM allergies_new; -- 52,211

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM allergies; -- 260,733
DROP TABLE allergies_new;

###################### Load medications table from output 6 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM allergies; -- 260,733
SELECT COUNT(*) FROM allergies_new; -- 52,449

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM allergies; -- 313,182
DROP TABLE allergies_new;

###################### Load medications table from output 7 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM allergies; -- 313,182
SELECT COUNT(*) FROM allergies_new; -- 52,357

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM allergies; -- 365,539
DROP TABLE allergies_new;

###################### Load medications table from output 8 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM allergies; -- 365,539
SELECT COUNT(*) FROM allergies_new; -- 52,323

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM allergies; -- 417,862
DROP TABLE allergies_new;

###################### Load medications table from output 9 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM allergies; -- 417,862
SELECT COUNT(*) FROM allergies_new; -- 51,674

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM allergies; -- 469,536
DROP TABLE allergies_new;

###################### Load medications table from output 10 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM allergies; -- 469,536
SELECT COUNT(*) FROM allergies_new; -- 51,579

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM allergies; -- 521,115
DROP TABLE allergies_new;

###################### Load medications table from output 11 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM allergies; -- 521,115
SELECT COUNT(*) FROM allergies_new; -- 51,911

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM allergies; -- 573,026
DROP TABLE allergies_new;

###################### Load medications table from output 12 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM allergies; -- 573,026
SELECT COUNT(*) FROM allergies_new; -- 51,585

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM allergies; -- 624,611
DROP TABLE allergies_new;