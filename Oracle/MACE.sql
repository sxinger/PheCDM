/********************************************************************
This script is to identify Major adverse cardiovascular events (MACE)
for the targeted cohort. MACE events are identified by ICD diagnosis
codes and CPT procedure codes.

For efficiency, it is recommended to perform computational 
phenotyping on a smaller cut of CDM DIAGNOSIS and PROCEDURES 
tables relevant to the eligible patient cohort. 

By running the prep.sql script, the study-specific DIAGNOSIS and 
PROCEDURES tables will be saved in a separate Study_Schema with 
CDM relational database structure preserved.
********************************************************************/

/*Identify MACE events:
- MI:myocardial infarction
- Ischemic,ST:nonfatal ischemic stroke 
- Hemorrhagic,ST:nonfatal hemorrhagic stroke 
- CR:Coronary revascularization 
- HF:Heart failure 
*/

/*Assumption: current schema is different from &&PCORNET_CDM_SCHEMA, 
              and it is where the prep.sql was run and all dependend
              study-specific CDM tables were created
*/

create table MACE_event as
select dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,dx.DX as IDENTIFIER
      ,split_part(dx.DX,'.',1) as IDENTIFIER_GRP
      ,'MI' ENDPOINT
      ,dx.DX_DATE ENDPOINT_DATE
from DIAGNOSIS dx
where dx.DX_TYPE = '10' and
      (dx.DX like 'I21%' or
       dx.DX like 'I22%' or
       dx.DX like 'I23%')
union
select dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,dx.DX as IDENTIFIER
      ,split_part(dx.DX,'.',1) as IDENTIFIER_GRP
      ,'ST-Ischemic' ENDPOINT
      ,dx.DX_DATE ENDPOINT_DATE
from DIAGNOSIS dx
where dx.DX_TYPE = '10' and
      dx.DX like 'I63%'
union
select dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,dx.DX as IDENTIFIER
      ,split_part(dx.DX,'.',1) as IDENTIFIER_GRP
      ,'ST-Hemorrhagic' ENDPOINT
      ,dx.DX_DATE ENDPOINT_DATE
from DIAGNOSIS dx
where dx.DX_TYPE = '10' and
      (dx.DX like 'I61%' or
       dx.DX like 'I62%')
union
select dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,dx.DX as IDENTIFIER
      ,split_part(dx.DX,'.',1) as IDENTIFIER_GRP
      ,'HF' ENDPOINT
      ,dx.DX_DATE ENDPOINT_DATE
from DIAGNOSIS dx
where dx.DX_TYPE = '10' and
      dx.DX like 'I50%'
union
select px.PATID
      ,'PX' as IDENTIFIER_TYPE
      ,px.PX as IDENTIFIER
      ,substr(px.PX,1,3) as IDENTIFIER_GRP
      ,'CR' ENDPOINT
      ,dx.DX_DATE ENDPOINT_DATE
from DIAGNOSIS px
where px.PX_TYPE = '10' and
      (px.PX like '021%' or
       px.PX like '027%'
      )
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
