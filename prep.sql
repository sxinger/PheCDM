/* This script is to collect a cohort-specific cut of core 
   CDM tables needed by other computational phenotyping scripts.
*/

/* setup environment*/
use role "ANALYTICS";
use warehouse ANALYTICS_WH;
use database ANALYTICSDB;
use schema VCCC_SCHEMA;

/*delcaration for external schema and table*/
set cdm_db_schema = 'PCORNET_CDM.CDM_C010R021';
set PCORNET_TRIAL = CONCAT($cdm_db_schema,'.PCORNET_TRIAL');
set ENCOUNTER = CONCAT($cdm_db_schema,'.ENCOUNTER');
set DEMOGRAPHIC = CONCAT($cdm_db_schema,'.DEMOGRAPHIC');
set VITAL = CONCAT($cdm_db_schema,'.VITAL');
set LAB_RESULT_CM = CONCAT($cdm_db_schema,'.LAB_RESULT_CM');
set DIAGNOSIS = CONCAT($cdm_db_schema,'.DIAGNOSIS');
set PRESCRIBING = CONCAT($cdm_db_schema,'.PRESCRIBING');
set trial_id = 'VCCC';
set start_date = '2020-08-01';
set end_date = '2020-10-31';
set age_lower = 18;
show variables;

/*eligible patients*/
create or replace table pat_incld as
select distinct PATID
      ,TRIAL_ENROLL_DATE as INDEX_DATE
from identifier($PCORNET_TRIAL) 
where TRIALID = identifier($trial_id)
-- limit 200
;

/*eligible encounter
 - reliable encounter type: AV, ED, EI, IP, OS, IS
 - age ate encounter >= 18
*/

create or replace table enc_incld as
with encs_with_age_at_visit as (
   select e.PATID
         ,e.ENCOUNTERID
         ,d.BIRTH_DATE
         ,e.ADMIT_DATE
         ,e.DISCHARGE_DATE
         ,e.ENC_TYPE
         ,year(e.ADMIT_DATE::date) - year(d.BIRTH_DATE::date) as AGE_AT_VIS
   from identifier($ENCOUNTER) e
   join identifier($DEMOGRAPHIC) d 
   on e.PATID = d.PATID and
      exists (select 1 from pat_incld p where e.PATID = p.PATID)
)
   ,summarized_encounters AS (
   SELECT PATID
         ,ENCOUNTERID
         ,BIRTH_DATE
         ,ADMIT_DATE
         ,DISCHARGE_DATE
         ,ENC_TYPE
         ,AGE_AT_VIS
         ,count(DISTINCT ADMIT_DATE::date) OVER (PARTITION BY PATID) AS cnt_distinct_enc_days
   FROM encs_with_age_at_visit
   WHERE AGE_AT_VIS >= $age_lower
   AND   ENC_TYPE in ( 'IP'
                      ,'ED'
                      ,'EI'
                      ,'IS'
                      ,'OS'
                      ,'AV') 
)
SELECT PATID
      ,ENCOUNTERID
      ,BIRTH_DATE
      ,ADMIT_DATE
      ,DISCHARGE_DATE
      ,ENC_TYPE
      ,AGE_AT_VIS
FROM summarized_encounters
WHERE cnt_distinct_enc_days >= 2
;

/*
create or replace table pat_excld as
;
*/

create or replace table pat_elig as
select pat.PATID
      ,pat.INDEX_DATE
from pat_incld pat
where exists (select 1 from enc_incld enc 
              where pat.PATID = enc.PATID)
;

/*
create or replace table enc_excld AS
;

create or replace table enc_elig AS
;
*/

create or replace table DEMOGRAPHIC as
select pat.PATID
      ,d.BIRTH_DATE
      ,d.SEX
      ,d.RACE
      ,d.HISPANIC
      ,d.PAT_PREF_LANGUAGE_SPOKEN 
from pat_elig pat
join identifier($DEMOGRAPHIC) d
on pat.PATID = d.PATID
;

create or replace table VITAL as
select pat.PATID
      ,v.ENCOUNTERID
      ,v.MEASURE_DATE
      ,v.MEASURE_TIME
      ,v.VITAL_SOURCE
      ,v.HT
      ,v.WT
      ,v.DIASTOLIC
      ,v.SYSTOLIC
      ,v.ORIGINAL_BMI
      ,v.BP_POSITION
      ,v.SMOKING
      ,v.TOBACCO
      ,v.TOBACCO_TYPE
from pat_elig pat
join identifier($VITAL) v
on pat.PATID = v.PATID 
;

create or replace table LAB_RESULT_CM as
select enc.PATID
      ,l.ENCOUNTERID
      ,l.LAB_LOINC
      ,l.LAB_RESULT_SOURCE
      ,l.LAB_LOINC_SOURCE
      ,l.PRIORITY
      ,l.RESULT_LOC
      ,l.LAB_PX
      ,l.LAB_PX_TYPE
      ,l.LAB_ORDER_DATE
      ,l.SPECIMEN_DATE
      ,l.SPECIMEN_TIME
      ,l.RESULT_DATE
      ,l.RESULT_TIME
      ,l.RESULT_QUAL
      ,l.RESULT_SNOMED
      ,l.RESULT_NUM
      ,l.RESULT_UNIT
      ,l.NORM_RANGE_LOW
      ,l.NORM_MODIFIER_LOW
      ,l.NORM_RANGE_HIGH
      ,l.NORM_MODIFIER_HIGH
      ,l.ABN_IND
      ,l.RAW_LAB_NAME
      ,l.RAW_LAB_CODE
      ,l.RAW_PANEL
      ,l.RAW_RESULT
      ,l.RAW_UNIT
      ,l.RAW_ORDER_DEPT
      ,l.RAW_FACILITY_CODE 
from enc_incld enc
join identifier($LAB_RESULT_CM) l
on enc.PATID = l.PATID and 
   enc.ENCOUNTERID = l.ENCOUNTERID
;


create or replace table DIAGNOSIS as
select enc.PATID
      ,d.ENCOUNTERID
      ,d.ENC_TYPE
      ,d.ADMIT_DATE
      ,d.DX
      ,d.DX_TYPE
      ,d.DX_DATE
      ,d.DX_SOURCE
      ,d.DX_ORIGIN
      ,d.PDX
      ,d.DX_POA
from enc_incld enc
join identifier($DIAGNOSIS) d
on enc.PATID = d.PATID and 
   enc.ENCOUNTERID = d.ENCOUNTERID
;


create or replace table PRESCRIBING as
select enc.PATID
      ,p.ENCOUNTERID
      ,p.RX_ORDER_DATE
      ,p.RX_ORDER_TIME
      ,p.RX_START_DATE
      ,p.RX_END_DATE
      ,p.RX_DOSE_ORDERED
      ,p.RX_DOSE_ORDERED_UNIT
      ,p.RX_QUANTITY 
      ,p.RX_DOSE_FORM 
      ,p.RX_REFILLS 
      ,p.RX_DAYS_SUPPLY
      ,p.RX_FREQUENCY
      ,p.RX_PRN_FLAG 
      ,p.RX_ROUTE
      ,p.RX_BASIS
      ,p.RXNORM_CUI
      ,p.RX_SOURCE 
      ,p.RX_DISPENSE_AS_WRITTEN
      ,p.RAW_RX_MED_NAME
      ,p.RAW_RXNORM_CUI 
      ,p.RAW_RX_NDC
from enc_incld enc
join identifier($PRESCRIBING) p
on enc.PATID = p.PATID and 
   enc.ENCOUNTERID = p.ENCOUNTERID
;
