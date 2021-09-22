/* This script is to collect a cohort-specific cut of core 
   CDM tables needed by other computational phenotyping scripts.
*/

/*eligible patients*/
create table pat_incld as
select distinct PATID
      ,TRIAL_ENROLL_DATE as INDEX_DATE
from &&PCORNET_CDM_SCHEMA.PCORNET_TRIAL
-- where TRIAL_ENROLL_DATE >= '&VCCC_Start_Date' -- we want the "Index_date" to be w.r.t. VCCC not other trials patient used to participate
-- where TRIALID = '&vccc_trial_id' -- comment it out as VCCC trialID may not be assigned to all participants
;

/*gather demographic information from CDM*/
create table DEMOGRAPHIC as
select pat.PATID
      ,d.BIRTH_DATE
      ,d.SEX
      ,d.RACE
      ,d.HISPANIC
      ,d.PAT_PREF_LANGUAGE_SPOKEN 
from pat_elig pat
join &&PCORNET_CDM_SCHEMA.DEMOGRAPHIC d
on pat.PATID = d.PATID
;

/*gather BP, HT, WT, BMI, and SMOKING information from CDM and Quardio*/
create table VITAL as
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
join &&PCORNET_CDM_SCHEMA.VITAL v
on pat.PATID = v.PATID 
union
-- stack BP information from Qardio
select q.PATID
      ,q.MEASURE_DATE
      ,q.MEASURE_TIME
      ,'' as VITAL_SOURCE
      ,NULL as HT
      ,NULL as WT
      ,q.SYS SYSTOLIC
      ,q.DIA DIASTOLIC
      ,NULL as ORIGINAL_BMI
      ,NULL as BP_POSITION
      ,NULL as SMOKING
      ,NULL as TOBACCO
      ,NULL as TOBACCO_TYPE
;

create table LAB_RESULT_CM as
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
join &&PCORNET_CDM_SCHEMA.LAB_RESULT_CM l
on enc.PATID = l.PATID and 
   enc.ENCOUNTERID = l.ENCOUNTERID
;


create table DIAGNOSIS as
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
join &&PCORNET_CDM_SCHEMA.DIAGNOSIS d
on enc.PATID = d.PATID and 
   enc.ENCOUNTERID = d.ENCOUNTERID
;


create table PRESCRIBING as
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
join &&PCORNET_CDM_SCHEMA.PRESCRIBING p
on enc.PATID = p.PATID and 
   enc.ENCOUNTERID = p.ENCOUNTERID
;
