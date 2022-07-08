## https://vsac.nlm.nih.gov/download/ccda
## process downloaded compressed files in bulk

from pickle import TRUE
import pandas as pd
from os.path import exists
from zipfile import ZipFile
import json

path_to_download = 'C:/Users/xsm7f/Downloads'
file_name = "c_cda_release_20210810"
# file_name = "test"

if exists(f'{path_to_download}/{file_name}.zip') and not exists(f'{path_to_download}/{file_name}.xlsx'):
    # unzip
    zipped_file = ZipFile(f'{path_to_download}/{file_name}.zip')
    zipped_file.extractall(path_to_download)
    file_lst = zipped_file.namelist()
    print(f'files unzipped:{file_lst} ')

# read-in file
df =  pd.read_excel(f'{path_to_download}/{file_name}.xlsx', sheet_name = 1, skiprows=[0])
vs_col = ["Value Set Name","Value Set OID","Purpose: Clinical Focus","Purpose: Data Element Scope","Purpose: Inclusion Criteria","Purpose: Exclusion Criteria"]
ccda_set = {}
# parse each spreadsheet (DGM domain)
unique_vs = df[vs_col].drop_duplicates(ignore_index=True).reset_index()
# parse each value-code chunk
for i, r in unique_vs.iterrows():
    # keep metadata info for the valueset
    ccda_set[r[vs_col[0]]]={"vs-id":r[vs_col[0]],
                            "clinical-focus":r[vs_col[1]],
                            "data-element":r[vs_col[2]],
                            "incld":r[vs_col[3]],
                            "excld":r[vs_col[4]]}
    # gather codelist included in the value set
    sub_df = df[df[vs_col[0]]==r[vs_col[0]]]
    sub_df_zip = sub_df.groupby('Code System').apply(lambda x: list(zip(x['Code'].to_list(),x['Description'].to_list()))).to_dict()
    sub_df_dict = {k: list(set(v)) for k,v in sub_df_zip.items()} # not sure why last step created duplications
    ccda_set[r[vs_col[0]]]["codelist"] = sub_df_dict

# dump dict as json file
with open(f"C:/repo/PheCDM/concept_set/valueset_autogen/ccda-hl7.json","w",encoding='utf-8') as writer: 
    json.dump(ccda_set, writer, ensure_ascii=False, indent=4)

    
