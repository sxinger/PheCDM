/* BP Control for elder patients (>=65 yo) 
   Comorbidity: Dementia or Alzheimer
   PI: Aditi Gupta, Jeff Burn
   Grant: R66-R31 
   Data extract: 04/2020, electric
*/

alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS';

/******************************************************/
/* Inclusion criteria                                 */
/******************************************************/
whenever sqlerror continue;
/*# of Patients seen in Primary Care - 1 pat-visit/row*/
drop table PC_pat_dt purge;
create table PC_pat_dt as
with pc_cd as (
select distinct concept_cd, name_char, 'family medicine' department
from blueherondata.concept_dimension
where concept_path like ('%Visit Details\ServiceDepartments\Outpatient Visits\Family Medicine%')
union all
select distinct concept_cd, name_char, 'general internal medicine' department
from blueherondata.concept_dimension
where concept_path like ('%Visit Details\ServiceDepartments\Outpatient Visits\General Internal Medicine%')
union all
select distinct concept_cd, name_char, 'geriatric medicine' department
from blueherondata.concept_dimension
where concept_path like ('%Visit Details\ServiceDepartments\Outpatient Visits\Geriatric Medicine%')
union all
select distinct concept_cd, name_char, 'internal medicine' department
from blueherondata.concept_dimension
where concept_path like ('%Visit Details\ServiceDepartments\Outpatient Visits\Internal Medicine%')
)
select distinct
       obs.patient_num
      ,obs.encounter_num
      ,pc_cd.department
      ,pc_cd.name_char clinic_name
      ,obs.start_date
      ,dense_rank() over (partition by obs.patient_num  order by obs.start_date) rn
from blueherondata.observation_fact obs
join pc_cd
on obs.concept_cd = pc_cd.concept_cd
--where obs.start_date >= Date '2019-01-01'
;
/*700 sec*/
create index PC_pat_dt_PAT_IDX on PC_pat_dt(patient_num);

--demographic table, 1 pat-vis/row
drop table PC_pat65up_demo purge;
create table PC_pat65up_demo as
with my_chart as (
select patient_num, min(start_date) mychart_start
from blueherondata.observation_fact
where concept_cd in ('MYC_ACCESSED:1','MYC_RECV_EMAIL:Y')
group by patient_num
)
    ,ethnicity as (
select patient_num, 
       case when concept_cd like 'DEM|ETHNICITY:his%' then 'hispanic'
            when concept_cd like 'DEM|ETHNICITY:non-his%' then 'non-hispanic'
            else 'NI'
       end as ethnicity_cd
from blueherondata.observation_fact
where concept_cd like 'DEM|ETHNICITY:%'
)
select distinct
       init.patient_num
      ,init.encounter_num
      ,pd.birth_date
      ,round((init.start_date-pd.birth_date)/365.25) age_at_vis
      ,pd.sex_cd
      ,pd.age_in_years_num
      ,floor((pd.age_in_years_num-65)/5)*5+65 age_grp
      ,pd.language_cd
      ,case when pd.race_cd in ('@','declined') then 'unknown' else pd.race_cd end as race_cd
      ,eth.ethnicity_cd
      ,my_chart.mychart_start
from PC_pat_dt init
join blueherondata.patient_dimension pd
on init.patient_num = pd.patient_num
left join my_chart
on init.patient_num = my_chart.patient_num
left join ethnicity eth
on init.patient_num = eth.patient_num
where pd.age_in_years_num >= 65 and pd.death_date is null
      and init.start_date >= Date '2019-01-01'
;

--create index PC_pat65up_demo_PAT_IDX on PC_pat65up_demo(patient_num);
--create index PC_pat65up_demo_ENC_IDX on PC_pat65up_demo(encounter_num);


/*# of Patients with indications of HTN (BP or Diagnosis)*/
-- outpatient bp, 1 pat-vis/row
drop table PC_pat65up_bp purge;
create table PC_pat65up_bp as
--with pat_sbp as (
select obs.patient_num
      ,obs.nval_num SBP
      ,obs.start_date
      ,obs.instance_num
      ,dense_rank() over (partition by obs.patient_num order by obs.start_date desc) bp_ord_desc
from blueherondata.observation_fact obs
where obs.concept_cd = 'KUH|PAT_ENC:BP_SYSTOLIC' and 
      exists (select 1 from PC_pat65up_demo 
              where PC_pat65up_demo.patient_num = obs.patient_num and
                    PC_pat65up_demo.encounter_num = obs.encounter_num) 
--)
--   ,pat_dbp as (
--select obs.patient_num
--      ,obs.nval_num DBP
--      ,obs.start_date
--      ,obs.instance_num
--from blueherondata.observation_fact obs
--where obs.concept_cd = 'KUH|PAT_ENC:BP_DIASTOLIC' and 
--      exists (select 1 from PC_pat65_demo 
--              where PC_pat65_demo.patient_num = obs.patient_num)
--)
--select sbp.patient_num
--      ,sbp.SBP
--      ,dbp.DBP
--      ,sbp.start_date BP_date
--      ,dense_rank() over (partition by sbp.patient_num order by sbp.start_date desc) bp_ord_desc
--from pat_sbp sbp
--left join pat_dbp dbp
--on sbp.patient_num = dbp.patient_num and sbp.instance_num = dbp.instance_num
;

