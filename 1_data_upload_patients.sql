-- Set global environment to process large files
-- Server restart required
SET GLOBAL max_allowed_packet = 30800949;
SET GLOBAL max_execution_time = 600;
SET GLOBAL wait_timeout = 3600;

-- CREATE DATABASE prediabetes;
CREATE DATABASE IF NOT EXISTS prediabetes;

-- Select database as default:
USE prediabetes;


-- DROP TABLE patients;

##############################
########## Patients ##########
##############################

-- Load the first patient table (output_1) using wizard
-- note that all fields are texts => change to reduce size

-- Change column names:
ALTER TABLE patients
CHANGE ID patient_id VARCHAR(100),
CHANGE BIRTHDATE birthdate TEXT,
CHANGE DEATHDATE deathdate TEXT,
CHANGE SSN ssn VARCHAR(50),
CHANGE DRIVERS drivers VARCHAR(25),
CHANGE PASSPORT passport VARCHAR(25),
CHANGE PREFIX prefix VARCHAR(7),
CHANGE FIRST first_name VARCHAR(20),
CHANGE LAST last_name VARCHAR(30),
CHANGE SUFFIX suffix VARCHAR(10),
CHANGE MAIDEN maiden VARCHAR(30),
CHANGE MARITAL marital VARCHAR(3),
CHANGE RACE race VARCHAR (30),
CHANGE ETHNICITY ethnicity VARCHAR(30),
CHANGE GENDER gender VARCHAR(3),
CHANGE BIRTHPLACE birthplace VARCHAR(50),
CHANGE ADDRESS address VARCHAR(100);

-- trim preceding and trailing spaces:
UPDATE patients
SET patient_id = TRIM(patient_id),
    birthdate = TRIM(birthdate),
    deathdate = TRIM(deathdate),
    ssn = TRIM(ssn),
    drivers = TRIM(drivers),
    passport = TRIM(passport),
    prefix = TRIM(prefix),
    first_name = TRIM(first_name),
    last_name = TRIM(last_name),
    suffix = TRIM(suffix),
    maiden = TRIM(maiden),
    marital = TRIM(marital),
    race = TRIM(race),
    ethnicity = TRIM(ethnicity),
    gender = TRIM(gender),
    birthplace = TRIM(birthplace),
    address = TRIM(address)
LIMIT 135000;

-- Keep only the (first) date portion from BIRTHDATE (still in text)
UPDATE patients
SET birthdate = SUBSTRING(birthdate, 1, 10)
WHERE birthdate IS NOT NULL AND birthdate REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
LIMIT 135000;

-- Keep only the (first) date portion from deathdate (still in text)
UPDATE patients
SET deathdate = SUBSTRING(deathdate, 1, 10)
WHERE deathdate IS NOT NULL AND deathdate REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
LIMIT 133000;

-- Delete all rows that have deathdate in the wrong format
DELETE FROM patients
WHERE deathdate NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}' AND deathdate != ''
LIMIT 135000;

-- Check for columns that have more than 10 characters (date length)
SELECT birthdate FROM patients
WHERE LENGTH(birthdate) > 10; -- no such entries

-- add a new column of type DATE to hold the date of birth
ALTER TABLE patients
ADD COLUMN date_of_birth DATE;

-- Update the values for date_of_birth
UPDATE patients
SET date_of_birth = CASE
	WHEN birthdate = '' THEN NULL
    ELSE STR_TO_DATE(birthdate, '%Y-%m-%d')
END
LIMIT 135000;
-- Remove birthdate column
ALTER TABLE patients
DROP COLUMN birthdate;

-- add a new column of type DATE to hold the date of death
ALTER TABLE patients
ADD COLUMN date_of_death DATE;

-- Update the values for date_of_birth
UPDATE patients
SET date_of_death = CASE
	WHEN deathdate = '' THEN NULL
    ELSE STR_TO_DATE(deathdate, '%Y-%m-%d')
END
LIMIT 135000;

-- Remove birthdate column
ALTER TABLE patients
DROP COLUMN deathdate;

-- Set patient_id as a primary key
ALTER TABLE patients
ADD PRIMARY KEY (patient_id);


########################################################
#### 			PROCEDURES AND FUNCTIONS			####
########################################################

