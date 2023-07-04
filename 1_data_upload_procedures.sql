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

	ALTER TABLE procedures_new
	CHANGE PATIENT patient_id VARCHAR(50),
	CHANGE ENCOUNTER encounter_procedure VARCHAR(50),
	CHANGE CODE encounter_code_procedure VARCHAR(20),
	CHANGE DESCRIPTION description_procedure VARCHAR(200),
	CHANGE REASONCODE encounter_reasoncode_procedure VARCHAR(20),
	CHANGE REASONDESCRIPTION description_reason_procedure VARCHAR(200);
END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- Remove rows that do not conform to column criteria
DROP PROCEDURE IF EXISTS delete_rows;
DELIMITER //
CREATE PROCEDURE delete_rows()
BEGIN    

	DELETE FROM procedures_new -- appropriate patient ID
	WHERE PATIENT NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
	LIMIT 1000000;
	DELETE FROM procedures_new -- appropriate encounter ID
	WHERE ENCOUNTER NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
	LIMIT 1000000;
	DELETE FROM procedures_new -- appropriate CODE for encounter
	WHERE CODE NOT REGEXP '^[1-9][0-9]*$'
	LIMIT 1000000;
	DELETE FROM procedures_new -- appropriate start date
	WHERE DATE NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
	LIMIT 1000000;

END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Extract only first occurance of BRITHDATE
DROP PROCEDURE IF EXISTS date_first;
DELIMITER //
CREATE PROCEDURE date_first()
BEGIN
	UPDATE procedures_new
	SET DATE = SUBSTRING(DATE, 1, 10)
	WHERE DATE IS NOT NULL AND DATE REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
	LIMIT 1000000;
END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Convert date to type DATE, add to new columns and delete old ones
DROP PROCEDURE IF EXISTS text2date;
DELIMITER //
CREATE PROCEDURE text2date()
BEGIN
		
	ALTER TABLE procedures_new
	ADD COLUMN date_procedure DATE;
	-- Update the values for start date
	UPDATE procedures_new
	SET date_procedure = CASE
		WHEN DATE = '' THEN NULL
		ELSE STR_TO_DATE(DATE, '%Y-%m-%d')
		END
	LIMIT 1000000;
	-- Remove DATE column
	ALTER TABLE procedures_new
	DROP COLUMN DATE;

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
	INSERT INTO procedures
	SELECT *
	FROM procedures_new;
END //
DELIMITER ;


#################################################################
## LOAD TABLES AND CONSOLIDATE INTO A SINGLE TABLE PROCEDURES  ##
#################################################################

###################### Load procedures table from output 1 ###################

-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM procedures; -- 628,785
-- Remove rows that do not conform to column criteria
DELETE FROM procedures -- appropriate patient ID
WHERE PATIENT NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
LIMIT 1000000;
DELETE FROM procedures -- appropriate encounter ID
WHERE ENCOUNTER NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
LIMIT 1000000;
DELETE FROM procedures -- appropriate CODE for encounter
WHERE CODE NOT REGEXP '^[1-9][0-9]*$'
LIMIT 1000000;
DELETE FROM procedures -- appropriate start date
WHERE DATE NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
LIMIT 1000000;


-- Keep only first for Start and Stop date
UPDATE procedures
SET DATE = SUBSTRING(DATE, 1, 10)
WHERE DATE IS NOT NULL AND DATE REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
LIMIT 1000000;

-- Convert text to date:
-- add a new column of type DATE to hold the date of birth
ALTER TABLE procedures
ADD COLUMN date_procedure DATE;
-- Update the values for start date
UPDATE procedures
SET date_procedure = CASE
	WHEN DATE = '' THEN NULL
	ELSE STR_TO_DATE(DATE, '%Y-%m-%d')
	END
LIMIT 1000000;
-- Remove DATE column
ALTER TABLE procedures
DROP COLUMN DATE;


-- Change column types to reduce overall size:
ALTER TABLE procedures
CHANGE PATIENT patient_id VARCHAR(50),
CHANGE ENCOUNTER encounter_procedure VARCHAR(50),
CHANGE CODE encounter_code_procedure VARCHAR(20),
CHANGE DESCRIPTION description_procedure VARCHAR(200),
CHANGE REASONCODE encounter_reasoncode_procedure VARCHAR(20),
CHANGE REASONDESCRIPTION description_reason_procedure VARCHAR(200);

SELECT * FROM procedures LIMIT 4;
SELECT COUNT(*) FROM procedures; -- 628,785

###################### Load immunizations table from output 2 ###################
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
SELECT COUNT(*) FROM procedures; -- 628,785
SELECT COUNT(*) FROM procedures_new; -- 627,139
INSERT INTO procedures
SELECT *
FROM procedures_new;
SELECT COUNT(*) FROM procedures; -- 1,255,924
DROP TABLE procedures_new;

###################### Load procedures table from output 3 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM procedures; -- 1,255,924
SELECT COUNT(*) FROM procedures_new; -- 626,002

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM procedures; -- 1,881,926
DROP TABLE procedures_new;

###################### Load immunizations table from output 4 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM procedures; -- 1,881,926
SELECT COUNT(*) FROM procedures_new; -- 623,646

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM procedures; -- 2,505,572
DROP TABLE procedures_new;

###################### Load procedures table from output 5 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types

-- Clean and merge:
CALL clean_mergeNdrop(); 	

SELECT COUNT(*) FROM procedures_new; -- 622,851
SELECT COUNT(*) FROM procedures; -- 3,128,423
DROP TABLE immunizations_new;

###################### Load procedures table from output 6 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM procedures_new; -- 628,817

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM procedures_new; -- 628,817
SELECT COUNT(*) FROM procedures; -- 3,757,240
DROP TABLE procedures_new;

###################### Load procedures table from output 7 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM procedures_new; -- 622,581

-- Clean and merge:
CALL clean_mergeNdrop();
SELECT COUNT(*) FROM procedures_new; -- 622,581
SELECT COUNT(*) FROM procedures; -- 4,379,821
DROP TABLE procedures_new;

###################### Load procedures table from output 8 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM procedures; -- 4,379,821
SELECT COUNT(*) FROM procedures_new; -- 621,487

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM procedures_new; -- 621,487
SELECT COUNT(*) FROM procedures; -- 5,001,308
DROP TABLE procedures_new;

###################### Load procedures table from output 9 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM procedures; -- 5,001,308

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM procedures_new; -- 627,446
SELECT COUNT(*) FROM procedures; -- 5,628,754
DROP TABLE procedures_new;

###################### Load procedures table from output 10 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM procedures; -- 5,628,754
SELECT COUNT(*) FROM procedures_new; -- 627,897

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM procedures_new; -- 627,897
SELECT COUNT(*) FROM procedures; -- 6,256,651
DROP TABLE procedures_new;


###################### Load procedures table from output 11 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM procedures; -- 6,256,651
SELECT COUNT(*) FROM procedures_new; -- 621,228

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM procedures_new; -- 621,228
SELECT COUNT(*) FROM procedures; -- 6,877,879
DROP TABLE procedures_new;

###################### Load procedures table from output 12 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM procedures; -- 6,877,879
SELECT COUNT(*) FROM procedures_new; -- 624,139

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM procedures_new; -- 624,139
SELECT COUNT(*) FROM procedures; -- 7,502,018
DROP TABLE procedures_new;