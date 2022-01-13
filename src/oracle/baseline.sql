/* This script is to collect baseline clinical characteristics
   from CDM tables needed for data analysis. 
   See "Data to be collected through EPIC.docx" for more details
*/

/*Assumption: the prep.sql has been run with study-specific cut of the
              following CDM tables: 
  - DEMOGRAPHIC
  - DIAGNOSIS
  - PROCEDURES
  - LAB_RESULT_CM
  - PRESCRIBING
  - DISPENSING
  - VITAL
*/

/*baseline demographic table: 1 patient per row*/
create table BL_DEMO as 
with demo_payor_rank as (
select p.PATID
      ,d.BIRTH_DATE
      ,round((p.INDEX_DATE - d.BIRTH_DATE)/365.25) AGE_AT_ENROLL
      ,d.SEX
      ,d.RACE
      ,d.HISPANIC
      ,d.PAT_PREF_LANGUAGE_SPOKEN 
--      ,a.ADDRESS_ZIP9  -- not available
      ,case when UPPER(e.RAW_PAYER_NAME_PRIMARY) like '%MEDICARE%' 
            then 1 else 0 end as MEDICARE_IND
      ,e.RAW_PAYER_NAME_PRIMARY
      ,round(e.ADMIT_DATE - p.INDEX_DATE) PAYER_DAYS_SINCE_ENROLL
      ,e.ADMIT_DATE
      ,row_number() over (partition by p.PATID order by case when UPPER(e.RAW_PAYER_NAME_PRIMARY) like '%MEDICARE%' then 1 else 0 end desc, e.ADMIT_DATE desc) rn 
from pat_incld p
join DEMOGRAPHIC d on p.PATID = d.PATID
-- left join &&PCORNET_CDM_SCHEMA.PRIVATE_ADDRESS_HISTORY a on p.PATID = a.PATID -- not available
left join ENCOUNTER e on p.PATID = e.PATID 
where e.ADMIT_DATE <= d.INDEX_DATE -- so that the payor 
)
select PATID
      ,BIRTH_DATE
      ,AGE_AT_ENROLL
      ,SEX
      ,RACE
      ,HISPANIC
      ,PAT_PREF_LANGUAGE_SPOKEN 
--      ,ADDRESS_ZIP9
      ,RAW_PAYER_NAME_PRIMARY
      ,MEDICARE_IND
      ,ADMIT_DATE as PAYER_LATEST_ENCOUNTER
      ,PAYER_DAYS_SINCE_ENROLL
from demo_payor_rank
where rn = 1
;


/*baseline lab table: 1 patient-lab-date per row*/
create table BL_LAB as
-- Total cholesterol 
select distinct p.PATID
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) as LAB_DATE 
      ,'TC' as LAB_NAME
      ,l.RESULT_NUM
      ,round(NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) - p.INDEX_DATE) as LAB_DAYS_SINCE_ENROLL
from pat_incld p 
join LAB_RESULT_CM l on l.PATID = p.PATID
where ( 
       /*--LOINC code set*/
        l.LAB_LOINC in ( 
           '2093-3'
          ,'48620-9'
          ,'35200-5'
          ,'14647-2'
          ) 
       or
      /*--local code set
        -- using a local mapping table VCCC.LOINC_COMPONENT_MAP to obtain
           local codes that may not completely mapped to LOINC ontology yet*/
         l.RAW_FACILITY_CODE in (
            select 'KUH|COMPONENT_ID:'||COMPONENT_ID as KUH_COMPONENT_ID from VCCC.LOINC_COMPONENT_MAP
            where LOINC in (
             '2093-3'
            ,'48620-9'
            ,'35200-5'
            ,'14647-2'
            )
          )
        )
       and 
       UPPER(l.RESULT_UNIT) = 'MG/DL' -- may want to comment it out to avoid missing records if the measuring units hasn't been standardized 