-- change data types:
DROP PROCEDURE modify_patients_table_types;
DELIMITER //
CREATE PROCEDURE modify_patients_table_types()
BEGIN
    ALTER TABLE patients_new
    CHANGE ID patient_id VARCHAR(100),
    CHANGE BIRTHDATE birthdate TEXT,
    CHANGE DEATHDATE deathdate TEXT,
    CHANGE SSN ssn VARCHAR(100),
    CHANGE DRIVERS drivers VARCHAR(100),
    CHANGE PASSPORT passport VARCHAR(100),
    CHANGE PREFIX prefix VARCHAR(100),
    CHANGE FIRST first_name VARCHAR(100),
    CHANGE LAST last_name VARCHAR(100),
    CHANGE SUFFIX suffix VARCHAR(100),
    CHANGE MAIDEN maiden VARCHAR(100),
    CHANGE MARITAL marital VARCHAR(100),
    CHANGE RACE race VARCHAR(100),
    CHANGE ETHNICITY ethnicity VARCHAR(100),
    CHANGE GENDER gender VARCHAR(100),
    CHANGE BIRTHPLACE birthplace VARCHAR(100),
    CHANGE ADDRESS address VARCHAR(100);
END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

-- Remove rows that do not conform to column criteria
DROP PROCEDURE delete_rows;
DELIMITER //
CREATE PROCEDURE delete_rows()
BEGIN
    DELETE FROM patients_new -- appropriate patient ID
	WHERE ID NOT REGEXP '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
	LIMIT 135000;
    DELETE FROM patients_new -- appropriate SSN
	WHERE SSN NOT REGEXP '^[0-9]{3}-[0-9]{2}-[0-9]{4}$' AND SSN != ''
	LIMIT 135000;
    DELETE FROM patients_new -- appropriate date of birth
	WHERE BIRTHDATE NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND BIRTHDATE != ''
    LIMIT 135000;
    DELETE FROM patients_new -- appropriate date of death
	WHERE DEATHDATE NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' AND DEATHDATE != ''
    LIMIT 135000;
    DELETE FROM patients_new -- appropriate gender
	WHERE GENDER NOT IN ('M', 'F', '', ' ')
    LIMIT 135000;
    DELETE FROM patients_new -- appropriate race
	WHERE RACE NOT IN ('black', 'white', 'hispanic', 'asian', '', ' ')
    LIMIT 135000;        
END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Extract only first occurance of BRITHDATE
DELIMITER //
CREATE PROCEDURE date_first()
BEGIN
    UPDATE patients_new
	SET BIRTHDATE = SUBSTRING(BIRTHDATE, 1, 10)
	WHERE BIRTHDATE IS NOT NULL AND BIRTHDATE REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
	LIMIT 135000;
    UPDATE patients_new
	SET DEATHDATE = SUBSTRING(DEATHDATE, 1, 10)
	WHERE DEATHDATE IS NOT NULL AND DEATHDATE REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
	LIMIT 135000;
END //
DELIMITER ;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


-- Convert date to type DATE, add to new columns and delete old ones
DELIMITER //
CREATE PROCEDURE text2date()
BEGIN
	-- add a new column of type DATE to hold the date of birth
	ALTER TABLE patients_new
	ADD COLUMN date_of_birth DATE;

	-- Update the values for date_of_birth
	UPDATE patients_new
	SET date_of_birth = CASE
		WHEN birthdate = '' THEN NULL
		ELSE STR_TO_DATE(birthdate, '%Y-%m-%d')
	END
	LIMIT 135000;
	-- Remove birthdate column
	ALTER TABLE patients_new
	DROP COLUMN birthdate;

	-- add a new column of type DATE to hold the date of death
	ALTER TABLE patients_new
	ADD COLUMN date_of_death DATE;
	-- Update the values for date_of_birth
	UPDATE patients_new
		SET date_of_death = CASE
			WHEN deathdate = '' THEN NULL
			ELSE STR_TO_DATE(deathdate, '%Y-%m-%d')
		END
		LIMIT 135000;
	-- Remove birthdate column
	ALTER TABLE patients_new
	DROP COLUMN deathdate;
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
	CALL modify_patients_table_types();
	CALL text2date();
	INSERT INTO patients
	SELECT *
	FROM patients_new;
END //
DELIMITER ;


########################################################
########################################################

######## Load patient output 2 clean up and merge to patients ############
-- Load the next patient table using wizard
-- note that all fields are texts => change to reduce size

-- Fix dates keeping only first occurrence
CALL date_first();

-- Delete entries with bad/inappropriate entries corresponding to each column
CALL delete_rows();

-- Modify column data type and names:
CALL modify_patients_table_types();

-- Transform dates from text to date format
CALL text2date();

-- Merge to patients table and delete new
INSERT INTO patients
SELECT *
FROM patients_new;
DROP TABLE patients_new;

######## Load patient output 3 clean up and merge to patients ############
-- Load the next patient table using wizard
CALL date_first();
CALL date_first();
CALL delete_rows();
CALL modify_patients_table_types();
CALL text2date();
INSERT INTO patients
SELECT *
FROM patients_new;
DROP TABLE patients_new;


