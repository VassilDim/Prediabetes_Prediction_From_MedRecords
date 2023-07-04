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

	ALTER TABLE immunizations_new
	CHANGE PATIENT patient_id VARCHAR(50),
	CHANGE ENCOUNTER encounter_immunization VARCHAR(50),
	CHANGE CODE encounter_code_immunization VARCHAR(20),
	CHANGE DESCRIPTION description_immunization VARCHAR(200);

END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- Remove rows that do not conform to column criteria
DROP PROCEDURE IF EXISTS delete_rows;
DELIMITER //
CREATE PROCEDURE delete_rows()
BEGIN    

	DELETE FROM immunizations_new -- appropriate patient ID
	WHERE PATIENT NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
	LIMIT 1000000;
	DELETE FROM immunizations_new -- appropriate encounter ID
	WHERE ENCOUNTER NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
	LIMIT 1000000;
	DELETE FROM immunizations_new -- appropriate CODE for encounter
	WHERE CODE NOT REGEXP '^[1-9][0-9]*$'
	LIMIT 1000000;
	DELETE FROM immunizations_new -- appropriate start date
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
	UPDATE immunizations_new
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
		
	ALTER TABLE immunizations_new
	ADD COLUMN date_immunization DATE;
	-- Update the values for start date
	UPDATE immunizations_new
	SET date_immunization = CASE
		WHEN DATE = '' THEN NULL
		ELSE STR_TO_DATE(DATE, '%Y-%m-%d')
		END
	LIMIT 1000000;
	-- Remove DATE column
	ALTER TABLE immunizations_new
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
	INSERT INTO immunizations
	SELECT *
	FROM immunizations_new;
END //
DELIMITER ;


####################################################################
## LOAD TABLES AND CONSOLIDATE INTO A SINGLE TABLE IMMUNIZATIONS  ##
####################################################################

###################### Load immunizations table from output 1 ###################

-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM immunizations; -- 873,133
-- Remove rows that do not conform to column criteria
DELETE FROM immunizations -- appropriate patient ID
WHERE PATIENT NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
LIMIT 1000000;
DELETE FROM immunizations -- appropriate encounter ID
WHERE ENCOUNTER NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
LIMIT 1000000;
DELETE FROM immunizations -- appropriate CODE for encounter
WHERE CODE NOT REGEXP '^[1-9][0-9]*$'
LIMIT 1000000;
DELETE FROM immunizations -- appropriate start date
WHERE DATE NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
LIMIT 1000000;


-- Keep only first for Start and Stop date
UPDATE immunizations
SET DATE = SUBSTRING(DATE, 1, 10)
WHERE DATE IS NOT NULL AND DATE REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
LIMIT 1000000;

-- Convert text to date:
-- add a new column of type DATE to hold the date of birth
ALTER TABLE immunizations
ADD COLUMN date_immunization DATE;
-- Update the values for start date
UPDATE immunizations
SET date_immunization = CASE
	WHEN DATE = '' THEN NULL
	ELSE STR_TO_DATE(DATE, '%Y-%m-%d')
	END
LIMIT 1000000;
-- Remove DATE column
ALTER TABLE immunizations
DROP COLUMN DATE;


-- Change column types to reduce overall size:
ALTER TABLE immunizations
CHANGE PATIENT patient_id VARCHAR(50),
CHANGE ENCOUNTER encounter_immunization VARCHAR(50),
CHANGE CODE encounter_code_immunization VARCHAR(20),
CHANGE DESCRIPTION description_immunization VARCHAR(200);

SELECT * FROM immunizations LIMIT 4;
SELECT COUNT(*) FROM immunizations; -- 831,410

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
SELECT COUNT(*) FROM immunizations; -- 831,410
SELECT COUNT(*) FROM immunizations_new; -- 826,314
INSERT INTO immunizations
SELECT *
FROM immunizations_new;
SELECT COUNT(*) FROM immunizations; -- 1,657,724
DROP TABLE immunizations_new;

###################### Load immunizations table from output 3 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM immunizations; -- 1,657,724
SELECT COUNT(*) FROM immunizations_new; -- 825,910

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM immunizations; -- 2,483,634
DROP TABLE immunizations_new;

###################### Load immunizations table from output 4 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM immunizations; -- 2,483,634
SELECT COUNT(*) FROM immunizations_new; -- 828,079

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM immunizations; -- 3,311,713
DROP TABLE immunizations_new;

###################### Load immunizations table from output 5 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types

-- Clean and merge:
CALL clean_mergeNdrop(); 	

SELECT COUNT(*) FROM immunizations_new; -- 826,435
SELECT COUNT(*) FROM immunizations; -- 4,138,058
DROP TABLE immunizations_new;

###################### Load immunizations table from output 6 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM immunizations_new; -- 866,427

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM immunizations_new; -- 826,074
SELECT COUNT(*) FROM immunizations; -- 4,964,132
DROP TABLE immunizations_new;

###################### Load immunizations table from output 7 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM immunizations_new; -- 

-- Clean and merge:
CALL clean_mergeNdrop();
SELECT COUNT(*) FROM immunizations_new; -- 827,208
SELECT COUNT(*) FROM immunizations; -- 5,791,340
DROP TABLE immunizations_new;

###################### Load immunizations table from output 8 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM immunizations; -- 5,791,340
SELECT COUNT(*) FROM immunizations_new; -- 866,436

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM immunizations_new; -- 825,719
SELECT COUNT(*) FROM immunizations; -- 6,617,059
DROP TABLE immunizations_new;

###################### Load immunizations table from output 9 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM immunizations; -- 6,617,059

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM immunizations_new; -- 825,882
SELECT COUNT(*) FROM immunizations; -- 7,442,941
DROP TABLE careplans_new;

###################### Load immunizations table from output 10 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM immunizations; -- 7,442,941
SELECT COUNT(*) FROM immunizations_new; -- 869,142

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM immunizations_new; -- 828,424
SELECT COUNT(*) FROM immunizations; -- 8,271,365
DROP TABLE immunizations_new;


###################### Load immunizations table from output 11 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM immunizations; -- 8,271,365
SELECT COUNT(*) FROM immunizations_new; -- 867,476

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM immunizations_new; -- 826,767
SELECT COUNT(*) FROM immunizations; -- 9,098,132
DROP TABLE immunizations_new;

###################### Load immunizations table from output 12 ###################
-- Load data
-- Use Table Import wizard and use TEXT or INT as default data types
SELECT COUNT(*) FROM immunizations; -- 9,098,132
SELECT COUNT(*) FROM immunizations_new; -- 865,163

-- Clean and merge:
CALL clean_mergeNdrop();

SELECT COUNT(*) FROM immunizations_new; -- 824,602
SELECT COUNT(*) FROM immunizations; -- 9,922,734
DROP TABLE immunizations_new;