union all
-- LDL
select distinct p.PATID
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) as LAB_DATE 
      ,'LDL-C' as LAB_NAME
      ,l.RESULT_NUM
      ,round(NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) - p.INDEX_DATE) as LAB_DAYS_SINCE_ENROLL
from pat_incld p 
join LAB_RESULT_CM l on l.PATID = p.PATID
where ( 
       /*--LOINC code set*/
        l.LAB_LOINC in ( 
           '2089-1'
          ,'18262-6'
          ,'49132-4'
          ,'35198-1'
          ,'39469-2'
          ,'12773-8'
          ,'18261-8'
          ,'22748-8'
          ,'13457-7'
          ,'9346-8'
          ,'2574-2'
          ,'14815-5'
          ) 
          or
        /*--local code set
           -- using a local mapping table VCCC.LOINC_COMPONENT_MAP to obtain
              local codes that may not completely mapped to LOINC ontology yet */
         l.RAW_FACILITY_CODE in (
            select 'KUH|COMPONENT_ID:'||COMPONENT_ID as KUH_COMPONENT_ID from VCCC.LOINC_COMPONENT_MAP
            where LOINC in (
           '2089-1'
          ,'18262-6'
          ,'49132-4'
          ,'35198-1'
          ,'39469-2'
          ,'12773-8'
          ,'18261-8'
          ,'22748-8'
          ,'13457-7'
          ,'9346-8'
          ,'2574-2'
          ,'14815-5'
            )
          )
        )
       and 
       UPPER(l.RESULT_UNIT) = 'MG/DL' -- may want to comment it out to avoid missing records if the measuring units hasn't been standardized
union all
-- HDL
select distinct p.PATID
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) as LAB_DATE 
      ,'HDL-C' as LAB_NAME
      ,l.RESULT_NUM
      ,round(NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) - p.INDEX_DATE) as LAB_DAYS_SINCE_ENROLL
from pat_incld p 
join LAB_RESULT_CM l on l.PATID = p.PATID
where ( 
       /*--LOINC code set*/
        l.LAB_LOINC in ( 
           '2085-9'
          ,'49130-8'
          ,'35197-3'
          ,'12771-2'
          ,'12772-0'
          ,'18263-4'
          ,'27340-9'
          ,'14646-4'
          )
       or
       /*--local code set
        -- using a local mapping table VCCC.LOINC_COMPONENT_MAP to obtain
           local codes that may not completely mapped to LOINC ontology yet*/
         l.RAW_FACILITY_CODE in (
            select 'KUH|COMPONENT_ID:'||COMPONENT_ID as KUH_COMPONENT_ID from VCCC.LOINC_COMPONENT_MAP
            where LOINC in (
           '2085-9'
          ,'49130-8'
          ,'35197-3'
          ,'12771-2'
          ,'12772-0'
          ,'18263-4'
          ,'27340-9'
          ,'14646-4'
            )
          )
        )
       and 
       UPPER(l.RESULT_UNIT) = 'MG/DL' -- may want to comment it out to avoid missing records if the measuring units hasn't been standardized
union all
-- Triglycerides
select distinct p.PATID
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) as LAB_DATE 
      ,'TG' as LAB_NAME
      ,l.RESULT_NUM
      ,round(NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) - p.INDEX_DATE) as LAB_DAYS_SINCE_ENROLL
from pat_incld p 
join LAB_RESULT_CM l on l.PATID = p.PATID
where ( 
       /*--LOINC code set*/
        l.LAB_LOINC in ( 
           '2571-8'
          ,'1644-4'
          ,'3043-7'
         )
       or
       /*--local code set
        -- using a local mapping table VCCC.LOINC_COMPONENT_MAP to obtain
           local codes that may not completely mapped to LOINC ontology yet*/
         l.RAW_FACILITY_CODE in (
            select 'KUH|COMPONENT_ID:'||COMPONENT_ID as KUH_COMPONENT_ID from VCCC.LOINC_COMPONENT_MAP
            where LOINC in (
            '2571-8'
           ,'1644-4'
           ,'3043-7'
            )
          )
       )        
       and 
       UPPER(l.RESULT_UNIT) = 'MG/DL' -- may want to comment it out to avoid missing records if the measuring units hasn't been standardized
