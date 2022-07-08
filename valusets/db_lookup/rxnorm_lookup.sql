-- look up RXCUI by generic name string matching
-- load lookup reference
create or replace table LOOKUP_TABLE_GN (
  GN VARCHAR(40)
);
-- load data in from console
select * from LOOKUP_TABLE_GN;

-- look up Rxnorm by generic name
create or replace table ConceptSet_Med_APD_RXCUI as
select distinct
       l.GN
      ,r.STR
      ,r.RXCUI
      ,r.SUPPRESS
from LOOKUP_TABLE_GN l
join ontology.rxnorm.rxnconso r
on lower(r.STR) like '%'||l.GN||'%' and
   r.TTY = 'SCD' --Semantic Clinical Drug
;

-- look up NDC by provided RXCUI list
create or replace table ConceptSet_Med_APD_NDC as
select distinct
       rxn.RXCUI
      ,rxn.GN
      ,rxmap.ATV as NDC
      ,rxmap.SUPPRESS
from ConceptSet_Med_APD_RXCUI rxn
join ontology.rxnorm.rxnsat rxmap
on rxn.RXCUI = rxmap.RXCUI and
   rxmap.ATN = 'NDC'and rxmap.SAB = 'RXNORM' -- normalized 11-digit NDC codes
;

