-- Set global environment to process large files
-- Server restart required
SET GLOBAL max_allowed_packet = 100800949;
SET GLOBAL max_execution_time = 6000;
SET GLOBAL wait_timeout = 36000;

USE prediabetes;

#######################################################
############## PROCEDURES AND FUNCTIONS ###############
#######################################################

-- change data types:
DROP PROCEDURE modify_medications_table_types;
DELIMITER //
CREATE PROCEDURE modify_medications_table_types()
BEGIN
	ALTER TABLE medications_new
	CHANGE PATIENT patient_id VARCHAR(50),
	CHANGE ENCOUNTER encounter VARCHAR(50),
	CHANGE CODE encounter_code VARCHAR(20),
	CHANGE DESCRIPTION description VARCHAR(200),
	CHANGE REASONCODE encounter_reason_code VARCHAR(20),
	CHANGE REASONDESCRIPTION encounter_reason_description VARCHAR(200);
END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- Remove rows that do not conform to column criteria
DROP PROCEDURE delete_rows;
DELIMITER //
CREATE PROCEDURE delete_rows()
BEGIN    
	DELETE FROM medications_new -- appropriate patient ID
	WHERE PATIENT NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
	LIMIT 450000;
	DELETE FROM medications_new -- appropriate encounter ID
	WHERE ENCOUNTER NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
	LIMIT 450000;
	DELETE FROM medications_new -- appropriate CODE for encounter
	WHERE CODE NOT REGEXP '^[1-9][0-9]*$'
	LIMIT 450000;
	DELETE FROM medications_new -- appropriate start date
	WHERE START NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
	LIMIT 450000;
	DELETE FROM medications_new -- appropriate stop death
	WHERE STOP NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND STOP != ''
	LIMIT 450000;
END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Extract only first occurance of BRITHDATE
DROP PROCEDURE date_first;
DELIMITER //
CREATE PROCEDURE date_first()
BEGIN
    UPDATE medications_new
	SET START = SUBSTRING(START, 1, 10)
	WHERE START IS NOT NULL AND START REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
	LIMIT 450000;
	UPDATE medications_new
	SET STOP = SUBSTRING(STOP, 1, 10)
	WHERE STOP IS NOT NULL AND STOP REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
	LIMIT 450000;
END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


-- Convert date to type DATE, add to new columns and delete old ones
DROP PROCEDURE text2date;
DELIMITER //
CREATE PROCEDURE text2date()
BEGIN
	ALTER TABLE medications_new
	ADD COLUMN start_date DATE;
	-- Update the values for start date
	UPDATE medications_new
	SET start_date = CASE
		WHEN START = '' THEN NULL
		ELSE STR_TO_DATE(START, '%Y-%m-%d')
	END
	LIMIT 450000;
	-- Remove START column
	ALTER TABLE medications_new
	DROP COLUMN START;

	-- add a new column of type DATE to hold the stop date
	ALTER TABLE medications_new
	ADD COLUMN stop_date DATE;
	-- Update the values for date_of_birth
	UPDATE medications_new
		SET stop_date = CASE
			WHEN STOP = '' THEN NULL
			ELSE STR_TO_DATE(STOP, '%Y-%m-%d')
		END
		LIMIT 450000;
	-- Remove birthdate column
	ALTER TABLE medications_new
	DROP COLUMN STOP;
END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Fix new uploaded patients table by using established procedures
-- and concatinate to existing patients table
DROP PROCEDURE clean_mergeNdrop;
DELIMITER //
CREATE PROCEDURE clean_mergeNdrop()
BEGIN
	CALL date_first();
    CALL date_first();
	CALL delete_rows();
	CALL modify_medications_table_types();
	CALL text2date();
	INSERT INTO medications
	SELECT *
	FROM medications_new;
END //
DELIMITER ;


################################################################
## LOAD TABLES AND CONSOLIDATE INTO A SINGLE TABLE MEDICATIONS #
################################################################

###################### Load medications table from output 1 ###################

-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types

