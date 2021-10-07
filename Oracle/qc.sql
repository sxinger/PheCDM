/* This script is to collect potential QC checks against known EPIC source tables. 
   Not required to run
*/

create table PAT_INSURANCE as
select distinct
       pat.PATID
      ,mem.MEM_EFF_FROM_DATE
      ,mem.MEM_EFF_TO_DATE
      ,epm.PAYOR_NAME as RAW_PAYER_NAME
      ,coalesce(fc.financial_class_name,zcfv.name) as RAW_PAYER_TYPE
from pat_incld pat 
join &&nightheron_schema.patient_mapping pm on pat.PATID = pm.PATIENT_NUM and pm.PATIENT_IDE_SOURCE like 'Epic@%' -- map CDM de-ID to EPIC PAT_ID
join &&clarity_schema.coverage_mem_list mem on mem.pat_id=pm.patient_ide
join &&clarity_schema.coverage cvg on cvg.coverage_id=mem.coverage_id -- 
join &&clarity_schema.clarity_epm p on p.payor_id=cvg.payor_id
left join &&clarity_schema.clarity_fc fc on p.FINANCIAL_CLASS =fc.FINANCIAL_CLASS
left join &&clarity_schema.zc_financial_class zcfv on p.financial_class = zcfv.FINANCIAL_CLASS
where coalesce(fc.financial_class_name,zcfv.name) is not null and 
      and mem.MEM_EFF_FROM_DATE is not null /*null exists*/
      and mem.MEM_COVERED_YN = 'Y' /*confirm converage*/
;