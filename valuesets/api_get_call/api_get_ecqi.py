## https://www.nlm.nih.gov/vsac/support/usingvsac/vsacsvsapiv2.html
## https://github.com/HHS/uts-rest-api/blob/master/samples/python/retrieve-value-set-info.py

import requests
import json
import os
import pandas as pd
import api_call_utils as apiutil


'''
# convert json to dataframe
data = response_api.text
df = pd.read_json(data)

# write to csv file
path_to_save = f'{os.path.dirname(os.path.dirname(__file__))}/valueset_autogen'
df.to_csv(f'{path_to_save}/{which_cms_open_data}.csv', index = None)
'''
