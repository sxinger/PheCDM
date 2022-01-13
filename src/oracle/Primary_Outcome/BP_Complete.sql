/* This script is to collect and integrate BP information 
   from multiple sources and provide a comprehensive view
   See "BP Integration Strategy.docx" for more details
*/
create table BP_Complete as
-- SBP and DBP from VITAL table
select * from
(select p.PATID
       ,v.ENCOUNTERID
       ,v.SYSTOLIC
       ,v.DIASTOLIC
       ,v.MEASURE_DATE
       ,v.MEASURE_TIME
       ,round(v.MEASURE_DATE - p.INDEX_DATE) as DAYS_SINCE_ENROLL
 from pat_incld p
 join VITAL v on v.PATID = p.PATID 
 where v.SYSTOLIC is not null
)
unpivot (
   VITAL_VAL for VITAL_TYPE in (SYSTOPIC, DIASTOLIC)
)
union all
-- SBP from OBS_CLIN table
select p.PATID
      ,oc.ENCOUNTERID
      ,'SYSTOLIC' as VITAL_TYPE
      ,oc.OBSCLIN_RESULT as VITAL_VAL
      ,oc.OBSCLIN_RESULT_UNIT as VITAL_UNIT
      ,oc.OBSCLIN_START_DATE 
      ,oc.OBSCLIN_START_TIME
      ,round(v.OBSCLIN_START_DATE  - p.INDEX_DATE) as DAYS_SINCE_ENROLL
from pat_incld p
join OBS_CLIN oc on oc.PATID = p.PATID and
     oc.OBSCLIN_TYPE = 'LC' and 
     oc.OBSCLIN_CODE in ( '8460-8' --standing
                         ,'8459-0' --sitting
                         ,'8461-6' --supine
                         ,'8479-8' --palpation
                         ,'8480-6' --general
                        )
union all
-- SBP from OBS_CLIN table
select p.PATID
      ,oc.ENCOUNTERID
      ,'DIASTOLIC' as VITAL_TYPE
      ,oc.OBSCLIN_RESULT as VITAL_VAL
      ,oc.OBSCLIN_RESULT_UNIT as VITAL_UNIT
      ,oc.OBSCLIN_START_DATE 
      ,oc.OBSCLIN_START_TIME
      ,round(oc.OBSCLIN_START_DATE  - p.INDEX_DATE) as DAYS_SINCE_ENROLL
from pat_incld p
join OBS_CLIN oc on oc.PATID = p.PATID and
     oc.OBSCLIN_TYPE = 'LC' and 
     oc.OBSCLIN_CODE in ( '8454-1' --standing
                         ,'8453-3' --sitting
                         ,'8455-8' --supine
                         ,'8462-4' --general
                        )
;

