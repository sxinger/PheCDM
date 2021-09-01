/********************************************************************
This table is to identify patients' Smoking Status. Smoking Status is 
identified by self-reported Smoking/Tabacco usage data, acertained by 
a) smoking cessation, or
b) use of nicotine withdrawal meds, or 
c) Fagerstrom Test For Nicotine Dependence (FTND) 

For efficiency, it is recommended to perform computational 
phenotyping on a smaller cut of CDM tables relevant to the 
eligible patient cohort
********************************************************************/

/* setup environment*/
use role "ANALYTICS";
use warehouse ANALYTICS_WH;
use database ANALYTICSDB;
use schema VCCC_SCHEMA;

