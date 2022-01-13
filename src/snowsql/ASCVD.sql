/******************************************************************************************
This script is to identify Atherosclerotic Cardiovascular Diseases (ASCVD)
for the targeted cohort. ASCVD events consists of:
- CHD: Coronary Heart Disease
- CVD: Cerebrovascular Disease
- PAD: Peripheral Arterial Disease
which are identified by ICD diagnosis codes and ICD/CPT procedure codes.
Ref: https://phekb.org/sites/phenotype/files/Map_ICD9_2_ICD10_CS_MSS_03222017_0.pdf

For efficiency, it is recommended to perform computational 
phenotyping on a smaller cut of needed CDM tables only relevant to the 
eligible patient cohort. The study-specific CDM tables are usually 
saved in a separate Study Schema (e.g. VCCC_SCHEMA) preserving CDM relational database structure.
*************************************************************************************************/