union all
-- Serum Creatinine
select distinct p.PATID
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) as LAB_DATE 
      ,'SCr' as LAB_NAME
      ,l.RESULT_NUM
      ,round(NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) - p.INDEX_DATE) as LAB_DAYS_SINCE_ENROLL
from pat_incld p 
join LAB_RESULT_CM l on l.PATID = p.PATID
where ( 
       /*--LOINC code set*/
        l.LAB_LOINC in ( 
            '2160-0'
           ,'38483-4'
           ,'14682-9'
           ,'21232-4'
           ,'35203-9'
           ,'44784-7'
           ,'59826-8'
          )
       or
       /*--local code set
        -- using a local mapping table VCCC.LOINC_COMPONENT_MAP to obtain
           local codes that may not completely mapped to LOINC ontology yet*/
         l.RAW_FACILITY_CODE in (
            select 'KUH|COMPONENT_ID:'||COMPONENT_ID as KUH_COMPONENT_ID from VCCC.LOINC_COMPONENT_MAP
            where LOINC in (
            '2160-0'
           ,'38483-4'
           ,'14682-9'
           ,'21232-4'
           ,'35203-9'
           ,'44784-7'
           ,'59826-8'
            )
          )
       )
       and (UPPER(l.RESULT_UNIT) = 'MG/DL' or UPPER(l.RESULT_UNIT) = 'MG') /*there are variations of common units*/
       and l.SPECIMEN_SOURCE <> 'URINE' /*only serum creatinine*/
       and l.RESULT_NUM > 0 /*value 0 could exist*/
union all
-- Urine Protein Creatinine ratio
select distinct p.PATID
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) as LAB_DATE 
      ,'UProtCrRatio' as LAB_NAME
      ,l.RESULT_NUM
      ,round(NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) - p.INDEX_DATE) as LAB_DAYS_SINCE_ENROLL
from pat_incld p 
join LAB_RESULT_CM l on l.PATID = p.PATID
where ( 
       /*--LOINC code set*/
        l.LAB_LOINC in ( 
           '34366-5'
          ,'40486-3'
          ,'14959-1'
          ,'2889-4'
         )
       or
       /*--local code set
        -- using a local mapping table VCCC.LOINC_COMPONENT_MAP to obtain
           local codes that may not completely mapped to LOINC ontology yet*/
         l.RAW_FACILITY_CODE in (
            select 'KUH|COMPONENT_ID:'||COMPONENT_ID as KUH_COMPONENT_ID from VCCC.LOINC_COMPONENT_MAP
            where LOINC in (
           '34366-5'
          ,'40486-3'
          ,'14959-1'
          ,'2889-4'
            )
          )
      )
;