create index PC_pat65up_bp_PAT_IDX on PC_pat65up_bp(patient_num);


drop table PC_pat65up_htn_dx purge;
create table PC_pat65up_htn_dx as 
with htn_cd as (
select distinct concept_cd, name_char
from blueherondata.concept_dimension 
where concept_path like ('%\ICD9%\401%') or   -- htn
      concept_path like ('%\ICD9%\402%') or
      concept_path like ('%\ICD9%\403%') or
      concept_path like ('%\ICD9%\404%') or
      concept_path like ('%\ICD9%\405%') or
      concept_path like ('%\ICD10%\I10%') or
      concept_path like ('%\ICD10%\I11%') or
      concept_path like ('%\ICD10%\I12%') or
      concept_path like ('%\ICD10%\I13%') or
      concept_path like ('%\ICD10%\R03%')
)
select obs.patient_num
      ,obs.concept_cd
      ,obs.start_date
      ,obs.modifier_cd
      ,'dx' identifier
from blueherondata.observation_fact obs
where exists (select 1 from htn_cd
              where obs.concept_cd = htn_cd.concept_cd) and 
      exists (select 1 from PC_pat65up_demo 
              where PC_pat65up_demo.patient_num = obs.patient_num) 
;

--create index PC_pat65_htn_dx_PAT_IDX on PC_pat65_htn_dx(patient_num);

/*define elevated blood pressure events*/
drop table PC_pat65up_htn;
create table PC_pat65up_htn (
 patient_num varchar2(80),
 event1_date date,
 event2_date date,
 htn_type varchar2(80)
);

--SBP >140 at most-recent visit AND documented history of hypertension
insert into PC_pat65up_htn
select sbp.patient_num
      ,sbp.start_date 
      ,dx.start_date 
      ,'sbp_dx'
from PC_pat65up_bp sbp
join PC_pat65up_htn_dx dx
on sbp.patient_num = dx.patient_num
   and sbp.bp_ord_desc = 1 and sbp.SBP > 140   -- most recent SBP record > 140
   and dx.start_date < sbp.start_date          -- HTN dx before SBP
;
--SBP > 140 at most-recent visit AND at another visit in last 18 months
insert into PC_pat65up_htn
select sbp1.patient_num
      ,sbp1.start_date
      ,sbp2.start_date 
      ,'sbp_pair'
from PC_pat65up_bp sbp1
join PC_pat65up_bp sbp2
on sbp1.patient_num = sbp2.patient_num
   and sbp1.bp_ord_desc = 1
   and sbp1.sbp > 140 and sbp2.sbp > 140                      -- two SBP records > 140
   and sbp1.start_date - sbp2.start_date between 1 and 18*30  -- within 18 months
;
-- SBP >160 at most-recent visit
insert into PC_pat65up_htn
select patient_num
      ,null
      ,start_date
      ,'sbp_single_high'
from PC_pat65up_bp
where bp_ord_desc = 1 and sbp > 160  -- most recent SBP record > 160
;

select * from PC_pat65up_htn;

select count(distinct patient_num) from PC_pat65up_htn
where event2_date >= Date '2019-01-01';
--3,824

/******************************************************/
/* Exclusion criteria                                 */
/******************************************************/
drop table excld_esrd_rrt purge;
create table excld_esrd_rrt as
with esrd_rrt_dxid as (
--ESRD
select distinct concept_cd, name_char
from blueherondata.concept_dimension
where concept_path like ('%\ICD9%\585.6%')
union all
--Dialysis
select distinct concept_cd, name_char
from blueherondata.concept_dimension
where concept_path like ('%\ICD10%\N18.6%')
union all
select distinct concept_cd, name_char
from blueherondata.concept_dimension
where concept_path like ('%\ICD9%\V45.1%') or
      concept_path like ('%\ICD9%\V56%') or
      concept_path like ('%\ICD9%\V42.0%')
union all
select distinct concept_cd, name_char
from blueherondata.concept_dimension
where concept_path like ('%\ICD10%\Z49%') or 
      concept_path like ('%\ICD10%\Z99.2%') or
      concept_path like ('%\ICD10%\Z94.0%')
union all
select distinct concept_cd, name_char
from blueherondata.concept_dimension
where concept_cd in ('CPT:99512','CPT:90970','CPT:90989',
                     'CPT:90920','CPT:90921','CPT:90924','CPT:90925',
                     'CPT:90935','CPT:90937','CPT:90945','CPT:90947',
                     'CPT:90960','CPT:90961','CPT:90962','CPT:90966',
                     'CPT:90993','CPT:90999',
                     'ICD10:03130JD','ICD10:03140JD','ICD10:03150JD',
                     'ICD10:03160JD','ICD10:03170JD','ICD10:03180JD',
                     'ICD10:031A0JF','ICD10:031B0JF','ICD10:031C0JF','ICD10:03190JF',
                     'ICD9:39.93','ICD9:39.95','ICD9:54.98'
                     )
)
select /*+ leading(cd,obs,pat)*/
       distinct obs.patient_num
