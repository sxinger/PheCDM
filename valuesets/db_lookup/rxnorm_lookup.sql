-- look up RXCUI by generic name string matching
-- look up Rxnorm by generic name partial string matching
create or replace table ConceptSet_Med_APD_RXCUI as
select distinct
       l.GN
      ,r.STR
      ,r.RXCUI
      ,r.SUPPRESS
from LOOKUP_TABLE_GN l
join ontology.rxnorm.rxnconso r
on (
      lower(r.STR) like '%chlorpromazine%' OR
      lower(r.STR) like '%amisulpride%'  OR
      lower(r.STR) like '%aripiprazole%'  OR
      lower(r.STR) like '%benperidol%' OR
      lower(r.STR) like '%clopenthixol%' OR
      lower(r.STR) like '%clorprothixene%' OR
      lower(r.STR) like '%clotiapine%' OR
      lower(r.STR) like '%clozapine%' OR
      lower(r.STR) like '%droperidol%' OR
      lower(r.STR) like '%flupenthixol%' OR
      lower(r.STR) like '%fluphenazine%' OR
      lower(r.STR) like '%haloperidol%' OR
      lower(r.STR) like '%levomepromazine%'  OR
      lower(r.STR) like '%loxapine%' OR
      lower(r.STR) like '%mesoridazine%' OR
      lower(r.STR) like '%methotrimeprazine%' OR
      lower(r.STR) like '%molindone%' OR
      lower(r.STR) like '%olanzapine%' OR
      lower(r.STR) like '%oxypertine%' OR
      lower(r.STR) like '%paliperidone%' OR
      lower(r.STR) like '%pericyazine%' OR
      lower(r.STR) like '%perphenazine%' OR
      lower(r.STR) like '%pimozide%' OR
      lower(r.STR) like '%prochlorperazine%' OR
      lower(r.STR) like '%quetiapine%' OR
      lower(r.STR) like '%remoxipride%' OR
      lower(r.STR) like '%risperidone%' OR
      lower(r.STR) like '%sertindole%' OR
      lower(r.STR) like '%sulpiride%' OR
      lower(r.STR) like '%thioridazine%' OR
      lower(r.STR) like '%thiothixene%' OR
      lower(r.STR) like '%trifluoperazine%' OR
      lower(r.STR) like '%trifluperidol%' OR
      lower(r.STR) like '%triflupromazine%' OR
      lower(r.STR) like '%ziprasidone%' OR
      lower(r.STR) like '%zotepine%' OR
      lower(r.STR) like '%zuclopenthixol%' OR
      lower(r.STR) like '%chlorpromazine%hcl%' OR
      lower(r.STR) like '%clotiapine%injectable%' OR
      lower(r.STR) like '%fluphenazine%hcl%' OR
      lower(r.STR) like '%haloperidol%lactate%' OR
      lower(r.STR) like '%loxapine%hcl%' OR
      lower(r.STR) like '%mesoridazine%besylate%' OR
      lower(r.STR) like '%olanzapine%tartrate%' OR
      lower(r.STR) like '%perphenazine%usp%' OR
      lower(r.STR) like '%prochlorperazine%mesylate%' OR
      lower(r.STR) like '%promazine%hcl%' OR
      lower(r.STR) like '%trifluoperazine%hcl%' OR
      lower(r.STR) like '%triflupromazine%hcl%' OR
      lower(r.STR) like '%ziprasidone%mesylate%' OR
      lower(r.STR) like '%zuclopenthixol%acetate%' OR
      lower(r.STR) like '%clopenthixol%decanoate%' OR
      lower(r.STR) like '%flupenthixol%decanoate%' OR
      lower(r.STR) like '%fluphenazine%decanoate%' OR
      lower(r.STR) like '%fluphenazine%enanthate%' OR
      lower(r.STR) like '%fluspirilene%' OR
      lower(r.STR) like '%haloperidol%decanoate%' OR
      lower(r.STR) like '%perphenazine%enanthate%' OR
      lower(r.STR) like '%pipotiazine%palmitate%' OR
      lower(r.STR) like '%risperidone%microspheres%' OR
      lower(r.STR) like '%zuclopenthixol%decanoate%' OR
      lower(r.STR) like '%acepromazine%' OR
      lower(r.STR) like '%acetophenazine%' OR
      lower(r.STR) like '%asenapine%' OR
      lower(r.STR) like '%bromperidol%' OR
      lower(r.STR) like '%butaperazine%' OR
      lower(r.STR) like '%chlorprothixene%' OR
      lower(r.STR) like '%dixyrazine%' OR
      lower(r.STR) like '%flupentixol%' OR
      lower(r.STR) like '%levosulpiride%' OR
      lower(r.STR) like '%lurasidone%' OR
      lower(r.STR) like '%melperone%' OR
      lower(r.STR) like '%moperone%' OR
      lower(r.STR) like '%penfluridol%' OR
      lower(r.STR) like '%perazine%' OR
      lower(r.STR) like '%periciazine%' OR
      lower(r.STR) like '%pipamperone%' OR
      lower(r.STR) like '%pipotiazine%' OR
      lower(r.STR) like '%promazine%' OR
      lower(r.STR) like '%prothipendyl%' OR
      lower(r.STR) like '%sultopride%' OR
      lower(r.STR) like '%thiopropazate%' OR
      lower(r.STR) like '%thioproperazine%' OR
      lower(r.STR) like '%tiapride%' OR
      lower(r.STR) like '%tiotixene%' OR
      lower(r.STR) like '%aripiprazole%lauroxil%' OR
      lower(r.STR) like '%brexpiprazole%' OR
      lower(r.STR) like '%cariprazine%' OR
      lower(r.STR) like '%iloperidone%'
   )
   and
   (
      -- https://www.nlm.nih.gov/research/umls/rxnorm/docs/appendix5.html
      r.TTY like 'SCD%' OR --Semantic Clinical Drug
      r.TTY like 'SBD%' OR --Semantic Branded Drug
      r.TTY like '%IN'
   )
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