/*baseline medical history/condition table: 1 patient-condition-date per row*/
create table BL_COND as
with event_deck as (
-- history of coronary artery disease: diagnosis
select  dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,'CAD' as CONDITION
      ,dx.DX_DATE as CONDITION_DATE
      ,round(dx.DX_DATE - p.INDEX_DATE) as COND_DAYS_SINCE_ENROLL
from pat_incld p
join DIAGNOSIS dx on p.PATID = dx.PATID
where (dx.DX_TYPE = '10' and
       (dx.DX like 'I25%')) 
      or 
      (dx.DX_TYPE = '09' and
       (dx.DX like '410%' or
        dx.DX like '411%' or
        dx.DX like '412%' or
        dx.DX like '413%' or
        dx.DX like '414%' or 
        dx.DX like '429.7%' or 
        dx.DX like 'V45.81%' or 
        dx.DX like 'V45.82%'))
union all
-- history of coronary artery disease: past coronary revascularization procedures
select px.PATID
      ,'PX' as IDENTIFIER_TYPE
      ,'CAD' as CONDITION
      ,px.PX_DATE as CONDITION_DATE
      ,round(px.PX_DATE - p.INDEX_DATE) as COND_DAYS_SINCE_ENROLL
from pat_incld p
join PROCEDURES px on p.PATID = px.PATID
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
union all
-- history of stroke
select dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,'Stroke' as CONDITION
      ,dx.DX_DATE as CONDITION_DATE
      ,round(dx.DX_DATE - p.INDEX_DATE) as COND_DAYS_SINCE_ENROLL
from pat_incld p
join DIAGNOSIS dx on p.PATID = dx.PATID
where (dx.DX_TYPE = '10' and
       (dx.DX like 'I61%' or
        dx.DX like 'I62%' or
        dx.DX like 'I63%' )) 
      or 
      (dx.DX_TYPE = '09' and
       (dx.DX like '431%' or
        dx.DX like '434%'))
union all
-- history of CKD
select dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,'CKD' as CONDITION
      ,dx.DX_DATE
      ,round(dx.DX_DATE - p.INDEX_DATE) as COND_DAYS_SINCE_ENROLL
from pat_incld p
join DIAGNOSIS dx on p.PATID = dx.PATID
where (dx.DX_TYPE = '10' and
       (dx.DX like 'N18%')) 
      or 
      (dx.DX_TYPE = '09' and
       (dx.DX like '585%'))
union all
select dx.PATID
      ,'LAB' as IDENTIFIER_TYPE
      ,'CKD' as CONDITION
      ,NVL(lab.SPECIMEN_DATE,lab.LAB_ORDER_DATE) as CONDITION_DATE 
      ,round(NVL(lab.SPECIMEN_DATE,lab.LAB_ORDER_DATE) - p.INDEX_DATE) as COND_DAYS_SINCE_ENROLL
from pat_incld p
join LAB_RESULT_CM lab on p.PATID = lab.PATID
where ( 
       /*--LOINC code set for eGFR/GFR*/
        l.LAB_LOINC in ( 
           '33914-3'
          ,'50044-7'
          ,'48642-3'
          ,'48643-1'
          ,'62238-1'
          ,'88293-6'
          ,'88294-4'
          ,'69405-9'
          ,'94677-2'
         )
       or
       /*--local code set
        -- using a local mapping table VCCC.LOINC_COMPONENT_MAP to obtain
           local codes that may not completely mapped to LOINC ontology yet*/
         l.RAW_FACILITY_CODE in (
            select 'KUH|COMPONENT_ID:'||COMPONENT_ID as KUH_COMPONENT_ID from VCCC.LOINC_COMPONENT_MAP
            where LOINC in (
           '33914-3'
          ,'50044-7'
          ,'48642-3'
          ,'48643-1'
          ,'62238-1'
          ,'88293-6'
          ,'88294-4'
          ,'69405-9'
          ,'94677-2'
            )
          )
       )
      and 
      lab.RESULT_NUM < 60
union all
-- history of dyslipidemia
select dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,'Dyslipidemia' as CONDITION
      ,dx.DX_DATE as CONDITION_DATE
      ,round(dx.DX_DATE - p.INDEX_DATE) as COND_DAYS_SINCE_ENROLL
from pat_incld p
join DIAGNOSIS dx on p.PATID = dx.PATID
where (dx.DX_TYPE = '10' and
       (dx.DX like 'E78.5%' )) 
      or 
      (dx.DX_TYPE = '09' and
       (dx.DX like '272.4%'))
)
select distinct PATID
      ,CONDITION
      ,CONDITIOn_DATE
      ,COND_DAYS_SINCE_ENROLL
from event_deck
;

