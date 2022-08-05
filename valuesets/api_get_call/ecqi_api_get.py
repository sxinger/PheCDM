## https://www.nlm.nih.gov/vsac/support/usingvsac/vsacsvsapiv2.html

import requests
import json
import os
import pandas as pd

def get_access_info(path_to_key):
    with open(path_to_key) as config_file:
        key = json.load(config_file)
    return(key)

# make api request for two-step-authentication
# step 1 - get ticket-granting-token
url_tgt = f'''{get_access_info("./.config/config.json")['vsac-api']['base-url']}/ws/Ticket'''
apikey = get_access_info("./.config/config.json")['vsac-api']['api-key']
response_tgt = requests.post(url_tgt,data={"apikey":apikey})
# step 2 - get service ticket
url_st = f'''{get_access_info("./.config/config.json")['vsac-api']['base-url']}/ws/Ticket/{response_tgt.text}'''
response_st = requests.post(url_st,data={"service":"http://umlsks.nlm.nih.gov"})
print('status_code',response_tgt.status_code)

'''
# convert json to dataframe
data = response_api.text
df = pd.read_json(data)

# write to csv file
path_to_save = f'{os.path.dirname(os.path.dirname(__file__))}/valueset_autogen'
df.to_csv(f'{path_to_save}/{which_cms_open_data}.csv', index = None)
'''
