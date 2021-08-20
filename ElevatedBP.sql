/********************************************************************
This table is to identify elevated blood pressure events. Elevated BP
events are identified by multiple combinatoral clinical endpoints 
comprising SBP above certain threshold and ICD diagnosis:
a) SBP >140 at current visit AND documented history of hypertension; or
b) SBP >140 at current visit and at another visit in last 18 months; or
c) SBP >160 at current visit 

For efficiency, it is recommended to perform computational 
phenotyping on a smaller cut of needed CDM tables only relevant to the 
eligible patient cohort
********************************************************************/

/*Declarative Step*/
set cdm_db_schema = 'PCORNET_CDM.CDM_C010R021';
set DIAGNOSIS = CONCAT($cdm_db_schema,'.DIAGNOSIS');
set VITAL = CONCAT($cdm_db_schema,'.VITAL');
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
      ,DAY(dx.DX_DATE::date) - DAY(pat.INDEX_DATE::date) DAYS_SINCE_INDEX
from pat_eligible pat
join identifier($DIAGNOSIS) dx
on pat.PATID = dx.PATID
; 

/*Study-Specific CDM VITAL table*/
create or replace table CDM_VITAL_VCCC as
select pat.PATID
      ,vt.SYSTOLIC
      ,DAY(vt.MEASURE_DATE::date) - DAY(pat.INDEX_DATE::date) DAYS_SINCE_INDEX
from pat_eligible pat
join identifier($VITAL) vt
on pat.PATID = vt.PATID
; 

/*Identify elevated blood pressure events
a) SBP >140 at current visit AND documented history of hypertension; or
b) SBP >140 at current visit and at another visit in last 18 months; or
c) SBP >160 at current visit 
*/

create or replace table BP_DX_Event as
select dx.PATID
      ,dx.DX as IDENTIFIER
      ,split_part(dx.DX,'.',1) as IDENTIFIER_GRP
      ,DAYS_SINCE_INDEX
from CDM_DX_VCCC dx
where (dx.DX_TYPE = '10' and
       split_part(dx.DX,'.',1) in ( 'I10'
                                   ,'I11'
                                   ,'I12'
                                   ,'I13'
                                   ,'R03')
       ) or
       (dx.DX_TYPE = '09' and
       split_part(dx.DX,'.',1) in ( '401'
                                   ,'402'
                                   ,'403'
                                   ,'404'
                                   ,'405')
        )   
;

create or replace table BP_Event as
select sbp1.PATID
      ,(sbp2.DAYS_SINCE_INDEX-sbp1.DAYS_SINCE_INDEX) SUB_EVENT -- gap between two defining events
      ,'SBP_PAIR' as ENDPOINT
      ,sbp2.DAYS_SINCE_INDEX
from CDM_VITAL_VCCC sbp1
join CDM_VITAL_VCCC sbp2
on sbp1.PATID = sbp2.PATID and
   sbp1.SYSTOLIC > 140 and sbp2.SYSTOLIC > 140 and
   sbp2.DAYS_SINCE_INDEX - sbp1.DAYS_SINCE_INDEX between 1 and 18*30 
union
select sbp.PATID
      ,(sbp.DAYS_SINCE_INDEX-dx.DAYS_SINCE_INDEX) SUB_EVENT -- gap between two defining events
      ,'SBP_DX' as ENDPOINT
      ,sbp.DAYS_SINCE_INDEX
from BP_DX_Event dx
join CDM_VITAL_VCCC sbp
on dx.PATID = sbp.PATID and
   sbp.SYSTOLIC > 140 and
   sbp.DAYS_SINCE_INDEX > dx.DAYS_SINCE_INDEX 
union
select PATID
      ,0 as SUB_EVENT
      ,'SBP_SINGLE' as ENDPOINT
      ,DAYS_SINCE_INDEX
from CDM_VITAL_VCCC
where SYSTOLIC > 160
;