/*stage the supplement concept_set files: 
1. ConceptSet_Med_AntiHTN.csv  --RXNORM codes of different AntiHTN drug classes
source: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7068459/

2. ConceptSet_Med_AntiHTN_NDC.csv  --NDC codes of different AntiHTN drug classes
source: https://www.nlm.nih.gov/research/umls/rxnorm/docs/techdoc.htm 
*/
select * from CONCEPTSET_MED_ANTIHTN;
select * from CONCEPTSET_MED_ANTIHTN_NDC;

/*baseline medication: 1 patient-drugclass-perscription/dispense per row*/
create table BL_MED as
-- from prescribing table
select distinct
       p.PATID
      ,m.RX_START_DATE as START_DATE
      ,m.RX_END_DATE as END_DATE --can be empty
      ,cs.DRUG_CLASS
      ,m.RX_DAYS_SUPPLY as DAYS_SUPPLY
      ,m.RX_DOSE_ORDERED as DOSE
      ,m.RX_DOSE_ORDERED_UNIT as DOSE_UNIT
      ,m.RX_QUANTITY as QUANTITY_AMT
      ,round(m.RX_START_DATE - p.INDEX_DATE) as DAYS_SINCE_ENROLL
      ,'Prescribing' DRUG_SOURCE_TABLE
from pat_incld p
join PRESCRIBING m on m.PATID = p.PATID
join CONCEPTSET_MED_ANTIHTN cs on m.RXNORM_CUI = cs.RXCUI 
where m.RX_ORDER_DATE <= p.INDEX_DATE
union all 
-- from dispensing table
select distinct
       p.PATID
      ,d.DISPENSE_DATE START_DATE
      ,NULL as END_DATE --no end_date for dispensing data
      ,cs.DRUG_CLASS
      ,d.DISPENSE_SUP as DAYS_SUPPLY
      ,d.DISPENSE_DOSE_DISP as DOSE
      ,d.DISPENSE_DOSE_DISP_UNIT as DOSE_UNIT
      ,d.DISPENSE_AMT as QUANTITY_AMT
      ,round(d.DISPENSE_DATE - p.INDEX_DATE) as DAYS_SINCE_ENROLL
      ,'Dispensing' DRUG_SOURCE_TABLE
from pat_incld p
join DISPENSING d on d.PATID = p.PATID
join CONCEPTSET_MED_ANTIHTN_NDC csn on d.NDC = csn.NDC 
where d.DISPENSE_DATE <= p.INDEX_DATE
;

/*baseline BMI: 1 patient-BMI record per row
create table BL_BMI as
select p.PATID
      ,v.HT as HT
      ,v.WT as WT
      ,NVL(round(v.WT/(v.HT*v.HT)*703),v.ORIGINAL_BMI) as BMI -- BMI = (Weight in Pounds / (Height in inches) x (Height in inches)) x 703
      ,round(v.MEASURE_DATE - p.INDEX_DATE) as DAYS_SINCE_ENROLL
from pat_incld p
join VITAL v on v.PATID = p.PATID 
where coalesce(v.HT,v.WT,v.ORIGINAL_BMI) is not null
;
*/


