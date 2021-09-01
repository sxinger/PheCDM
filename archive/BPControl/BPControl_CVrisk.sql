/* BP Control for adult patients (18 to 65)
   Comorbidity: CVD
   PI: Aditi Gupta 
   Data extract: 11/24/2020, deer creek
*/

alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS';

/******************************************************/
/* Inclusion criteria                                 */
/******************************************************/
/*
1.	Age >18
2.	Active patient in participating primary care clinic 
3.	Access to compatible “smartphone” or device (i.e., Android, Kindle or Apple with internet connectivity)
4.	Elevated BP as defined by 
    SBP >140 at current visit AND documented history of hypertension            
    OR
    SBP > 140 at current visit and at another visit in last 18 months 
    OR
    SBP >160 at current visit 
    (no DBP inclusion criteria) 
*/

/*************************************************/
/*Patients seen in Primary Care - 1 pat-visit/row*/
/*************************************************/
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
;
/*2600 sec*/
create index PC_pat_dt_PAT_IDX on PC_pat_dt(patient_num);


/*collect master demographic table for patients of 18-65, 1 pat-vis/row*/
drop table PC_pat18to65_demo purge;
create table PC_pat18to65_demo as
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
      ,pd.age_in_years_num --current age
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
where pd.age_in_years_num between 18 and 65 
      and pd.death_date is null                -- still alive
      and init.start_date >= Date '2019-01-01' -- recent year
;
/*30 seconds*/

select * from PC_pat18to65_demo;

--create index PC_pat18to65_demo_PAT_IDX on PC_pat18to65_demo(patient_num);
--create index PC_pat18to65_demo_ENC_IDX on PC_pat18to65_demo(encounter_num);

