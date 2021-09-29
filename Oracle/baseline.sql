/* This script is to collect baseline clinical characteristics
   from CDM tables needed for data analysis
*/

/*Assumption: the prep.sql has been run with study-specific cut of the
              following CDM tables: 
  - DEMOGRAPHIC
  - DEMOGRAPHIC_SUPP (supplemental insurance coverage table)
  - DIAGNOSIS
  - PROCEDURES
  - LAB_RESULT_CM
  - PRESCRIBING
  - DISPENSING
*/

/*baseline demographic table: 1 patient-provider per row*/
create table BL_DEMO as 
with demo_payor_rank as (
select p.PATID
      ,d.BIRTH_DATE
      ,round((p.INDEX_DATE - d.BIRTH_DATE)/365.25) AGE_AT_ENROLL
      ,d.SEX
      ,d.RACE
      ,d.HISPANIC
      ,d.PAT_PREF_LANGUAGE_SPOKEN 
      ,a.ADDRESS_ZIP9
      ,ds.RAW_PAYOR_NAME
      ,dense_rank() over (partition by p.PATID order by case when p.INDEX_DATE between ds.MEM_EFF_FROM_DATE and coalesce(ds.MEM_EFF_TO_DATE, CURRENT_DATE) then 0 else 1 end) rn 
from pat_incld p
join DEMOGRPHIC d on p.PATID = d.PATID
left join &&PCORNET_CDM_SCHEMA.PRIVATE_ADDRESS_HISTORY a on p.PATID = a.PATID
left join DEMOGRAPHIC_SUPP ds on p.PATID = ds.PATID 
)
select PATID
      ,BIRTH_DATE
      ,AGE_AT_ENROLL
      ,SEX
      ,RACE
      ,HISPANIC
      ,PAT_PREF_LANGUAGE_SPOKEN 
      ,ADDRESS_ZIP9
      ,RAW_PAYOR_NAME
from demo_payor_rank
where rn = 1
;

/*baseline lab table: 1 patient-lab-observation per row*/
create table BL_LAB as
-- Total cholesterol 
select p.PATID
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) as LAB_DATE 
      ,'TC' as LAB_NAME
      ,l.RESULT_NUM
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) - p.INDEX_DATE as LAB_DAYS_SINCE_ENROLL
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
       and UPPER(l.RESULT_UNIT) = 'MG/DL'
      ) 
union all
-- LDL
select p.PATID
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) as LAB_DATE 
      ,'LDL-C' as LAB_NAME
      ,l.RESULT_NUM
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) - p.INDEX_DATE as LAB_DAYS_SINCE_ENROLL
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
       and UPPER(l.RESULT_UNIT) = 'MG/DL'
      )
union all
-- HDL
select p.PATID
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) as LAB_DATE 
      ,'HDL-C' as LAB_NAME
      ,l.RESULT_NUM
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) - p.INDEX_DATE as LAB_DAYS_SINCE_ENROLL
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
       and UPPER(l.RESULT_UNIT) = 'MG/DL'
      )
union all
-- Triglycerides
select p.PATID
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) as LAB_DATE 
      ,'TG' as LAB_NAME
      ,l.RESULT_NUM
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) - p.INDEX_DATE as LAB_DAYS_SINCE_ENROLL
from pat_incld p 
join LAB_RESULT_CM l on l.PATID = p.PATID
where ( 
       /*--LOINC code set*/
       l.LAB_LOINC in ( 
          '2571-8'
         ,'1644-4'
         ,'3043-7'
         )
       and UPPER(l.RESULT_UNIT) = 'MG/DL'
      )
union all
-- Serum Creatinine
select p.PATID
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) as LAB_DATE 
      ,'SCr' as LAB_NAME
      ,l.RESULT_NUM
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) - p.INDEX_DATE as DAYS_SINCE_ENROLL
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
       and (UPPER(l.RESULT_UNIT) = 'MG/DL' or UPPER(l.RESULT_UNIT) = 'MG') /*there are variations of common units*/
       and l.SPECIMEN_SOURCE <> 'URINE' /*only serum creatinine*/
       and l.RESULT_NUM > 0 /*value 0 could exist*/
      )
union all
-- Urine Protein Creatinine ratio
select p.PATID
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) as LAB_DATE 
      ,'UProtCrRatio' as LAB_NAME
      ,l.RESULT_NUM
      ,NVL(l.SPECIMEN_DATE,l.LAB_ORDER_DATE) - p.INDEX_DATE as LAB_DAYS_SINCE_ENROLL
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
      )
;

/*baseline medical history/condition table: 1 patient-condition per row*/
create table BL_COND as
-- history of coronary artery disease
select  dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,'CAD' as CONDITION
      ,dx.DX_DATE as CONDITION_DATE
      ,(dx.DX_DATE - p.INDEX_DATE) as DAYS_SINCE_ENROLL
from pat_incld p
join DIAGNOSIS dx on p.PATID = dx.PATID
where (dx.DX_TYPE = '10' and
       (dx.DX like 'I61%' or
        dx.DX like 'I63%' )) 
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
-- Coronary revascularization
select px.PATID
      ,'PX' as IDENTIFIER_TYPE
      ,'CAD' as CONDITION
      ,px.PX_DATE as CONDITION_DATE
      ,(px.PX_DATE - p.INDEX_DATE) as DAYS_SINCE_ENROLL
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
      ,(dx.DX_DATE - p.INDEX_DATE) as DAYS_SINCE_ENROLL
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
      ,(dx.DX_DATE - p.INDEX_DATE) as DAYS_SINCE_ENROLL
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
      ,NVL(lab.SPECIMEN_DATE,lab.LAB_ORDER_DATE) - p.INDEX_DATE as DAYS_SINCE_ENROLL
from pat_incld p
join LAB_RESULT_CM lab on p.PATID = lab.PATID
where ( 
       /*--LOINC code set*/
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
         ) and
       lab.RESULT_NUM < 60
      )
union all
-- history of dyslipidemia
select dx.PATID
      ,'DX' as IDENTIFIER_TYPE
      ,'Dyslipidemia' as CONDITION
      ,dx.DX_DATE as CONDITION_DATE
      ,(dx.DX_DATE - p.INDEX_DATE) as DAYS_SINCE_ENROLL
from pat_incld p
join DIAGNOSIS dx on p.PATID = dx.PATID
where (dx.DX_TYPE = '10' and
       (dx.DX like 'E78.5%' )) 
      or 
      (dx.DX_TYPE = '09' and
       (dx.DX like '272.4%'))
;

/*stage the supplement concept_set file ConceptSet_Med_AntiHTN.csv
 source: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7068459/
*/
select * from CONCEPTSET_MED_ANTIHTN;

create table BL_MED as
select p.PATID
      ,m.RX_ORDER_DATE
      ,m.RX_START_DATE
      ,m.RX_END_DATE
      ,cs.DRUG_CLASS
      ,(m.RX_START_DATE - p.INDEX_DATE) as START_DAYS_SINCE_ENROLL
from pat_incld p
join PRESCRIBING m on m.PATID = p.PATID
join CONCEPTSET_MED_ANTIHTN cs on m.RXNORM_CUI = cs.RXCUI 
where m.RX_ORDER_DATE <= p.INDEX_DATE
;



