/********************************************************************
This script is to identify pregnancy-related events. Pregnancy events 
are identified by ICD diagnosis codes and ICD/CPT procedure codes.

For efficiency, it is recommended to perform computational 
phenotyping on a smaller cut of CDM tables relevant to the eligible 
patient and/or encounts cohort. The study-specific CDM tables are 
usually saved in a separate Study_Schema with CDM relational database 
structure preserved.
********************************************************************/
/* setup environment*/
use role "ANALYTICS";
use warehouse ANALYTICS_WH;
use database ANALYTICSDB;
use schema VCCC_SCHEMA;


CREATE TABLE NextD_pregnancy_event_dates AS
WITH preg_related_dx AS (
   SELECT dia.PATID      AS PATID
         ,dia.ADMIT_DATE AS ADMIT_DATE
   FROM "&&PCORNET_CDM".DIAGNOSIS dia
   JOIN "&&PCORNET_CDM".DEMOGRAPHIC d ON dia.PATID = d.PATID
   WHERE
      -- miscarriage, abortion, pregnancy, birth and pregnancy related complications diagnosis codes diagnosis codes:
      (
        -- ICD9 codes
        (
          (   regexp_like(dia.DX,'^63[0-9]\.')
           or regexp_like(dia.DX,'^6[4-7][0-9]\.')
           or regexp_like(dia.DX,'^V2[2-3]\.')
           or regexp_like(dia.DX,'^V28\.')
          )
          AND dia.DX_TYPE = '09'
        )
        OR
        -- ICD10 codes
        (
          (   regexp_like(dia.DX,'^O')
           or regexp_like(dia.DX,'^A34\.')
           or regexp_like(dia.DX,'^Z3[34]\.')
           or regexp_like(dia.DX,'^Z36')
          )
          and dia.DX_TYPE = '10'
        )
      )
      -- age restriction
      AND
      (
        ((dia.ADMIT_DATE - d.BIRTH_DATE) / 365.25 ) BETWEEN 18 AND 89
      )
      -- time frame restriction
      AND dia.ADMIT_DATE BETWEEN DATE '2010-01-01' AND CURRENT_DATE
      -- eligible patients
      AND
      (
        EXISTS (SELECT 1 FROM NextD_first_visit v WHERE dia.PATID = v.PATID)
      )
), delivery_proc AS (
   SELECT  p.PATID       AS PATID
          ,p.ADMIT_DATE  AS ADMIT_DATE
    FROM "&&PCORNET_CDM".PROCEDURES  p
    JOIN "&&PCORNET_CDM".DEMOGRAPHIC d ON p.PATID = d.PATID
    WHERE
      -- Procedure codes
      (
          -- ICD9 codes
          (
            regexp_like(p.PX,'^7[2-5]\.')
            and p.PX_TYPE = '09'
          )
          OR
          -- ICD10 codes
          (
            regexp_like(p.PX,'^10')
            and p.PX_TYPE = '10'
          )
          OR
          -- CPT codes
          (
            regexp_like(p.PX,'^59[0-9][0-9][0-9]')
            and p.PX_TYPE='CH'
          )
      )
      -- age restriction
      AND
      (
        ((p.ADMIT_DATE - d.BIRTH_DATE) / 365.25 ) BETWEEN 18 AND 89
      )
      -- time frame restriction
      AND p.ADMIT_DATE BETWEEN DATE '2010-01-01' AND CURRENT_DATE
      -- eligible patients
      AND
      (
        EXISTS (SELECT 1 FROM NextD_first_visit v WHERE p.PATID = v.PATID)
      )
)
SELECT PATID, ADMIT_DATE
FROM preg_related_dx
UNION
SELECT PATID, ADMIT_DATE
FROM delivery_proc
;

-- Find separate pregnancy events (separated by >= 12 months from prior event)
CREATE TABLE NextD_distinct_preg_events AS
WITH delta_pregnancies AS (
    SELECT PATID
          ,ADMIT_DATE
          ,round(months_between( ADMIT_DATE
                               , Lag(ADMIT_DATE, 1, NULL) OVER (PARTITION BY PATID ORDER BY ADMIT_DATE)
                               )) AS months_delta
    FROM NextD_pregnancy_event_dates
)
SELECT PATID
      ,ADMIT_DATE
      ,row_number() OVER (PARTITION BY PATID ORDER BY ADMIT_DATE) rn
FROM delta_pregnancies
WHERE months_delta IS NULL OR months_delta >= 12;

-- Transponse pregnancy table into single row per patient
CREATE TABLE NextD_FinalPregnancy AS
  SELECT *
  FROM
    (
     SELECT PATID, ADMIT_DATE, rn
     FROM NextD_distinct_preg_events
    )
    PIVOT (max(ADMIT_DATE) for (rn) in (1,2,3,4,5,6,7,8,9,10))
    ORDER BY PATID
;