/*********************************************************/
/*Patients with indications of HTN (BP or Diagnosis)*/
/*********************************************************/
-- outpatient bp, 1 pat-vis/row
drop table PC_pat18to65_bp purge;
create table PC_pat18to65_bp as
--with pat_sbp as (
select obs.patient_num
      ,obs.nval_num SBP
      ,obs.start_date
      ,obs.instance_num
      ,dense_rank() over (partition by obs.patient_num order by obs.start_date desc) bp_ord_desc
from blueherondata.observation_fact obs
where obs.concept_cd = 'KUH|PAT_ENC:BP_SYSTOLIC' and 
      exists (select 1 from PC_pat18to65_demo 
              where PC_pat18to65_demo.patient_num = obs.patient_num and
                    PC_pat18to65_demo.encounter_num = obs.encounter_num) 
;
/*160 seconds*/

create index PC_pat18to65_bp_PAT_IDX on PC_pat18to65_bp(patient_num);

drop table PC_pat18to65_htn_dx purge;
create table PC_pat18to65_htn_dx as 
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
      exists (select 1 from PC_pat18to65_demo 
              where PC_pat18to65_demo.patient_num = obs.patient_num) 
;

--create index PC_pat18_htn_dx_PAT_IDX on PC_pat18_htn_dx(patient_num);

/*define elevated blood pressure events*/
drop table PC_pat18to65_htn;
create table PC_pat18to65_htn (
 patient_num varchar2(80),
 event1_date date,
 event2_date date,
 htn_type varchar2(80)
);

--SBP >140 at most-recent visit AND documented history of hypertension
insert into PC_pat18to65_htn
select sbp.patient_num
      ,sbp.start_date 
      ,dx.start_date 
      ,'sbp_dx'
from PC_pat18to65_bp sbp
join PC_pat18to65_htn_dx dx
on sbp.patient_num = dx.patient_num
   and sbp.bp_ord_desc = 1 and sbp.SBP > 140   -- most recent SBP record > 140
   and dx.start_date < sbp.start_date          -- HTN dx before SBP
;
--SBP > 140 at most-recent visit AND at another visit in last 18 months
insert into PC_pat18to65_htn
select sbp1.patient_num
      ,sbp1.start_date
      ,sbp2.start_date 
      ,'sbp_pair'
from PC_pat18to65_bp sbp1
join PC_pat18to65_bp sbp2
on sbp1.patient_num = sbp2.patient_num
   and sbp1.bp_ord_desc = 1
   and sbp1.sbp > 140 and sbp2.sbp > 140                      -- two SBP records > 140
   and sbp1.start_date - sbp2.start_date between 1 and 18*30  -- within 18 months
;
-- SBP >160 at most-recent visit
insert into PC_pat18to65_htn
select patient_num
      ,null
      ,start_date
      ,'sbp_single_high'
from PC_pat18to65_bp
where bp_ord_desc = 1 and sbp > 160  -- most recent SBP record > 160
;

select * from PC_pat18to65_htn;

select count(distinct patient_num) from PC_pat18to65_htn
where event2_date >= Date '2019-01-01';
-- 3,959

/******************************************************************************/
/*Increased cardiovascular risk defined as having one or more of the following*/
/******************************************************************************/
drop table PC_htn_CV_risk;
create table PC_htn_CV_risk (
   patient_num varchar (20),
   htn_date date,
   first_date date,
   last_date date,
   comorb varchar(20),
   comorb_sub varchar(20)
);


/*a. CKD (eGFR <60 ml/min/1.73 m2 or proteinuria)*/
insert into PC_htn_CV_risk
with ckd_cd as (
select distinct concept_cd, name_char
from blueherondata.concept_dimension 
where concept_path like ('%\ICD9%\585%') or
      concept_path like ('%\ICD10%\N18%')
)
select obs.patient_num
      ,htn.event2_date
      ,min(obs.start_date)
      ,max(obs.start_date)
      ,'CKD'
      ,'CKD_ICD'
from blueherondata.observation_fact obs
join PC_pat18to65_htn htn on htn.patient_num = obs.patient_num
where exists (select 1 from ckd_cd
              where obs.concept_cd = ckd_cd.concept_cd) and 
       htn.event2_date >= obs.start_date
group by obs.patient_num,htn.event2_date
;


insert into PC_htn_CV_risk
select obs.patient_num
      ,htn.event2_date
      ,min(obs.start_date)
      ,max(obs.start_date)
      ,'CKD'
      ,'CKD_eGFR'
from blueherondata.observation_fact obs
join PC_pat18to65_htn htn on htn.patient_num = obs.patient_num
where obs.concept_cd in ('KUH|COMPONENT_ID:191','KUH|COMPONENT_ID:200') and 
      obs.nval_num < 60 and
      htn.event2_date >= obs.start_date
group by obs.patient_num,htn.event2_date
;


insert into PC_htn_CV_risk
select obs.patient_num
      ,htn.event2_date
      ,min(obs.start_date)
      ,max(obs.start_date)
      ,'CKD'
      ,'CKD_ACR'
from blueherondata.observation_fact obs
join PC_pat18to65_htn htn on htn.patient_num = obs.patient_num
where obs.concept_cd in ( 'KUH|COMPONENT_ID:7165'
                         ,'LOINC:14959-1'
                         ,'KUH|COMPONENT_ID:7085'
                         ,'LOINC:2889-4'
                        ) and
      obs.nval_num >= 30 and
      htn.event2_date >= obs.start_date
group by obs.patient_num,htn.event2_date
;



/*b. Diabetes*/
insert into PC_htn_CV_risk
with dm_cd as (
select distinct concept_cd, name_char
from blueherondata.concept_dimension 
where concept_path like ('%\ICD9%\250%') or 
      concept_path like ('%\ICD10%\E08%') or
      concept_path like ('%\ICD10%\E09%') or
      concept_path like ('%\ICD10%\E10%') or
      concept_path like ('%\ICD10%\E11%') or
      concept_path like ('%\ICD10%\E12%') or
      concept_path like ('%\ICD10%\E13%')
)
select obs.patient_num
      ,htn.event2_date
      ,min(obs.start_date)
      ,max(obs.start_date)
      ,'DM'
      ,'DM_ICD'
from blueherondata.observation_fact obs
join PC_pat18to65_htn htn on htn.patient_num = obs.patient_num
where exists (select 1 from dm_cd
              where obs.concept_cd = dm_cd.concept_cd) and 
      htn.event2_date > obs.start_date
group by obs.patient_num,htn.event2_date
;


/*c. H/o smoking*/
insert into PC_htn_CV_risk
select obs.patient_num
      ,htn.event2_date 
      ,min(obs.start_date)
      ,max(obs.start_date)
      ,'SMOKING' comorb
      ,'SMOKING_USE'
from blueherondata.observation_fact obs
join PC_pat18to65_htn htn on htn.patient_num = obs.patient_num
where obs.concept_cd in ('KUMC|TOBACCO_USER:1',
                         'KUMC|SMOKING_TOB_USE:1',
                         'KUMC|SMOKING_TOB_USE:2',
                         'KUMC|SMOKING_TOB_USE:3',
                         'KUMC|SMOKING_TOB_USE:4',
                         'KUMC|SMOKING_TOB_USE:9',
                         'KUMC|SMOKING_TOB_USE:10'
                     )     and 
      htn.event2_date >= obs.start_date  
group by obs.patient_num, htn.event2_date 
;


insert into PC_htn_CV_risk
select obs.patient_num
      ,htn.event2_date
      ,min(obs.start_date)
      ,max(obs.start_date)
      ,'SMOKING'
      ,'SMOKING_PPD'
from blueherondata.observation_fact obs
join PC_pat18to65_htn htn on htn.patient_num = obs.patient_num
where obs.concept_cd =  'KUMC|PACK_PER_DAY' and 
      obs.nval_num > 0 and
      htn.event2_date >= obs.start_date
group by obs.patient_num, htn.event2_date
;


insert into PC_htn_CV_risk
select obs.patient_num
      ,htn.event2_date
      ,min(obs.start_date)
      ,max(obs.start_date)
      ,'SMOKING'
      ,'SMOKING_YEARS'
from blueherondata.observation_fact obs
join PC_pat18to65_htn htn on htn.patient_num = obs.patient_num
where obs.concept_cd =  'KUMC|TOBACCO_USED_YEARS'  and 
      obs.nval_num > 0 and
      htn.event2_date >= obs.start_date     
group by obs.patient_num, htn.event2_date
;


/*d. Non-diabetic patients with Framingham Risk Score estimating 10 year risk of CVD ?15% based on current SBP and laboratory data within past 24 months*/
-- ref: https://framinghamheartstudy.org/fhs-risk-functions/hard-coronary-heart-disease-10-year-risk/
--drop table Framingham_Mapping purge;
--create table Framingham_Mapping as



/*e. History of CVD or acute coronary syndrome defined as having one or more of the following
      i.	previous myocardial infarction (including non ST-elevation and ST-elevation MI) -- ICD
     ii.	unstable angina -- ICD
    iii.	percutaneous coronary intervention -- CPT
     iv.	coronary artery bypass grafting -- CPT
      v.	carotid endarterectomy, carotid stenting, peripheral artery disease with revascularization -- ICD, CPT
     vi.	at least a 50% diameter stenosis of a coronary, carotid, or lower extremity artery (??)
    vii.	abdominal aortic aneurysm ?5 cm (with or without repair) (??)
*/

insert into PC_htn_CV_risk
with cvd_cd as (
select distinct concept_cd, name_char
from blueherondata.concept_dimension 
where concept_path like ('%\ICD9%\410.%') or
      concept_path like ('%\ICD10%\%I21%') or
      concept_path like ('%\ICD10%\%I22%')
)
select obs.patient_num
      ,htn.event2_date
      ,min(obs.start_date)
      ,max(obs.start_date)
      ,'CVD_ACS'
      ,'CVD_ICD'
from blueherondata.observation_fact obs
join PC_pat18to65_htn htn on htn.patient_num = obs.patient_num
where exists (select 1 from cvd_cd
              where obs.concept_cd = cvd_cd.concept_cd) and 
      htn.event2_date > obs.start_date
group by obs.patient_num,htn.event2_date
;


insert into PC_htn_CV_risk
with cvd_cd as (
select distinct concept_cd, name_char
from blueherondata.concept_dimension 
where concept_path like ('%\ICD9%\411.1%') or
      concept_path like ('%\ICD10%\%I20.0%')
)
select obs.patient_num
      ,htn.event2_date
      ,min(obs.start_date)
      ,max(obs.start_date)
      ,'CVD_ACS'
      ,'ACS_ICD'
from blueherondata.observation_fact obs
join PC_pat18to65_htn htn on htn.patient_num = obs.patient_num
where exists (select 1 from cvd_cd
              where obs.concept_cd = cvd_cd.concept_cd) and 
      htn.event2_date > obs.start_date
group by obs.patient_num,htn.event2_date
;

insert into PC_htn_CV_risk
with cvd_cd as (
select distinct concept_cd, name_char
from blueherondata.concept_dimension 
where concept_path like ('%\ICD9%\443%') or
      concept_path like ('%\ICD10%\%I73%')
)
select obs.patient_num
      ,htn.event2_date
      ,min(obs.start_date)
      ,max(obs.start_date)
      ,'CVD_ACS'
      ,'PAD_ICD'
from blueherondata.observation_fact obs
join PC_pat18to65_htn htn on htn.patient_num = obs.patient_num
where exists (select 1 from cvd_cd
              where obs.concept_cd = cvd_cd.concept_cd) and 
      htn.event2_date > obs.start_date
group by obs.patient_num,htn.event2_date
;


insert into PC_htn_CV_risk
with cvd_cd as (
select distinct concept_cd, name_char
from blueherondata.concept_dimension 
where concept_path like ('%PROCEDURE\C4\(1012569) Medi~e46q\(1012974) Card~n5t6\(1012975) Ther~zs26\(1021141) Ther~qtwu\(1021163) Perc~vq53%') or
      concept_path like ('%PROCEDURE\C4\(1012569) Medi~e46q\(1012974) Card~n5t6\(1012975) Ther~zs26\(1021141) Ther~qtwu\(1021164) Perc~nqsk%') or
      concept_path like ('%PROCEDURE\C4\(1012569) Medi~e46q\(1012974) Card~n5t6\(1012975) Ther~zs26\(1021141) Ther~qtwu\(1021165) Perc~m81c%') or
      concept_path like ('%PROCEDURE\C4\(1012569) Medi~e46q\(1012974) Card~n5t6\(1012975) Ther~zs26\(1021141) Ther~qtwu\(1021166) Perc~60mq%') or
      concept_path like ('%PROCEDURE\C4\(1012569) Medi~e46q\(1012974) Card~n5t6\(1012975) Ther~zs26\(1021141) Ther~qtwu\(1021167) Perc~fe8s%') or
      concept_path like ('%PROCEDURE\C4\(1012569) Medi~e46q\(1012974) Card~n5t6\(1012975) Ther~zs26\(1021141) Ther~qtwu\(1021168) Perc~1waa%') or
      concept_path like ('%PROCEDURE\C4\(1012569) Medi~e46q\(1012974) Card~n5t6\(1012975) Ther~zs26\(1021141) Ther~qtwu\(92941) Percut~hjqv%') or
      concept_path like ('%PROCEDURE\C4\(1012569) Medi~e46q\(1012974) Card~n5t6\(1012975) Ther~zs26\(1021141) Ther~qtwu\(92973) Percut~8vfu%')
)
select obs.patient_num
      ,htn.event2_date
      ,min(obs.start_date)
      ,max(obs.start_date)
      ,'CVD_ACS'
      ,'PCI_CPT'
from blueherondata.observation_fact obs
join PC_pat18to65_htn htn on htn.patient_num = obs.patient_num
where exists (select 1 from cvd_cd
              where obs.concept_cd = cvd_cd.concept_cd) and 
      htn.event2_date > obs.start_date
group by obs.patient_num,htn.event2_date
;

insert into PC_htn_CV_risk
with cvd_cd as (
select distinct concept_cd, name_char
from blueherondata.concept_dimension 
where concept_path like ('%PROCEDURE\C4\(1003143) Surgery\(1006056) Surg~qacl\(1006057) Surg~rpni\(1006216) Arte~taa4%') or
      concept_path like ('%PROCEDURE\C4\(1003143) Surgery\(1006056) Surg~qacl\(1006057) Surg~rpni\(1006199) Veno~q8fe%') or
      concept_path like ('%PROCEDURE\C4\(1003143) Surgery\(1006056) Surg~qacl\(1006359) Surg~ql5m\(1006515) Bypa~1u2b%')
)
select obs.patient_num
      ,htn.event2_date
      ,min(obs.start_date)
      ,max(obs.start_date)
      ,'CVD_ACS'
      ,'CABG_CPT'
from blueherondata.observation_fact obs
join PC_pat18to65_htn htn on htn.patient_num = obs.patient_num
where exists (select 1 from cvd_cd
              where obs.concept_cd = cvd_cd.concept_cd) and 
      htn.event2_date > obs.start_date
group by obs.patient_num,htn.event2_date
;

insert into PC_htn_CV_risk
with cvd_cd as (
select distinct concept_cd, name_char
from blueherondata.concept_dimension 
where concept_path like ('%PROCEDURE\C4\(1003143) Surgery\(1006056) Surg~qacl\(1006359) Surg~ql5m\(1006462) Thro~7zyq%')
)
select obs.patient_num
      ,htn.event2_date
      ,min(obs.start_date)
      ,max(obs.start_date)
      ,'CVD_ACS'
      ,'CEA_CPT'
from blueherondata.observation_fact obs
join PC_pat18to65_htn htn on htn.patient_num = obs.patient_num
where exists (select 1 from cvd_cd
              where obs.concept_cd = cvd_cd.concept_cd) and 
      htn.event2_date > obs.start_date
group by obs.patient_num,htn.event2_date
;

insert into PC_htn_CV_risk
with cvd_cd as (
select distinct concept_cd, name_char
from blueherondata.concept_dimension 
where concept_path like ('%PROCEDURE\C4\(1003143) Surgery\(1006056) Surg~qacl\(1006359) Surg~ql5m\(1006782) Tran~xw5w%')  
)
select obs.patient_num
      ,htn.event2_date
      ,min(obs.start_date)
      ,max(obs.start_date)
      ,'CVD_ACS'
      ,'CAS_CPT'
from blueherondata.observation_fact obs
join PC_pat18to65_htn htn on htn.patient_num = obs.patient_num
where exists (select 1 from cvd_cd
              where obs.concept_cd = cvd_cd.concept_cd) and 
      htn.event2_date > obs.start_date
group by obs.patient_num,htn.event2_date
;

select count(distinct patient_num) from PC_htn_CV_risk;
-- 3317






/******************************************************/
/* Exclusion criteria                                 */
/******************************************************/

create index PC_htn_CV_risk_PATNUM_DT_IDX on PC_htn_CV_risk(patient_num, htn_date);

drop table pat_excld;
create table pat_excld (
    patient_num varchar(20),
    excld_for varchar(20),
    event_date date
)
;

--1.	age >65 (comfort with telehealth, difference in long term follow up, benefits limited)
--2.	known secondary cause of HTN where usual anti-hypertensives may not work (??)

--3.	Documented proteinuria > 3 grams/day (??)

--4.	eGFR <20 ml/min/1.73 m2 or end stage kidney disease on dialysis -- Lab, ICD
insert into pat_excld
with esrd_cd as (
select distinct concept_cd
from blueherondata.concept_dimension 
where concept_path like ('%\ICD9%\585.6%') or
      concept_path like ('%\ICD10%\N18.6%')
)
   ,esrd_stk as (
select obs.patient_num
      ,obs.start_date
from blueherondata.observation_fact obs
where exists (select 1 from esrd_cd
              where obs.concept_cd = esrd_cd.concept_cd) and 
      exists (select 1 from PC_htn_CV_risk 
              where PC_htn_CV_risk.patient_num = obs.patient_num and 
                    PC_htn_CV_risk.htn_date >= obs.start_date)
union
select obs.patient_num
      ,obs.start_date
from blueherondata.observation_fact obs
where obs.concept_cd in ('KUH|COMPONENT_ID:191') and obs.nval_num < 20 and 
      exists (select 1 from PC_htn_CV_risk 
              where PC_htn_CV_risk.patient_num = obs.patient_num and 
                    PC_htn_CV_risk.htn_date >= obs.start_date)
)
select patient_num
      ,'ESRD'
      ,max(start_date)
from esrd_stk
group by patient_num
;



--5.	Myocardial infarction, angina, percutaneous coronary intervention, coronary artery bypass grafting, carotid endarterectomy, carotid stenting, or aortic aneurysm repair within last the past 3 months. -- ICD
--insert into pat_excld 
--select patient_num
--      ,'CVD_last3mth'
--      ,max(last_date)
--from PC_htn_CV_risk
--where last_date >= current_date - 90
--group by patient_num
--;



--6.	Medical conditions such as cirrhosis, heart failure, or cancer with life expectancy less than 2 years. (??)



--7.	Residence in a nursing home or active rehabilitation facility. (??)



--8.	Clinically-significant illness that may affect safety or completion per their treating PCP or study physician (??)



--9.	Chronic active disease with expected life expectancy < 2 years as determined by the study team (??)



--10.	Any factors judged by the clinic team to be likely to limit study procedures as determined by the physician or study team. For example, 
--   a.	Active substance abuse (??)
--   b.	Unstable psychiatric conditions (??)




/************************************************/
/* Final Cohort                                 */
/************************************************/
drop table PC_pat18to65_htn_CV purge;
create table PC_pat18to65_htn_CV as
select incld.patient_num
      ,max(incld.htn_date) htn_date
from PC_htn_CV_risk incld
where not exists (select 1 from pat_excld excld
                  where excld.patient_num = incld.patient_num)
group by incld.patient_num
;

--create index PC_pat18to65_htn_PAT_IDX on PC_pat18to65_htn(patient_num);

--drop table PC_pat18to65_htn purge;
--create table PC_pat18to65_htn as
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
select 'initial', case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end from PC_pat18to65_demo;

insert into stats_tbl
select 'elevated BP', case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end from PC_pat18to65_htn;

insert into stats_tbl
select comorb, case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end from PC_htn_CV_risk
group by comorb;

insert into stats_tbl
select 'final', case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end from PC_htn_CV_risk;

insert into stats_tbl
select ('exclude:' || excld_for), case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end from pat_excld
group by excld_for;

insert into stats_tbl
select 'my-chart enroll', case when count(distinct patient_num) < 11 then -1 else count(distinct patient_num) end from PC_pat18to65_htn_CV fin
where exists (select 1 from PC_pat18to65_demo demo
              where demo.patient_num = fin.patient_num and demo.mychart_start is not null);
              
insert into stats_tbl
with fin_demo as (
select demo.* from PC_pat18to65_demo demo
where exists (select 1 from PC_pat18to65_htn_CV fin where fin.patient_num = demo.patient_num)
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

whenever sqlerror exit;
commit;

/*eyeball the results*/
select * from stats_tbl;

/***************************************************************************************/
/* Load summary counts into software on Green-Heron for downstream analysis or plotting*/
/***************************************************************************************/
