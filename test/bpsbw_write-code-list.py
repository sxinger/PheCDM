import csv
import pandas as pd

path_to_search_catalog = 'C:/repo/PheCDM/concept_set/autogen_set'
search_catalog_name = 'ped-uc-var'

search_key = pd.read_csv(f'{path_to_search_catalog}/{search_catalog_name}.txt',sep=',').set_index("search_term")
search_dict = {k: g.to_dict(orient='records') for k, g in search_key.groupby(level=0)}
print(search_dict)