-- Remove rows that do not conform to column criteria
DELETE FROM medications -- appropriate patient ID
WHERE PATIENT NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
LIMIT 450000;
DELETE FROM medications -- appropriate encounter ID
WHERE ENCOUNTER NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
LIMIT 450000;
DELETE FROM medications -- appropriate CODE for encounter
WHERE CODE NOT REGEXP '^[1-9][0-9]*$'
LIMIT 450000;
DELETE FROM medications -- appropriate start date
WHERE START NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
LIMIT 450000;
DELETE FROM medications -- appropriate stop death
WHERE STOP NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND STOP != ''
LIMIT 450000;

-- Keep only first for Start and Stop date
UPDATE medications
SET START = SUBSTRING(START, 1, 10)
WHERE START IS NOT NULL AND START REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
LIMIT 450000;
UPDATE medications
SET STOP = SUBSTRING(STOP, 1, 10)
WHERE STOP IS NOT NULL AND STOP REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
LIMIT 450000;

-- Convert text to date:
-- add a new column of type DATE to hold the date of birth
ALTER TABLE medications
ADD COLUMN start_date DATE;
-- Update the values for start date
UPDATE medications
SET start_date = CASE
	WHEN START = '' THEN NULL
	ELSE STR_TO_DATE(START, '%Y-%m-%d')
END
LIMIT 450000;
-- Remove START column
ALTER TABLE medications
DROP COLUMN START;

-- add a new column of type DATE to hold the stop date
ALTER TABLE medications
ADD COLUMN stop_date DATE;
-- Update the values for date_of_birth
UPDATE medications
	SET stop_date = CASE
		WHEN STOP = '' THEN NULL
		ELSE STR_TO_DATE(STOP, '%Y-%m-%d')
	END
	LIMIT 450000;
-- Remove birthdate column
ALTER TABLE medications
DROP COLUMN STOP;

-- Change column types to reduce overall size:
ALTER TABLE medications
CHANGE PATIENT patient_id VARCHAR(50),
CHANGE ENCOUNTER encounter VARCHAR(50),
CHANGE CODE encounter_code VARCHAR(20),
CHANGE DESCRIPTION description VARCHAR(200),
CHANGE REASONCODE encounter_reason_code VARCHAR(20),
CHANGE REASONDESCRIPTION encounter_reason_description VARCHAR(200);


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
CALL modify_medications_table_types();

-- Merge to patients table and delete new
SELECT COUNT(*) FROM medications; -- 397,877
SELECT COUNT(*) FROM medications_new; -- 398,771
INSERT INTO medications
SELECT *
FROM medications_new;
SELECT COUNT(*) FROM medications; -- 796,648
DROP TABLE medications_new;


###################### Load medications table from output 3 ###################

-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types

-- Fix dates keeping only first occurrence
CALL date_first();

-- Delete entries with bad/inappropriate entries corresponding to each column
CALL delete_rows();

-- Transform dates from text to date format
CALL text2date();

-- Modify column data type and names:
CALL modify_medications_table_types();

-- Merge to patients table and delete new
SELECT COUNT(*) FROM medications; -- 796648
SELECT COUNT(*) FROM medications_new; -- 397,702
INSERT INTO medications
SELECT *
FROM medications_new;
SELECT COUNT(*) FROM medications; -- 1,193,850
DROP TABLE medications_new;


###################### Load medications table from output 4 ###################

-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types

-- Fix dates keeping only first occurrence
CALL date_first();

-- Delete entries with bad/inappropriate entries corresponding to each column
CALL delete_rows();

-- Transform dates from text to date format
CALL text2date();

-- Modify column data type and names:
CALL modify_medications_table_types();

-- Merge to patients table and delete new
SELECT COUNT(*) FROM medications; -- 1,193,850
SELECT COUNT(*) FROM medications_new; -- 398,808
INSERT INTO medications
SELECT *
FROM medications_new;
SELECT COUNT(*) FROM medications; -- 1,592,658
DROP TABLE medications_new;


###################### Load medications table from output 5 ###################

-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types

-- Fix dates keeping only first occurrence
CALL date_first();

-- Delete entries with bad/inappropriate entries corresponding to each column
CALL delete_rows();

-- Transform dates from text to date format
CALL text2date();

-- Modify column data type and names:
CALL modify_medications_table_types();

