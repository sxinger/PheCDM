from json import load,loads,dump
from re import search
import requests
import os
import pandas as pd
import api_call_utils as apiutil

# https://github.com/HHS/uts-rest-api

# Authentication
uri = apiutil.get_access_info()['umls-api']['auth-uri']
tgt_endpoint = apiutil.get_access_info()['umls-api']['auth-endpoint']
st_endpoint = apiutil.get_access_info()['umls-api']['service-endpoint']
apikey = apiutil.get_access_info()['umls-api']['api-key']

authclient = apiutil.two_factor_auth(uri,tgt_endpoint,st_endpoint,apikey)
tgt = authclient.get_tgt()
st = authclient.get_st(tgt)

class UmlsSearch:
    '''
    search UMLS API and return requested results in human-readable format
    '''
    def __init__(self,api_uri,api_key,sterm,sont):
        self.api_uri = api_uri
        self.api_key = api_key
        self.sterm = sterm
        self.sont = sont
    
    def get_json(self,url):
        opener = urllib.request.build_opener()
        opener.addheaders = [('Authorization', 'apikey token=' + self.api_key)]
        return loads(opener.open(url).read())

    def get_code_list(self) -> dict:
        '''
        parse returned json file and return as tabular data
        '''
        labels = [] 
        tuis = []
        cuis = []
        ids = []  
        
        page = 1
        next_page = page
        time.sleep(1)
        sterm_mod = self.sterm.replace(' ','%20')
        result = self.get_json(f'{self.API_URL}/search?q={sterm_mod}&ontologies={self.sont}')
        while next_page:
            '''loop over all items in the collection list'''
            for cls in result["collection"]:
                # additional filter
                if search(self.sterm.replace(' ','.*'),cls["prefLabel"].lower()):
                    labels.append(cls["prefLabel"])
                    tuis.append(' '.join(cls.get("semanticType","NA")))
                    cuis.append(' '.join(cls.get("cui","NA")))
                    ids.append(cls["@id"].rsplit('/', 1)[-1])
                else: 
                    continue

            '''go to next page'''
            next_page = result["nextPage"]
            page_url = result["links"]["nextPage"]
            time.sleep(1)
            try: 
                result = self.get_json(page_url)
            except:
                pass

        out = {"code_type":self.sont,
               "code":ids,
               "label":labels,
               "tui":tuis,
               "cui":cuis}
        return out

