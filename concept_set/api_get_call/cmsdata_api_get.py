## https://data.cms.gov/search

import requests
import json
import os
import pandas as pd

def get_access_info(path_to_key):
    with open(path_to_key) as config_file:
        key = json.load(config_file)
    return(key)

# make api request
cms_open_data = "provider_taxonomy"
url = get_access_info("./.config/config.json")['cmsdata_api'][cms_open_data]
response_api = requests.get(url)
print(f'status_code:{response_api.status_code}')

# convert json to dataframe
data = response_api.text
df = pd.read_json(data)

# write to csv file
path_to_save = f'{os.path.dirname(os.path.dirname(__file__))}/valueset_autogen'
df.to_csv(f'{path_to_save}/{cms_open_data}.csv', index = None)

    

    



    