from blueherondata.observation_fact obs
join esrd_rrt_dxid cd
on obs.concept_cd = cd.concept_cd
where exists (select 1 from PC_pat65up_htn pat
              where pat.patient_num = obs.patient_num)
;
-- 500 sec


/************************************************/
/* Final Cohort                                 */
/************************************************/
drop table PC_pat65up_htn_fin purge;
create table PC_pat65up_htn_fin as
select incld.patient_num
      ,max(incld.event1_date) htn_date
from PC_pat65up_htn incld
where not exists (select 1 from excld_esrd_rrt excld
                  where excld.patient_num = incld.patient_num)
group by incld.patient_num
;

create index PC_pat65up_htn_fin_PAT_IDX on PC_pat65up_htn_fin(patient_num);


--drop table PC_pat65_htn_fin purge;
--create table PC_pat65_htn_fin as
--with htn_date as (
--select incld.patient_num
--      ,min(incld.event1_date) htn_date
--from PC_pat65_htn incld
--where not exists (select 1 from excld_esrd_rrt excld
--                  where excld.patient_num = incld.patient_num)
--group by incld.patient_num
--)
--select demo.*, htn_date.htn_date
--from PC_pat65_demo demo
--join htn_date
--on demo.patient_num = htn_date.patient_num
--;


/************************************************/
/* Collect Commorbidities                       */
/************************************************/
drop table PC_htn_comorb;
create table PC_htn_comorb (
   patient_num varchar (20),
   start_date date,
   comorb varchar(20)
);

insert into PC_htn_comorb
with dm_cd as (
select distinct concept_cd, name_char
from blueherondata.concept_dimension 
where concept_path like ('%\ICD9%\250%') or   -- dm
      concept_path like ('%\ICD10%\E08%') or
      concept_path like ('%\ICD10%\E09%') or
      concept_path like ('%\ICD10%\E10%') or
      concept_path like ('%\ICD10%\E11%') or
      concept_path like ('%\ICD10%\E12%') or
      concept_path like ('%\ICD10%\E13%')
)
select distinct
       obs.patient_num
      ,obs.start_date
      ,'DM' comorb
from blueherondata.observation_fact obs
where exists (select 1 from dm_cd
              where obs.concept_cd = dm_cd.concept_cd) and 
      exists (select 1 from PC_pat65up_htn_fin 
              where PC_pat65up_htn_fin.patient_num = obs.patient_num and 
                    PC_pat65up_htn_fin.htn_date > obs.start_date)
;

insert into PC_htn_comorb
with ad_cd as (
select distinct concept_cd, name_char, 'dementia' concept_grp
from blueherondata.concept_dimension 
where concept_path like ('%\ICD9%\290%') or   -- dementia
      concept_path like ('%\ICD10%\F02%') or
      concept_path like ('%\ICD10%\F03%')
union all
select distinct concept_cd, name_char, 'AD' concept_grp
from blueherondata.concept_dimension 
where concept_path like ('%\ICD9%\331.0%') or   -- alzheimer
      concept_path like ('%\ICD10%\G30%')
)
select distinct
       obs.patient_num
      ,obs.start_date
      ,'AD' comorb
from blueherondata.observation_fact obs
where exists (select 1 from ad_cd
              where obs.concept_cd = ad_cd.concept_cd) and 
      exists (select 1 from PC_pat65up_htn_fin 
              where PC_pat65up_htn_fin.patient_num = obs.patient_num and 
                    PC_pat65up_htn_fin.htn_date > obs.start_date)
;


/********************************************/
/* quantify "Active" patients?
/********************************************/
select count(distinct patient_num) from PC_pat65up_htn_fin; 


create or replace view pc_vis_consist as
select vis.patient_num, count(distinct extract(year from vis.start_date)) multi_vis_year
from PC_pat_dt vis
where exists (select 1 from PC_pat65up_htn_fin elig where vis.patient_num = elig.patient_num) and
      not exists (select 1 from PC_htn_comorb comorb where vis.patient_num = comorb.patient_num and comorb.comorb='AD')
group by vis.patient_num
;

