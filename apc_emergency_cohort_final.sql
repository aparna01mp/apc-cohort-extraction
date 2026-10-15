-- =====================================================================
-- Project: Emergency admittances to hospital
-- Source:  Artificial HES APC sample (table apc_raw, loaded via Python)
-- Cohort:  Adults (>18) with an emergency admission (ADMIMETH = 21)
--          Optional: admitted 01/04/2020 - 31/03/2021
-- Assumptions:
--   * "Over 18" is interpreted as STARTAGE > 18 (i.e. 19 and over).
--     Using >= 18 would include 18-year-olds and change the counts.
--   * STARTAGE 7001-7007 are special HES codes for infants (under 1 year),
--     not real ages; they are excluded by the upper bound of 120.
--   * Dates 1800-01-01 / 1801-01-01 are placeholder values, not real
--     admissions; they fall outside any valid study window.
--   * Each row is a hospital episode, so records != patients.
--     Patients are counted with COUNT(DISTINCT PSEUDO_HESID).
-- =====================================================================


-- ---------------------------------------------------------------------
-- A. INITIAL INSPECTION
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT PSEUDO_HESID) AS total_patients
FROM apc_raw;

-- ---------------------------------------------------------------------
-- B. DATA QUALITY CHECKS (fields used by the cohort definition)
-- ---------------------------------------------------------------------

-- B1. Missing values
SELECT
    SUM(CASE WHEN PSEUDO_HESID IS NULL OR PSEUDO_HESID = '' THEN 1 ELSE 0 END) AS missing_patient_id,
    SUM(CASE WHEN STARTAGE     IS NULL OR STARTAGE     = '' THEN 1 ELSE 0 END) AS missing_start_age,
    SUM(CASE WHEN ADMIMETH     IS NULL OR ADMIMETH     = '' THEN 1 ELSE 0 END) AS missing_admission_method,
    SUM(CASE WHEN ADMIDATE     IS NULL OR ADMIDATE     = '' THEN 1 ELSE 0 END) AS missing_admission_date
FROM apc_raw;
-- Records with missing STARTAGE cannot be confirmed as adults. They are
-- excluded automatically because CAST(NULL/'' AS INTEGER) is NULL/0,
-- which fails the "> 18" test.

-- B2. STARTAGE range and special codes
SELECT MIN(CAST(STARTAGE AS INTEGER)) AS min_age,
       MAX(CAST(STARTAGE AS INTEGER)) AS max_age
FROM apc_raw
WHERE STARTAGE IS NOT NULL AND STARTAGE <> '';

SELECT CAST(STARTAGE AS INTEGER) AS startage_code,
       COUNT(*) AS number_of_records
FROM apc_raw
WHERE CAST(STARTAGE AS INTEGER) BETWEEN 7001 AND 7007
GROUP BY CAST(STARTAGE AS INTEGER)
ORDER BY startage_code;
-- Special codes appear as both '7001' and '7001.0' text, so values are
-- cast to INTEGER before filtering.

-- B3. ADMIMETH values (check for formatting issues such as '21.0')
SELECT ADMIMETH, TYPEOF(ADMIMETH) AS stored_type, COUNT(*) AS number_of_records
FROM apc_raw
GROUP BY ADMIMETH, TYPEOF(ADMIMETH)
ORDER BY number_of_records DESC;
-- If any '21.0' (or similar) appears, the CAST in section C handles it.

-- B4. ADMIDATE format and range
SELECT LENGTH(ADMIDATE) AS date_length, COUNT(*) AS number_of_records
FROM apc_raw
GROUP BY LENGTH(ADMIDATE);
-- Expect only length 10 (YYYY-MM-DD). Anything else needs investigation.

SELECT MIN(ADMIDATE) AS earliest, MAX(ADMIDATE) AS latest
FROM apc_raw;

SELECT ADMIDATE, COUNT(*) AS number_of_records
FROM apc_raw
WHERE ADMIDATE < '1900-01-01'
GROUP BY ADMIDATE
ORDER BY number_of_records DESC;
-- Placeholder dates (1800-01-01, 1801-01-01) are not valid admission dates.


-- ---------------------------------------------------------------------
-- C. BUILD THE EXTRACT
--    Only the approved data fields are selected (data minimisation).
-- ---------------------------------------------------------------------

-- C1. Mandatory cohort: adult emergency admissions
DROP TABLE IF EXISTS apc_emergency_cohort;

CREATE TABLE apc_emergency_cohort AS
SELECT PSEUDO_HESID,
       STARTAGE,
       ADMIMETH,
       ADMIDATE
FROM apc_raw
WHERE CAST(STARTAGE AS INTEGER) BETWEEN 19 AND 120   -- over 18; excludes 7001-7007
  AND CAST(ADMIMETH AS INTEGER) = 21;                -- emergency admission

-- C2. Optional cohort: admitted between 01/04/2020 and 31/03/2021
DROP TABLE IF EXISTS apc_emergency_cohort_2020_21;

CREATE TABLE apc_emergency_cohort_2020_21 AS
SELECT *
FROM apc_emergency_cohort
WHERE ADMIDATE >= '2020-04-01'
  AND ADMIDATE <  '2021-04-01';   -- safe even if a time part is present


-- ---------------------------------------------------------------------
-- D. RESULTS AND VALIDATION
-- ---------------------------------------------------------------------

-- D1. Cohort counts (the figures requested by the task)
SELECT 'Mandatory cohort' AS cohort,
       COUNT(*) AS admission_records,
       COUNT(DISTINCT PSEUDO_HESID) AS unique_patients
FROM apc_emergency_cohort
UNION ALL
SELECT 'Optional cohort (2020/21)',
       COUNT(*),
       COUNT(DISTINCT PSEUDO_HESID)
FROM apc_emergency_cohort_2020_21;

-- D2. Validation: ranges inside the final cohorts
SELECT MIN(CAST(STARTAGE AS INTEGER)) AS min_age,
       MAX(CAST(STARTAGE AS INTEGER)) AS max_age,
       MIN(CAST(ADMIMETH AS INTEGER)) AS min_method,
       MAX(CAST(ADMIMETH AS INTEGER)) AS max_method
FROM apc_emergency_cohort;

SELECT MIN(ADMIDATE) AS earliest, MAX(ADMIDATE) AS latest
FROM apc_emergency_cohort_2020_21;

-- D3. Funnel: how many records/patients remain after each criterion
SELECT '1. All records' AS step,
       COUNT(*) AS records,
       COUNT(DISTINCT PSEUDO_HESID) AS patients
FROM apc_raw
UNION ALL
SELECT '2. Adult (age 19-120)',
       COUNT(*), COUNT(DISTINCT PSEUDO_HESID)
FROM apc_raw
WHERE CAST(STARTAGE AS INTEGER) BETWEEN 19 AND 120
UNION ALL
SELECT '3. + Emergency (ADMIMETH 21)',
       COUNT(*), COUNT(DISTINCT PSEUDO_HESID)
FROM apc_emergency_cohort
UNION ALL
SELECT '4. + Admitted 2020/21 (optional)',
       COUNT(*), COUNT(DISTINCT PSEUDO_HESID)
FROM apc_emergency_cohort_2020_21;
