/* This script is to collect a cohort-specific cut of core 
   CDM tables needed by other computational phenotyping scripts.
*/

/*eligible patients*/
create table pat_incld as
select PATID -- assume it is one patient per row
      ,TRIAL_ENROLL_DATE as INDEX_DATE
from &&PCORNET_CDM_SCHEMA.PCORNET_TRIAL
-- where TRIAL_ENROLL_DATE >= '&VCCC_Start_Date' -- we want the "Index_date" to be w.r.t. VCCC not other trials patient used to participate
where TRIALID = 'VCCC' -- identifier of VCCC trial
;

/*gather demographic information from CDM*/
create table DEMOGRAPHIC as
select pat.PATID
      ,d.BIRTH_DATE
      ,d.SEX
      ,d.RACE
      ,d.HISPANIC
      ,d.PAT_PREF_LANGUAGE_SPOKEN 
from pat_incld pat
join &&PCORNET_CDM_SCHEMA.DEMOGRAPHIC d on pat.PATID = d.PATID
;

/*gather patient-level insurance coverage information from Clarity table*/
create table ENCOUNTER AS
select pat.PATID
      ,e.ENCOUNTERID
      ,e.ENC_TYPE
      ,e.ADMIT_DATE
      ,e.PROVIDERID
      ,e.PAYER_TYPE_PRIMARY
      ,e.RAW_PAYER_TYPE_PRIMARY
      ,e.RAW_PAYER_NAME_PRIMARY
from pat_incld pat
join &&PCORNET_CDM_SCHEMA.ENCOUNTER e on pat.PATID = e.PATID
;

/*gather BP, HT, WT, BMI, and SMOKING information from CDM VITAL table*/
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
      ,v.MEASURE_DATE - pat.INDEX_DATE as DAY_SINCE_INDEX
from pat_incld pat
join &&PCORNET_CDM_SCHEMA.VITAL v
on pat.PATID = v.PATID 
;

/*gather BP and other Observables from CDM OBS_CLIN table*/
create table OBS_CLIN as
select pat.PATID
      ,o.ENCOUNTERID
      ,o.OBSCLIN_TYPE 
      ,o.OBSCLIN_CODE
      ,o.OBSCLIN_RESULT_QUAL
      ,o.OBSCLIN_RESULT_TEXT 
      ,o.OBSCLIN_RESULT_SNOMED
      ,o.OBSCLIN_RESULT_NUM
      ,o.OBSCLIN_RESULT_MODIFIER
      ,o.OBSCLIN_RESULT_UNIT
      ,o.OBSCLIN_SOURCE
      ,o.OBSCLIN_ABN_IND   
      ,o.RAW_OBSCLIN_CODE
      ,o.RAW_OBSCLIN_NAME  
      ,o.OBSCLIN_START_DATE
      ,o.OBSCLIN_START_DATE - pat.INDEX_DATE as DAY_SINCE_INDEX
from pat_incld pat
join &&PCORNET_CDM_SCHEMA.OBS_CLIN o
on pat.PATID = o.PATID 
;

create table LAB_RESULT_CM as
select pat.PATID
      ,l.ENCOUNTERID
      ,l.LAB_LOINC
      ,l.LAB_RESULT_SOURCE
      ,l.LAB_LOINC_SOURCE
      ,l.PRIORITY
      ,l.RESULT_LOC
      ,l.LAB_PX
      ,l.LAB_PX_TYPE
      ,l.LAB_ORDER_DATE
      ,l.SPECIMEN_SOURCE
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
from pat_incld pat
join &&PCORNET_CDM_SCHEMA.LAB_RESULT_CM l
on pat.PATID = l.PATID
;

create table DIAGNOSIS as
select pat.PATID
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
from pat_incld pat
join &&PCORNET_CDM_SCHEMA.DIAGNOSIS d
on pat.PATID = d.PATID
;

create table PROCEDURES as
select pat.PATID
      ,px.ENCOUNTERID
      ,px.PX
      ,px.PX_TYPE
      ,px.PX_SOURCE
      ,px.PX_DATE
from pat_incld pat
join &&PCORNET_CDM_SCHEMA.PROCEDURES px
on pat.PATID = px.PATID
;

create table PRESCRIBING as
select pat.PATID
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
from pat_incld pat
join &&PCORNET_CDM_SCHEMA.PRESCRIBING p
on pat.PATID = p.PATID
;

create table DISPENSING as
select pat.PATID
      ,d.ENCOUNTERID
      ,d.PRESCRIBINGID
      ,d.DISPENSE_DATE
      ,d.NDC
      ,d.DISPENSE_SOURCE
      ,d.DISPENSE_SUP
      ,d.DISPENSE_AMT
      ,d.DISPENSE_DOSE_DISP
      ,d.DISPENSE_DOSE_DISP_UNIT
      ,d.DISPENSE_ROUTE
from pat_incld pat
join &&PCORNET_CDM_SCHEMA.DISPENSING d
on pat.PATID = d.PATID
;

/*
create table MED_ADMIN as
select pat.PATID
      ,m.ENCOUNTERID
      ,m.MEDADMIN_TYPE
      ,m.MEDADMIN_CODE
      ,m.MEDADMIN_DOSE_ADMIN
      ,m.MEDADMIN_ROUTE
      ,m.MEDADMIN_SOURCE
      ,m.MEDADMIN_START_DATE
      ,m.MEDADMIN_START_TIME
from pat_incld pat
join &&PCORNET_CDM_SCHEMA.MED_ADMIN m
on pat.PATID = m.PATID
;
*/