select count(distinct patient_num) from pc_vis_consist
where multi_vis_year >= 2;


create or replace view pc_vis_consist_dept as
select * from (
 select vis.patient_num, vis.department, count(distinct extract(year from vis.start_date)) multi_vis_year
 from PC_pat_dt vis
 where exists (select 1 from PC_pat65up_htn_fin elig where vis.patient_num = elig.patient_num)
 group by vis.patient_num, vis.department)
pivot (max(multi_vis_year) for department in ('family medicine' family,
                                              'general internal medicine' general_internal,
                                              'geriatric medicine' geriatric,
                                              'internal medicine' internal
                                              )
)
where coalesce(family, general_internal,geriatric,internal) is not null
;

select 'any' department, multi_vis_year vis_time, count(distinct patient_num) pat_cnt from pc_vis_consist group by multi_vis_year
union all
select 'family', family, count(distinct patient_num) pat_cnt from pc_vis_consist_dept group by family
union all
select 'general_internal', general_internal, count(distinct patient_num) from pc_vis_consist_dept group by general_internal
union all
select 'geriatric', geriatric, count(distinct patient_num) from pc_vis_consist_dept group by geriatric
union all
select 'internal', internal, count(distinct patient_num) from pc_vis_consist_dept group by internal
;



create or replace view pc_vis_freq as
select patient_num, vis_year, count(distinct encounter_num) enc_cnt
from (
 select vis.patient_num, extract(year from vis.start_date) vis_year, vis.encounter_num
 from PC_pat_dt vis
 where exists (select 1 from PC_pat65up_htn_fin elig where vis.patient_num = elig.patient_num)
)
group by patient_num, vis_year
;

select vis_year, enc_cnt, count(distinct patient_num) pat_cnt
from pc_vis_freq
group by vis_year, enc_cnt
order by vis_year, enc_cnt
;

create or replace view pc_vis_intense as
with vis_lag as (
select distinct a.patient_num, a.encounter_num,(b.start_date-a.start_date) vis_lag
from PC_pat_dt a
join PC_pat_dt b on a.patient_num = b.patient_num and a.rn+1 = b.rn
)
select vis.patient_num, count(distinct vis.encounter_num) vis_cnt, 
       round(median(vis.vis_lag)) lag_med, 
       round(avg(vis.vis_lag)) lag_avg, 
       round(stddev(vis.vis_lag)) lag_sd
from vis_lag vis
where exists (select 1 from PC_pat65up_htn_fin elig where vis.patient_num = elig.patient_num)
group by vis.patient_num
having count(distinct vis.encounter_num) > 2
order by lag_sd asc
;

select vis_cnt, lag_med, count(distinct patient_num) pat_cnt 
from pc_vis_intense
group by vis_cnt, lag_med
order by vis_cnt, lag_med
;


/********************************************/
/* Collect Statistics                       */
/********************************************/
drop table stats_tbl;
create table stats_tbl (
    cnt_type varchar(40),
    pat_cnt integer
)
;
insert into stats_tbl
select 'initial', case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end from PC_pat65up_demo;

insert into stats_tbl
select 'elevated BP', case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end from PC_pat65up_htn;

insert into stats_tbl
select 'excld:ESRD', case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end from excld_esrd_rrt;

insert into stats_tbl
select 'final', case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end from PC_pat65up_htn_fin;

insert into stats_tbl
select 'my-chart enroll', case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end from PC_pat65up_htn_fin fin
where exists (select 1 from PC_pat65up_demo demo
              where demo.patient_num = fin.patient_num and demo.mychart_start is not null);
              
insert into stats_tbl
select comorb, case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end  from PC_htn_comorb group by comorb;

insert into stats_tbl
select 'AD-DM', case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end  from PC_htn_comorb ad
where ad.comorb = 'AD' and
      exists (select 1 from PC_htn_comorb dm where dm.patient_num = ad.patient_num and dm.comorb='DM');

insert into stats_tbl
with fin_demo as (
select demo.* from PC_pat65up_demo demo
where exists (select 1 from PC_pat65up_htn_fin fin where fin.patient_num = demo.patient_num)
)
select ('sex:' || sex_cd), case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end  from fin_demo group by sex_cd
union
select ('race:' || race_cd), case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end  from fin_demo group by race_cd
union 
select ('hispanic:' || ethnicity_cd), case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end  from fin_demo group by ethnicity_cd
union
select ('age_num: mean=' || to_char(round(avg(age_in_years_num)))), stddev(round(age_in_years_num)) from fin_demo
union
select ('agegrp:' || age_grp), case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end  from fin_demo group by age_grp
;
commit;

/*eyeball the results*/
select * from stats_tbl;

/***************************************************************************************/
/* Load summary counts into software on Green-Heron for downstream analysis or plotting*/
/***************************************************************************************/