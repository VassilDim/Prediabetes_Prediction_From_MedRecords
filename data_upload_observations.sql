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

	ALTER TABLE observations_new
	CHANGE PATIENT patient_id VARCHAR(50),
	CHANGE ENCOUNTER encounter_observations VARCHAR(50),
	CHANGE CODE encounter_code_observations VARCHAR(20),
	CHANGE DESCRIPTION description_observations VARCHAR(200),
	CHANGE `VALUE` value_observations FLOAT,
	CHANGE `UNITS` units_observations VARCHAR(200);

END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- Remove rows that do not conform to column criteria
DROP PROCEDURE IF EXISTS delete_rows;
DELIMITER //
CREATE PROCEDURE delete_rows()
BEGIN    

	DELETE FROM observations_new -- appropriate patient ID
	WHERE PATIENT NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
	LIMIT 6200000;
	DELETE FROM observations_new -- appropriate careplan ID
	WHERE ENCOUNTER NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
	LIMIT 6200000;
	DELETE FROM observations_new -- appropriate CODE for encounter
	WHERE CODE NOT REGEXP '^[1-9][0-9]*-[0-9]*$'
	LIMIT 6200000;
	DELETE FROM observations_new -- appropriate start date
	WHERE DATE NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
	LIMIT 6200000;
	DELETE FROM observations_new -- appropriate stop death
	WHERE VALUE NOT REGEXP '^[0-9]*$'
	LIMIT 6200000;

END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Extract only first occurance of BRITHDATE
DROP PROCEDURE IF EXISTS date_first;
DELIMITER //
CREATE PROCEDURE date_first()
BEGIN
	UPDATE observations_new
	SET `DATE` = SUBSTRING(`DATE`, 1, 10)
	WHERE `DATE` IS NOT NULL AND `DATE` REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
	LIMIT 6200000;
END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Convert date to type DATE, add to new columns and delete old ones
DROP PROCEDURE IF EXISTS text2date;
DELIMITER //
CREATE PROCEDURE text2date()
BEGIN
		
	ALTER TABLE observations_new
	ADD COLUMN date_observations DATE;
	-- Update the values for start date
	UPDATE observations_new
	SET date_observations = CASE
		WHEN `DATE` = '' THEN NULL
		ELSE STR_TO_DATE(`DATE`, '%Y-%m-%d')
		END
	LIMIT 6200000;
	-- Remove DATE column
	ALTER TABLE observations_new
	DROP COLUMN `DATE`;

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
	INSERT INTO observations
	SELECT *
	FROM observations_new;
END //
DELIMITER ;


####################################################################
## LOAD TABLES AND CONSOLIDATE INTO A SINGLE TABLE OBASERVATIONS  ##
####################################################################

###################### Load observations table from output 1 ###################

-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM observations; -- 1,048,575
-- Remove rows that do not conform to column criteria
DELETE FROM observations -- appropriate patient ID
WHERE PATIENT NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
LIMIT 1200000;
DELETE FROM observations -- appropriate careplan ID
WHERE ENCOUNTER NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
LIMIT 1200000;
DELETE FROM observations -- appropriate CODE for encounter
WHERE CODE NOT REGEXP '^[1-9][0-9]*-[0-9]*$'
LIMIT 1200000;
DELETE FROM observations -- appropriate start date
WHERE DATE NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
LIMIT 1200000;
DELETE FROM observations -- appropriate stop death
WHERE VALUE NOT REGEXP '^[0-9]*$'
LIMIT 1200000;

SELECT COUNT(*) FROM observations; -- 586,142

-- Keep only first for date
UPDATE observations
SET `DATE` = SUBSTRING(`DATE`, 1, 10)
WHERE `DATE` IS NOT NULL AND `DATE` REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
LIMIT 1200000;

-- Convert text to date:
-- add a new column of type DATE to hold the date of birth
ALTER TABLE observations
ADD COLUMN date_observations DATE;
-- Update the values for start date
UPDATE observations
SET date_observations = CASE
	WHEN `DATE` = '' THEN NULL
	ELSE STR_TO_DATE(`DATE`, '%Y-%m-%d')
	END
LIMIT 1200000;
-- Remove DATE column
ALTER TABLE observations
DROP COLUMN `DATE`;

-- Change column types to reduce overall size:
ALTER TABLE observations
CHANGE PATIENT patient_id VARCHAR(50),
CHANGE ENCOUNTER encounter_observations VARCHAR(50),
CHANGE CODE encounter_code_observations VARCHAR(20),
CHANGE DESCRIPTION description_observations VARCHAR(200),
CHANGE `VALUE` value_observations VARCHAR(20),
CHANGE `UNITS` units_observations VARCHAR(200);

SELECT * FROM observations LIMIT 4;
SELECT COUNT(*) FROM observations; -- 586,142

###################### Load observations table from output 2 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM observations_new; -- 5,392,026
SELECT COUNT(*) FROM observations; -- 586,142
-- Fix dates keeping only first occurrence
CALL date_first();
-- Delete entries with bad/inappropriate entries corresponding to each column
CALL delete_rows();
-- Transform dates from text to date format
CALL text2date();
-- Modify column data type and names:
CALL modify_table_types();
-- Merge to patients table and delete new
SELECT COUNT(*) FROM observations; -- 586,142
SELECT COUNT(*) FROM observations_new; -- 798,986
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