/*baseline vital: 1 patient-vital-record per row
  - height
  - weiht
  - BMI
  - heart rate
*/
create table BL_VITAL as
with vital_stack (
---- HEIGHT ----
-- from VITAL table
select p.PATID
      ,v.ENCOUNTERID
      ,'HT' as VITAL_TYPE
      ,v.HT as VITAL_VAL
      ,'in' as VITAL_UNIT
      ,round(v.MEASURE_DATE - p.INDEX_DATE) as DAYS_SINCE_ENROLL
from pat_incld p
join VITAL v on v.PATID = p.PATID 
where v.HT is not null
union all
-- from OBS_CLIN table
select p.PATID
      ,oc.ENCOUNTERID
      ,'HT' as VITAL_TYPE
      ,oc.OBSCLIN_RESULT as VITAL_VAL
      ,oc.OBSCLIN_RESULT_UNIT as VITAL_UNIT -- could be "cm" or "in"
      ,round(oc.OBSCLIN_START_DATE - p.INDEX_DATE) as DAYS_SINCE_ENROLL
from pat_incld p
join OBS_CLIN oc on oc.PATID = p.PATID and
     oc.OBSCLIN_TYPE = 'LC' and oc.OBSCLIN_CODE = '8302-2'
union all
---- WEIGHT ----
-- from VITAL table
select p.PATID
      ,v.ENCOUNTERID
      ,'WT' as VITAL_TYPE
      ,v.WT as VITAL_VAL
      ,'lb' as VITAL_UNIT
      ,round(v.MEASURE_DATE - p.INDEX_DATE) as DAYS_SINCE_ENROLL
from pat_incld p
join VITAL v on v.PATID = p.PATID 
where v.WT is not null
union all
-- from OBS_CLIN table
select p.PATID
      ,oc.ENCOUNTERID
      ,'WT' as VITAL_TYPE
      ,oc.OBSCLIN_RESULT as VITAL_VAL
      ,oc.OBSCLIN_RESULT_UNIT as VITAL_UNIT -- could be "lb" or "kg"
      ,round(oc.OBSCLIN_START_DATE - p.INDEX_DATE) as DAYS_SINCE_ENROLL
from pat_incld p
join OBS_CLIN oc on oc.PATID = p.PATID and
     oc.OBSCLIN_TYPE = 'LC' and oc.OBSCLIN_CODE = '29463-7'
union all
---- BMI ----
-- from VITAL table
select p.PATID
      ,v.ENCOUNTERID
      ,'BMI' as VITAL_TYPE
      ,NVL(round(v.WT/(v.HT*v.HT)*703),v.ORIGINAL_BMI) as VITAL_VAL -- BMI = (Weight in Pounds / (Height in inches) x (Height in inches)) x 703
      ,'kg/m2'
      ,round(v.MEASURE_DATE - p.INDEX_DATE) as DAYS_SINCE_ENROLL
from pat_incld p
join VITAL v on v.PATID = p.PATID 
where coalesce(v.HT,v.WT,v.ORIGINAL_BMI) is not null
-- from OBS_CLIN table
select p.PATID
      ,oc.ENCOUNTERID
      ,'BMI' as VITAL_TYPE
      ,oc.OBSCLIN_RESULT as VITAL_VAL
      ,oc.OBSCLIN_RESULT_UNIT as VITAL_UNIT 
      ,round(oc.OBSCLIN_START_DATE - p.INDEX_DATE) as DAYS_SINCE_ENROLL
from pat_incld p
join OBS_CLIN oc on oc.PATID = p.PATID and
     oc.OBSCLIN_TYPE = 'LC' and oc.OBSCLIN_CODE = '39156-5'
---- HEART RATE ----
-- from OBS_CLIN table
select p.PATID
      ,oc.ENCOUNTERID
      ,'HR' as VITAL_TYPE
      ,oc.OBSCLIN_RESULT as VITAL_VAL
      ,oc.OBSCLIN_RESULT_UNIT as VITAL_UNIT 
      ,round(oc.OBSCLIN_START_DATE - p.INDEX_DATE) as DAYS_SINCE_ENROLL
from pat_incld p
join OBS_CLIN oc on oc.PATID = p.PATID and
     oc.OBSCLIN_TYPE = 'LC' and 
     oc.OBSCLIN_CODE in ( '8889-8' -- general heart rate by Pulse oximetry
                         ,'8867-4' -- general heart rate by Palpation
                         ,'11328-2'-- heart rate at first encounter
                        )
)
select distinct
       PATID
      ,ENCOUNTERID
      ,VITAL_TYPE
      ,VITAL_VAL
      ,VITAL_UNIT
      ,DAYS_SINCE_ENROLL
from vital_stack
;