-- Merge to patients table and delete new
SELECT COUNT(*) FROM medications; -- 1,592,658
SELECT COUNT(*) FROM medications_new; -- 398,481
INSERT INTO medications
SELECT *
FROM medications_new;
SELECT COUNT(*) FROM medications; -- 1,991,139
DROP TABLE medications_new;

###################### Load medications table from output 6 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types

-- Fix dates keeping only first occurrence
CALL date_first();

-- Delete entries with bad/inappropriate entries corresponding to each column
CALL delete_rows();

-- Transform dates from text to date format
CALL text2date();

-- Modify column data type and names:
CALL modify_medications_table_types();

-- Merge to patients table and delete new
SELECT COUNT(*) FROM medications; -- 1,991,139
SELECT COUNT(*) FROM medications_new; -- 400,729
INSERT INTO medications
SELECT *
FROM medications_new;
SELECT COUNT(*) FROM medications; -- 2,391,868
DROP TABLE medications_new;

###################### Load medications table from output 7 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types

-- Fix dates keeping only first occurrence
CALL date_first();

-- Delete entries with bad/inappropriate entries corresponding to each column
CALL delete_rows();

-- Transform dates from text to date format
CALL text2date();

-- Modify column data type and names:
CALL modify_medications_table_types();

-- Merge to patients table and delete new
SELECT COUNT(*) FROM medications; -- 2,391,868
SELECT COUNT(*) FROM medications_new; -- 394,937
INSERT INTO medications
SELECT *
FROM medications_new;
SELECT COUNT(*) FROM medications; -- 2,786,805
DROP TABLE medications_new;

###################### Load medications table from output 8 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types

-- Fix dates keeping only first occurrence
CALL date_first();

-- Delete entries with bad/inappropriate entries corresponding to each column
CALL delete_rows();

-- Transform dates from text to date format
CALL text2date();

-- Modify column data type and names:
CALL modify_medications_table_types();

-- Merge to patients table and delete new
SELECT COUNT(*) FROM medications; -- 2,786,805
SELECT COUNT(*) FROM medications_new; -- 397,710
INSERT INTO medications
SELECT *
FROM medications_new;
SELECT COUNT(*) FROM medications; -- 3,184,515
DROP TABLE medications_new;

###################### Load medications table from output 10 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types

-- Fix dates keeping only first occurrence
CALL date_first();

-- Delete entries with bad/inappropriate entries corresponding to each column
CALL delete_rows();

-- Transform dates from text to date format
CALL text2date();

-- Modify column data type and names:
CALL modify_medications_table_types();

-- Merge to patients table and delete new
SELECT COUNT(*) FROM medications; -- 3,584,297
SELECT COUNT(*) FROM medications_new; -- 400,492
INSERT INTO medications
SELECT *
FROM medications_new;
SELECT COUNT(*) FROM medications; -- 3,984,789
DROP TABLE medications_new;

###################### Load medications table from output 11 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types

-- Fix dates keeping only first occurrence
CALL date_first();

-- Delete entries with bad/inappropriate entries corresponding to each column
CALL delete_rows();

-- Transform dates from text to date format
CALL text2date();

-- Modify column data type and names:
CALL modify_medications_table_types();

-- Merge to patients table and delete new
SELECT COUNT(*) FROM medications; -- 3,984,789
SELECT COUNT(*) FROM medications_new; -- 397,444
INSERT INTO medications
SELECT *
FROM medications_new;
SELECT COUNT(*) FROM medications; -- 4,382,233
DROP TABLE medications_new;

###################### Load medications table from output 12 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types

-- Fix dates keeping only first occurrence
CALL date_first();

-- Delete entries with bad/inappropriate entries corresponding to each column
CALL delete_rows();

-- Transform dates from text to date format
CALL text2date();

-- Modify column data type and names:
CALL modify_medications_table_types();

-- Merge to patients table and delete new
SELECT COUNT(*) FROM medications; -- 4,382,233
SELECT COUNT(*) FROM medications_new; -- 399,723
INSERT INTO medications
SELECT *
FROM medications_new;
SELECT COUNT(*) FROM medications; -- 4,781,956
DROP TABLE medications_new;

-- patients on any kind of medications
SELECT COUNT(DISTINCT patient_id) FROM medications; -- 1,280,688