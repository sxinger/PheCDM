/********************************************************************
This script is to identify Major adverse cardiovascular events (MACE)
for the targeted cohort. MACE events are identified by ICD diagnosis
codes and CPT procedure codes.

For efficiency, it is recommended to perform computational 
phenotyping on a smaller cut of CDM DIAGNOSIS and PROCEDURES 
tables relevant to the eligible patient cohort. The study-specific
DIAGNOSIS and PROCEDURES tables are usually saved in a separate
Study_Schema with CDM relational database structure preserved.
********************************************************************/

/* setup environment*/
use role "ANALYTICS";
use warehouse ANALYTICS_WH;
use database ANALYTICSDB;
use schema VCCC_SCHEMA;

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
      ,'MI' ENDPOINT
      ,dx.DX_DATE ENDPOINT_DATE
from DIAGNOSIS dx
where dx.DX_TYPE = '10' and
      split_part(dx.DX,'.',1) in ( 'I21'
                                  ,'I22'
                                  ,'I23')
union
select dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,dx.DX as IDENTIFIER
      ,split_part(dx.DX,'.',1) as IDENTIFIER_GRP
      ,'ST-Ischemic' ENDPOINT
      ,dx.DX_DATE ENDPOINT_DATE
from DIAGNOSIS dx
where dx.DX_TYPE = '10' and
      split_part(dx.DX,'.',1) in ( 'I63')
union
select dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,dx.DX as IDENTIFIER
      ,split_part(dx.DX,'.',1) as IDENTIFIER_GRP
      ,'ST-Hemorrhagic' ENDPOINT
      ,dx.DX_DATE ENDPOINT_DATE
from DIAGNOSIS dx
where dx.DX_TYPE = '10' and
      split_part(dx.DX,'.',1) in ( 'I61'
                                  ,'I62')
union
select dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,dx.DX as IDENTIFIER
      ,split_part(dx.DX,'.',1) as IDENTIFIER_GRP
      ,'HF' ENDPOINT
      ,dx.DX_DATE ENDPOINT_DATE
from DIAGNOSIS dx
where dx.DX_TYPE = '10' and
      split_part(dx.DX,'.',1) in ( 'I50')
union
select px.PATID
      ,'PX' as IDENTIFIER_TYPE
      ,px.PX as IDENTIFIER
      ,substr(px.PX,1,3) as IDENTIFIER_GRP
      ,'CR' ENDPOINT
      ,dx.DX_DATE ENDPOINT_DATE
from DIAGNOSIS px
where px.PX_TYPE = '10' and
      substr(px.PX,1,3) in ( '021'
                            ,'027')
union
select px.PATID
      ,'PX' as IDENTIFIER_TYPE
      ,px.PX as IDENTIFIER
      ,substr(px.PX,1,3) as IDENTIFIER_GRP
      ,'CR' ENDPOINT
      ,dx.DX_DATE ENDPOINT_DATE
from DIAGNOSIS px
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
                ,'92980'
                ,'92981'
                ,'92982'
                ,'92984'
                ,'92995'
                ,'92996'
                ,'92973'
                ,'92974'
               )
;
