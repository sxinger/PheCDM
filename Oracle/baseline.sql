/* This script is to collect baseline clinical characteristics
   from CDM tables needed for data analysis
*/

/*Assumption: the prep.sql has been run with */

create table BL_DEMO as 
select 

;

create table BL_VITAL as
;

create table BL_COND as
;

create table BL_LAB as
select PATID
      ,NVL(SPECIMEN_DATE,LAB_ORDER_DATE) as LAB_DATE 
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
      ,NVL(SPECIMEN_DATE,LAB_ORDER_DATE) as LAB_DATE 
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
      ,NVL(SPECIMEN_DATE,LAB_ORDER_DATE) as LAB_DATE 
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
;

create table BL_MED as
;



