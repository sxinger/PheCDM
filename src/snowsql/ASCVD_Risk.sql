/******************************************************************************************
This table is to collect clinical observable values for calculating the Atherosclerotic 
Cardiovascular Disease (ASCVD) risk score. All risk calculators require the following 
factors: 
- Race
- Age
- Gender
- BMI
- SBP
- Smoking Status
- Total Cholesterol
- LDL Cholesterol
- HDL Cholesterol
- History of Diabetes --- T2DM.sql (DM_event)
- Treatment With Statin

For efficiency, it is recommended to perform computational 
phenotyping on a smaller cut of needed CDM tables only relevant to the 
eligible patient cohort. The study-specific CDM tables are usually 
saved in a separate Study Schema (e.g. VCCC_SCHEMA) preserving CDM relational database structure.
*************************************************************************************************/

/*setup environment*/
use role "ANALYTICS";
use warehouse ANALYTICS_WH;
use database ANALYTICSDB;
use schema VCCC_SCHEMA;

/* LOINC code set reference for Total, LDL, HDL Cholestrol:
  -- https://phekb.org/sites/phenotype/files/FH_eAlgorithm_Pseudocode_FullText_2016_1_3.pdf
*/
create or replace table ASCVD_Risk_Chole as
with All_Chole as (
select PATID
      ,NVL(SPECIMEN_DATE::date,LAB_ORDER_DATE::date) as LAB_DATE 
      ,'TC' as LAB_NAME
      ,RESULT_NUM
from LAB_RESULT_CM
where ( 
       /*--LOINC code set*/
       LAB_LOINC in ( 
          '2093-3'
         ,'48620-9'
         ,'35200-5'
         ,'14647-2'
         )
       and UPPER(RESULT_UNIT) = 'MG/DL'
      ) 
union all
select PATID
      ,NVL(SPECIMEN_DATE::date,LAB_ORDER_DATE::date) as LAB_DATE 
      ,'LDL-C' as LAB_NAME
      ,RESULT_NUM
from LAB_RESULT_CM
where ( 
       /*--LOINC code set*/
       LAB_LOINC in ( 
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
       and UPPER(RESULT_UNIT) = 'MG/DL'
      )
union all
select PATID
      ,NVL(SPECIMEN_DATE::date,LAB_ORDER_DATE::date) as LAB_DATE 
      ,'HDL-C' as LAB_NAME
      ,RESULT_NUM
from LAB_RESULT_CM
where ( 
       /*--LOINC code set*/
       LAB_LOINC in ( 
          '2085-9'
         ,'49130-8'
         ,'35197-3'
         ,'12771-2'
         ,'12772-0'
         ,'18263-4'
         ,'27340-9'
         ,'14646-4'
         )
       and UPPER(RESULT_UNIT) = 'MG/DL'
      )
)
select * from (
  select PATID
        ,LAB_DATE
        ,LAB_NAME
        ,RESULT_NUM
  from All_Chole
  )
pivot (
  avg(RESULT_NUM) for LAB_NAME in ('TC','LDL-C','HDL-C')
  ) as p(PATID, LAB_DATE, TC, LDL_C, HDL_C)
order by PATID, LAB_DATE
;

/*the most plausible BMI*/
create or replace table ASCVD_Risk_BMI as
with bmi_closest as (
  select c.PATID
        ,c.LAB_DATE
        ,NVL(least(v.ORIGINAL_BMI,150),least(round(v.WT/(v.HT*v.HT)*703),150)) as BMI
        ,v.MEASURE_DATE::date as BMI_DATE
        ,row_number() over (partition by c.PATID,c.LAB_DATE order by abs(c.LAB_DATE::date-v.MEASURE_DATE::date)) rn
  from ASCVD_Risk_Chole c
  join VITAL v
  on c.PATID = v.PATID and 
     (v.ORIGINAL_BMI is not null or 
      (v.WT is not null and v.HT is not null))
)
select PATID
      ,LAB_DATE
      ,BMI
      ,BMI_DATE
from bmi_closest
where rn = 1
;

/*the most plausible smoking status*/
create or replace table ASCVD_Risk_Smoker as
with smoke_closest as (
  select c.PATID
        ,c.LAB_DATE
        ,case when v.SMOKING in ('01','02','03','05','07','08') or v.TOBACCO in ('01','03','04') then 1 
              else 0
         end as SMOKER
        ,v.MEASURE_DATE::date as SMOKER_DATE
        ,row_number() over (partition by c.PATID,c.LAB_DATE order by abs(c.LAB_DATE::date-v.MEASURE_DATE::date)) rn
  from ASCVD_Risk_Chole c
  join VITAL v
  on c.PATID = v.PATID
)
select PATID
      ,LAB_DATE
      ,SMOKER
      ,SMOKER_DATE
from smoke_closest
where rn = 1
;

create or replace table ASCVD_Risk_TRT as
with SBP_Statin as (
  select p.PATID
        ,v.SYSTOLIC as SBP
        ,case when v.MEASURE_DATE<=p.RX_ORDER_DATE then 'Before'
              else 'After'
         end as SBP_Bef_Aft
        ,p.RX_ORDER_DATE::date as RX_ORDER_DATE
        ,row_number() over (partition by p.PATID, (case when v.MEASURE_DATE <= p.RX_ORDER_DATE then 'Before' else 'After' end) order by abs(p.RX_ORDER_DATE::date-v.MEASURE_DATE::date)) rn
  from PRESCRIBING p
  join VITAL v on p.PATID = v.PATID
  where UPPER(p.RAW_RX_MED_NAME) like UPPER('%Atorvastatin%') or
        UPPER(p.RAW_RX_MED_NAME) like UPPER('%Fluvastatin%') or
        UPPER(p.RAW_RX_MED_NAME) like UPPER('%Lovastatin%') or
        UPPER(p.RAW_RX_MED_NAME) like UPPER('%Pitavastatin%') or
        UPPER(p.RAW_RX_MED_NAME) like UPPER('%Pravastatin%') or
        UPPER(p.RAW_RX_MED_NAME) like UPPER('%Rosuvastatin%') or
        UPPER(p.RAW_RX_MED_NAME) like UPPER('%Simvastatin%') or
        p.RXNORM_CUI in (
           '6472','36567','41127','42463','83367','197903','197904'
          ,'197905','198211','200345','259255','312961','314231'
          ,'476345','476350','597987','617310','617311','617312'
          ,'859419','859424','859747','859751','904457','904458'
          ,'904467','904475','2535750'
        )
  )
select * from (
  select PATID
        ,RX_ORDER_DATE
        ,SBP
        ,SBP_Bef_Aft
  from SBP_Statin
  where rn = 1
  )
pivot (
  avg(SBP) for SBP_Bef_Aft in ('Before','After')
) as p(PATID, RX_ORDER_DATE, SBP_Bef, SBP_Aft)
order by PATID, RX_ORDER_DATE
;

/*Combine all clinical observations required by ASCVD risk calculator*/
create or replace table ASCVD_Risk_Calc as
select c.PATID
      ,d.SEX
      ,Year(c.LAB_DATE::date)-Year(d.BIRTH_DATE::date) AGE
      ,d.RACE
      ,c.TC
      ,c.LDL_C
      ,c.HDL_C
      ,b.BMI
      ,s.SMOKER
      ,case when dm.DM_ONSET < c.LAB_DATE then 1 
            else 0
       end as DIABETES
      ,case when t.RX_ORDER_DATE < c.LAB_DATE then 1
            else 0
       end as TREATED
      ,case when t.RX_ORDER_DATE < c.LAB_DATE then t.SBP_Aft
            else t.SBP_Bef
       end as SBP
from ASCVD_Risk_Chole c
join DEMOGRAPHIC d on c.PATID = d.PATID
join ASCVD_Risk_BMI b on c.PATID = b.PATID and c.LAB_DATE = b.LAB_DATE
join ASCVD_Risk_Smoker s on c.PATID = s.PATID and c.LAB_DATE = s.LAB_DATE
join DM_Event dm on c.PATID = dm.PATID
join ASCVD_Risk_TRT t on c.PATID = t.PATID
;
