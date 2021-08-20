/********************************************************************
This table is to identify Major adverse cardiovascular events (MACE)
for the targeted cohort. MACE events are identified by ICD diagnosis
codes and CPT procedure codes.

For efficiency, it is recommended to perform computational 
phenotyping on a smaller cut of CDM DIAGNOSIS and PROCEDURES 
tables relevant to the eligible patient cohort
********************************************************************/

/*Declarative Steps*/
set cdm_db_schema = 'PCORNET_CDM.CDM_C010R021';
set DIAGNOSIS = CONCAT($cdm_db_schema,'.DIAGNOSIS');
set PROCEDURES = CONCAT($cdm_db_schema,'.PROCEDURES');
show variables;

/*Study-Specific CDM DIAGNOSIS table*/
create or replace table CDM_DX_VCCC as
select pat.PATID
      ,dx.DX
      ,dx.DX_TYPE
      ,dx.DX_SOURCE
      ,dx.DX_ORIGIN
      ,dx.PDX
      ,dx.DX_POA
      ,dx.DX_DATE
      ,DAY(dx.DX_DATE::date) - DAY(pat.ENROLL_START::date) DAYS_SINCE_ENROLL
from pat_eligible pat
join identifier($DIAGNOSIS) dx
on pat.PATID = dx.PATID and
   dx.DX_DATE >= pat.ENROLL_START
; 

/*Study-Specific CDM PROCEDURES table*/
create or replace table CDM_PX_VCCC as
select pat.PATID
      ,px.PX
      ,px.PX_TYPE
      ,px.PX_SOURCE
      ,px.PX_DATE
      ,DAY(px.PX_DATE::date) - DAY(pat.ENROLL_START::date) DAYS_SINCE_ENROLL
from pat_eligible pat
join identifier($PROCEDURES) px
on pat.PATID = px.PATID and
   px.PX_DATE >= pat.ENROLL_START
; 


/*Identify MACE events:
- MI:myocardial infarction
- Ischemic,ST:nonfatal ischemic stroke 
- Hemorrhagic,ST:nonfatal hemorrhagic stroke 
- CR:Coronary revascularization 
- HF:Heart failure 
*/
create or replace table MACE_event as
select dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,dx.DX as IDENTIFIER
      ,split_part(dx.DX,'.',1) as IDENTIFIER_GRP
      ,'MI' SUB_EVENT
      ,'MI' ENDPOINT
      ,DAYS_SINCE_ENROLL
from CDM_DX_VCCC dx
where dx.DX_TYPE = '10' and
      split_part(dx.DX,'.',1) in ( 'I21'
                                  ,'I22')
union
select dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,dx.DX as IDENTIFIER
      ,split_part(dx.DX,'.',1) as IDENTIFIER_GRP
      ,'Ischemic' SUB_EVENT
      ,'ST' ENDPOINT
      ,DAYS_SINCE_ENROLL
from CDM_DX_VCCC dx
where dx.DX_TYPE = '10' and
      split_part(dx.DX,'.',1) in ( 'I63')
union
select dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,dx.DX as IDENTIFIER
      ,split_part(dx.DX,'.',1) as IDENTIFIER_GRP
      ,'Hemorrhagic' SUB_EVENT
      ,'ST' ENDPOINT
      ,DAYS_SINCE_ENROLL
from CDM_DX_VCCC dx
where dx.DX_TYPE = '10' and
      split_part(dx.DX,'.',1) in ( 'I61'
                                  ,'I62')
union
select dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,dx.DX as IDENTIFIER
      ,split_part(dx.DX,'.',1) as IDENTIFIER_GRP
      ,'HF' SUB_EVENT
      ,'HF' ENDPOINT
      ,DAYS_SINCE_ENROLL
from CDM_DX_VCCC dx
where dx.DX_TYPE = '10' and
      split_part(dx.DX,'.',1) in ( 'I50')
union
select px.PATID
      ,'PX' as IDENTIFIER_TYPE
      ,px.PX as IDENTIFIER
      ,substr(px.PX,1,3) as IDENTIFIER_GRP
      ,'CR' SUB_EVENT
      ,'CR' ENDPOINT
      ,DAYS_SINCE_ENROLL
from CDM_PX_VCCC px
where px.PX_TYPE = '10' and
      substr(px.PX,1,3) in ( '021'
                            ,'027')
union
select px.PATID
      ,'PX' as IDENTIFIER_TYPE
      ,px.PX as IDENTIFIER
      ,substr(px.PX,1,3) as IDENTIFIER_GRP
      ,'CR' SUB_EVENT
      ,'CR' ENDPOINT
      ,DAYS_SINCE_ENROLL
from CDM_PX_VCCC px
where px.PX_TYPE = 'CH' and
      px.PX in ( '92920'
                ,'92921'
                ,'92924'
                ,'92925'
                ,'92928'
                ,'92929'
                ,'92933'
                ,'92934'
                ,'92937'
                ,'92938'
                ,'92941'
                ,'92943'
                ,'92944'
               )
;