######## Load patient output 4 clean up and merge to patients ############
-- Load the next patient table using wizard
-- Clean, merge to patients and drop table
CALL clean_mergeNdrop();
-- check new table:
SELECT COUNT(*) FROM patients;
DROP TABLE patients_new; -- remove temporary table

######## Load patient output 5 clean up and merge to patients ############
-- Load the next patient table using wizard
-- Clean, merge to patients and drop table
CALL clean_mergeNdrop();
-- check new table:
SELECT COUNT(*) FROM patients; -- count total - 664126
DROP TABLE patients_new; -- remove temporary table

######## Load patient output 6 clean up and merge to patients ############
-- Load the next patient table using wizard
SELECT COUNT(*) FROM patients_new; -- 132825
-- Clean, merge to patients and drop table
CALL date_first();
CALL date_first();
CALL delete_rows();
CALL modify_patients_table_types();
CALL text2date();
INSERT INTO patients
SELECT * FROM patients_new;
SELECT COUNT(*) FROM patients; -- 796644
DROP TABLE patients_new; -- remove temporary table

######## Load patient output 7 clean up and merge to patients ############
-- Load the next patient table using wizard
SELECT COUNT(*) FROM patients_new; -- 132546
-- Clean, merge to patients and drop table
CALL date_first();
CALL date_first();
CALL delete_rows();
CALL modify_patients_table_types();
CALL text2date();
INSERT INTO patients
SELECT * FROM patients_new LIMIT 135000;
SELECT COUNT(*) FROM patients; -- 929033
DROP TABLE patients_new; -- remove temporary table

######## Load patient output 8 clean up and merge to patients ############
-- Load the next patient table using wizard
SELECT COUNT(*) FROM patients_new; -- 133070
-- Clean, merge to patients and drop table
CALL date_first();
CALL delete_rows();
CALL modify_patients_table_types();
CALL text2date();
INSERT INTO patients
SELECT * FROM patients_new LIMIT 135000;
SELECT COUNT(*) FROM patients; -- 1061766
DROP TABLE patients_new; -- remove temporary table

######## Load patient output 9 clean up and merge to patients ############
-- Load the next patient table using wizard
SELECT COUNT(*) FROM patients_new; -- 133224
-- Clean, merge to patients and drop table
CALL date_first();
CALL delete_rows();
CALL modify_patients_table_types();
CALL text2date();
SELECT COUNT(*) FROM patients; -- 1,061,766
INSERT INTO patients
SELECT * FROM patients_new LIMIT 134000;
SELECT COUNT(*) FROM patients; -- 1194674
SELECT COUNT(*) FROM patients_new; -- 132908
DROP TABLE patients_new; -- remove temporary table

######## Load patient output 10 clean up and merge to patients ############
-- Load the next patient table using wizard
SELECT COUNT(*) FROM patients_new; -- 132127
-- Clean, merge to patients and drop table
CALL date_first();
CALL delete_rows();
CALL modify_patients_table_types();
CALL text2date();
SELECT COUNT(*) FROM patients; -- 1,194,674
SELECT COUNT(*) FROM patients_new; -- 131770
INSERT INTO patients
SELECT * FROM patients_new LIMIT 132000;
SELECT COUNT(*) FROM patients; -- 1,326,444
DROP TABLE patients_new; -- remove temporary table

######## Load patient output 11 clean up and merge to patients ############
-- Load the next patient table using wizard
SELECT COUNT(*) FROM patients_new; -- 132569
-- Clean, merge to patients and drop table
CALL date_first();
CALL delete_rows();
CALL modify_patients_table_types();
CALL text2date();
SELECT COUNT(*) FROM patients; -- 1,326,444
SELECT COUNT(*) FROM patients_new; -- 132218
INSERT INTO patients
SELECT * FROM patients_new LIMIT 133000;
SELECT COUNT(*) FROM patients; -- 1,458,662
DROP TABLE patients_new; -- remove temporary table

######## Load patient output 12 clean up and merge to patients ############
-- Load the next patient table using wizard
SELECT COUNT(*) FROM patients_new; -- 133109
-- Clean, merge to patients and drop table
CALL date_first();
CALL delete_rows();
CALL modify_patients_table_types();
CALL text2date();
SELECT COUNT(*) FROM patients; -- 1,458,662
SELECT COUNT(*) FROM patients_new; -- 132761
INSERT INTO patients
SELECT * FROM patients_new LIMIT 133000;
SELECT COUNT(*) FROM patients; -- 1,591,423
DROP TABLE patients_new; -- remove temporary table

######## Check that the patient_id is unique ############
SELECT COUNT(DISTINCT patient_id) FROM patients; -- 1,591,423
SELECT COUNT(patient_id) FROM patients; -- 1,591,423
-- So all patient_id's are unique


