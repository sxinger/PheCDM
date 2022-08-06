## https://data.cms.gov/search

import requests
import json
import os
import pandas as pd
import api_call_utils as apiutil

which_cms_open_data = "provider_taxonomy"

# make api request
url = apiutil.get_access_info()['cmsdata_api'][which_cms_open_data]
response_api = requests.get(url)
print(f'status_code:{response_api.status_code}')

# convert json to dataframe
data = response_api.text
df = pd.read_json(data)

# write to csv file
path_to_save = f'{os.path.dirname(os.path.dirname(__file__))}/valueset_autogen'
df.to_csv(f'{path_to_save}/{which_cms_open_data}.csv', index = None)

