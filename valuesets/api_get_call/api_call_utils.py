# https://github.com/HHS/uts-rest-api/blob/master/samples/python/Authentication.py

import os
from json import load
import requests
import lxml.html as lh

def get_access_info(path_to_key=None):
    # populate default location for config file
    if path_to_key is None:
        path_to_key = os.path.dirname(os.path.dirname(os.path.dirname(__file__))) + '\.config\config.json'    
    # load config file
    with open(path_to_key) as config_file:
        key = load(config_file)
    return(key)

class two_factor_auth:
    '''
    make api request for two-step-authentication
    '''
    def __init__(self,auth_uri,tgt_endpoint,st_endpoint,apikey):
        self.auth_uri = auth_uri
        self.tgt_endpoint = tgt_endpoint
        self.st_endpoint = st_endpoint
        self.apikey = apikey

    def get_tgt(self):
        # step 1 - get ticket-granting-token
        params = {'apikey': self.apikey}
        headers = {"Content-type": "application/x-www-form-urlencoded", "Accept": "text/plain", "User-Agent":"python" }
        response_tgt = requests.post(self.auth_uri+self.tgt_endpoint,
                                     data=params, headers = headers)
        response_tgt_out = lh.fromstring(response_tgt.text)
        tgt = response_tgt_out.xpath('//form/@action')[0]
        return tgt

    def get_st(self,tgt,verbose=True):
        # step 2 - get service ticket
        params = {'service': self.st_endpoint}
        headers = {"Content-type": "application/x-www-form-urlencoded", "Accept": "text/plain", "User-Agent":"python" }
        response_st = requests.post(tgt,data=params,headers=headers)
        if verbose:
            print('status_code',response_st.status_code)
        st = response_st.text
        return st

    
