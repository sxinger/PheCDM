/*********************************************************************************
This table is to identify elevated blood pressure events. Elevated BP
events are identified by multiple combinatoral clinical endpoints 
comprising SBP above certain threshold and ICD diagnosis:
a) SBP >140 at current visit AND documented history of hypertension; or
b) SBP >140 at current visit and at another visit in last 18 months; or
c) SBP >160 at current visit 

For efficiency, it is recommended to perform computational 
phenotyping on a smaller cut of needed CDM tables only relevant to the 
eligible patient cohort. The study-specific CDM tables are usually 
saved in a separate Study_Schema preserving CDM relational database structure.
************************************************************************************/

/* setup environment*/
use role "ANALYTICS";
use warehouse ANALYTICS_WH;
use database ANALYTICSDB;
use schema VCCC_SCHEMA;

/*Declarative Step*/
set study_schema = 'Study_Schema';
set DIAGNOSIS = CONCAT($study_schema,'.DIAGNOSIS');
set VITAL = CONCAT($study_schema,'.VITAL');
show variables;

/*Identify elevated blood pressure events
a) SBP >140 at current visit AND documented history of hypertension; or
b) SBP >140 at current visit and at another visit in last 18 months; or
c) SBP >160 at current visit 
*/

create or replace temporary table BP_DX_Event as
select dx.PATID
      ,dx.DX as IDENTIFIER
      ,split_part(dx.DX,'.',1) as IDENTIFIER_GRP
      ,DAYS_SINCE_INDEX
from identifier($DIAGNOSIS) dx
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
      ,'SBP2' IDENTIFIER_TYPE
      ,(sbp2.DAYS_SINCE_INDEX-sbp1.DAYS_SINCE_INDEX) IDENTIFIER -- gap between two defining events
      ,'HBP' as ENDPOINT
      ,sbp2.MEASURE_DATE as ENDPOINT_DATE
      ,sbp2.DAYS_SINCE_INDEX
from identifier($VITAL) sbp1
join identifier($VITAL) sbp2
on sbp1.PATID = sbp2.PATID and
   sbp1.SYSTOLIC > 140 and sbp2.SYSTOLIC > 140 and
   sbp2.DAYS_SINCE_INDEX - sbp1.DAYS_SINCE_INDEX between 1 and 18*30 
union
select sbp.PATID
      ,'DX-SBP' as IDENTIFIER_TYPE
      ,(sbp.DAYS_SINCE_INDEX-dx.DAYS_SINCE_INDEX) IDENTIFIER -- gap between two defining events
      ,'HBP' as ENDPOINT
      ,sbp.MEASURE_DATE as ENDPOINT_DATE
      ,sbp.DAYS_SINCE_INDEX
from BP_DX_Event dx
join identifier($VITAL) sbp
on dx.PATID = sbp.PATID and
   sbp.SYSTOLIC > 140 and
   sbp.DAYS_SINCE_INDEX > dx.DAYS_SINCE_INDEX 
union
select PATID
      ,'SBP' as IDENTIFIER_TYPE
      ,0 as IDENTIFIER
      ,'HBP' as ENDPOINT
      ,MEASURE_DATE as ENDPOINT_DATE
      ,DAYS_SINCE_INDEX
from identifier($VITAL)
where SYSTOLIC > 160
;
