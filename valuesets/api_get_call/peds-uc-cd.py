import bioportal_api_get as bps
import numpy as np
import pandas as pd
import api_call_utils as apiutil

# get api key
api_key=apiutil.get_access_info()['bioportal']['api_key']

# generate a bps batch write instance
bps.batch_write_vs_excel(
     api_key
    ,'C:/repo/PheCDM/concept_set/autogen_set'
    ,'ped-uc-var_input2'
    )

"""
'''
colectomy
'''
s1a = bps.BioPortalSearch(key,'colectomy','CPT').get_code_list()
s1b = bps.BioPortalSearch(key,'colectomy','HCPCS').get_code_list()
# s1c = bps.BioPortalSearch(key,'colectomy','ICD10PCS')
s1a_tbl = pd.DataFrame({k:s1a[k] for k in ('code_type','code',"label")})
s1b_tbl = pd.DataFrame({k:s1b[k] for k in ('code_type','code',"label")})
s1_tbl = pd.concat([s1a_tbl,s1b_tbl],ignore_index=True)

with pd.ExcelWriter('ped-uc-codeset.xlsx') as writer:
    s1_tbl.to_excel(writer,sheet_name='colectomy')


'''
mesalazine
'''
s2 = bps.BioPortalSearch(key,'mesalazine','RXNORM').get_code_list()
s2_tbl = pd.DataFrame({k:s2[k] for k in ('code_type','code',"label")})

with pd.ExcelWriter('ped-uc-codeset.xlsx',mode='a') as writer:
    s2_tbl.to_excel(writer,sheet_name='mesalazine')

'''
corticosteroids
'''
s3a = bps.BioPortalSearch(key,'prednisone','RXNORM').get_code_list()
s3b = bps.BioPortalSearch(key,'methylprednisolone','RXNORM').get_code_list()
s3c = bps.BioPortalSearch(key,'hydrocortisone','RXNORM').get_code_list()
s3d = bps.BioPortalSearch(key,'budesonide','RXNORM').get_code_list()

s3a_tbl = pd.DataFrame({k:s3a[k] for k in ('code_type','code',"label")})
s3b_tbl = pd.DataFrame({k:s3b[k] for k in ('code_type','code',"label")})
s3c_tbl = pd.DataFrame({k:s3c[k] for k in ('code_type','code',"label")})
s3d_tbl = pd.DataFrame({k:s3d[k] for k in ('code_type','code',"label")})

s3_tbl = pd.concat([s3a_tbl,s3b_tbl,s3c_tbl,s3d_tbl],ignore_index=True)

with pd.ExcelWriter('ped-uc-codeset.xlsx',mode='a') as writer:
    s3_tbl.to_excel(writer,sheet_name='corticosteroids')

'''
hemoglobin
'''
s4 = bps.BioPortalSearch(key,'hemoglobin','LOINC').get_code_list()
s4_tbl = pd.DataFrame({k:s4[k] for k in ('code_type','code',"label")})

with pd.ExcelWriter('ped-uc-codeset.xlsx',mode='a') as writer:
    s4_tbl.to_excel(writer,sheet_name='hemoglobin')

'''
platelet count
'''
s5 = bps.BioPortalSearch(key,'platelet+count','LOINC').get_code_list()
s5_tbl = pd.DataFrame({k:s5[k] for k in ('code_type','code',"label")})

with pd.ExcelWriter('ped-uc-codeset.xlsx',mode='a') as writer:
    s5_tbl.to_excel(writer,sheet_name='platelet count')

'''
white blood count
'''
s6 = bps.BioPortalSearch(key,'white+blood+count','LOINC').get_code_list()
s6_tbl = pd.DataFrame({k:s6[k] for k in ('code_type','code',"label")})

with pd.ExcelWriter('ped-uc-codeset.xlsx',mode='a') as writer:
    s6_tbl.to_excel(writer,sheet_name='white blood count')

'''
albumin
'''
s7 = bps.BioPortalSearch(key,'albumin','LOINC').get_code_list()
s7_tbl = pd.DataFrame({k:s7[k] for k in ('code_type','code',"label")})

with pd.ExcelWriter('ped-uc-codeset.xlsx',mode='a') as writer:
    s7_tbl.to_excel(writer,sheet_name='albumin')

'''
fecal calprotectin
'''
s8 = bps.BioPortalSearch(key,'fecal+calprotectin','LOINC').get_code_list()
s8_tbl = pd.DataFrame({k:s8[k] for k in ('code_type','code',"label")})

with pd.ExcelWriter('ped-uc-codeset.xlsx',mode='a') as writer:
    s8_tbl.to_excel(writer,sheet_name='fecal calprotectin')

'''
erythrocyte sedimentation rate
'''
s9 = bps.BioPortalSearch(key,'erythrocyte+sedimentation+rate','LOINC').get_code_list()
s9_tbl = pd.DataFrame({k:s9[k] for k in ('code_type','code',"label")})

with pd.ExcelWriter('ped-uc-codeset.xlsx',mode='a') as writer:
    s9_tbl.to_excel(writer,sheet_name='ESR')

'''
C-reactive protein
'''
s10 = bps.BioPortalSearch(key,'C+reactive+protein','LOINC').get_code_list()
s10_tbl = pd.DataFrame({k:s10[k] for k in ('code_type','code',"label")})

with pd.ExcelWriter('ped-uc-codeset.xlsx',mode='a') as writer:
    s10_tbl.to_excel(writer,sheet_name='CRP')

'''
fecal osteoprotegerin
'''
s11 = bps.BioPortalSearch(key,'fecal+osteoprotegerin','LOINC').get_code_list()
s11_tbl = pd.DataFrame({k:s11[k] for k in ('code_type','code',"label")})

with pd.ExcelWriter('ped-uc-codeset.xlsx',mode='a') as writer:
    s11_tbl.to_excel(writer,sheet_name='fecal osteoprotegerin')

'''
25-OH Vitamin D
'''
s12 = bps.BioPortalSearch(key,'25+OH+Vitamin+D','LOINC').get_code_list()
s12_tbl = pd.DataFrame({k:s12[k] for k in ('code_type','code',"label")})

with pd.ExcelWriter('ped-uc-codeset.xlsx',mode='a') as writer:
    s12_tbl.to_excel(writer,sheet_name='25OH vitaminD')

'''
abdominal pain
'''
s13a = bps.BioPortalSearch(key,'abdominal+pain','ICD10CM').get_code_list()
s13b = bps.BioPortalSearch(key,'abdominal+pain','ICD9CM').get_code_list()
s13a_tbl = pd.DataFrame({k:s13a[k] for k in ('code_type','code',"label")})
s13b_tbl = pd.DataFrame({k:s13b[k] for k in ('code_type','code',"label")})
s13_tbl = pd.concat([s13a_tbl,s13b_tbl],ignore_index=True)

with pd.ExcelWriter('ped-uc-codeset.xlsx',mode='a') as writer:
    s13_tbl.to_excel(writer,sheet_name='abdominal pain')

'''
diarrhea
'''
s14a = bps.BioPortalSearch(key,'diarrhea','ICD10CM').get_code_list()
s14b = bps.BioPortalSearch(key,'diarrhea','ICD9CM').get_code_list()
s14a_tbl = pd.DataFrame({k:s14a[k] for k in ('code_type','code',"label")})
s14b_tbl = pd.DataFrame({k:s14b[k] for k in ('code_type','code',"label")})
s14_tbl = pd.concat([s14a_tbl,s14b_tbl],ignore_index=True)

with pd.ExcelWriter('ped-uc-codeset.xlsx',mode='a') as writer:
    s14_tbl.to_excel(writer,sheet_name='diarrhea')

'''
rectal bleeding
'''
s15a = bps.BioPortalSearch(key,'rectal+bleeding','ICD10CM').get_code_list()
s15b = bps.BioPortalSearch(key,'rectal+bleeding','ICD9CM').get_code_list()
s15a_tbl = pd.DataFrame({k:s15a[k] for k in ('code_type','code',"label")})
s15b_tbl = pd.DataFrame({k:s15b[k] for k in ('code_type','code',"label")})
s15_tbl = pd.concat([s15a_tbl,s15b_tbl],ignore_index=True)

with pd.ExcelWriter('ped-uc-codeset.xlsx',mode='a') as writer:
    s15_tbl.to_excel(writer,sheet_name='rectal bleeding')
"""