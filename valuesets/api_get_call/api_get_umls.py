from json import load,loads,dump,dumps
from re import search
import requests
import os
import pandas as pd
import api_call_utils as apiutil
from re import search

# https://github.com/HHS/uts-rest-api

class UmlsSearch:
    '''
    search UMLS API and return requested results in human-readable format
    '''
    # global values
    AUTH_URI = apiutil.get_access_info()['uts-auth-api']['auth-uri']
    TGT_ENDPOINT = apiutil.get_access_info()['uts-auth-api']['auth-endpoint']
    ST_ENDPOINT = apiutil.get_access_info()['uts-auth-api']['service-endpoint']
    API_KEY = apiutil.get_access_info()['uts-auth-api']['api-key']
    API_URI = apiutil.get_access_info()['umls-api']['uts-ws-endpoint']

    # instance value
    def __init__(self,sterm,sont):
        self.sterm = sterm
        self.sont = sont
        # generate ticket granting ticket for the session
        self.authclient = apiutil.two_factor_auth(self.AUTH_URI,self.TGT_ENDPOINT,self.ST_ENDPOINT,self.API_KEY)
        self.tgt = self.authclient.get_tgt()
    
    # main function for getting code list of specified vocab
    def get_code_list(self,verbose=True) -> dict:
        '''
        get code list from a particular vocab based on term search
        '''
        labels = [] 
        cuis = []
        ids = []  
        
        page = 0
        valid_page = True
        while valid_page:
            # time.sleep(0.05)
            tkt = self.authclient.get_st(self.tgt, verbose=False)
            # build search query
            page += 1
            query = {'string': self.sterm,
                     'ticket': tkt,
                     'pageNumber': page,
                     'sabs':self.sont}
            #query['includeObsolete'] = 'true'
            #query['includeSuppressible'] = 'true'  
            #query['returnIdType'] = "sourceConcept"
            response = requests.get(f'{self.API_URI}/search/current',params=query)
            items  = loads(response.text)
            jsonData = items["result"]

            # either search returned nothing, or we're at an empty page, break the loop
            if not jsonData["results"]:
                valid_page = False
                break

            # otherwise, parse out code information from results
            for result in jsonData["results"]:
                # additional filter
                if result["rootSource"] == self.sont and search(self.sterm.replace(' ','.*'),result["name"].lower()):
                    labels.append(result["name"])
                    cuis.append(result["ui"])
                    # another api call to get the concept code from the vocab of interests
                    tkt = self.authclient.get_st(self.tgt, verbose=False)
                    query = {'ticket': tkt,
                             'sabs':self.sont}
                    id_r = requests.get(f'{result["uri"]}/atoms',params=query)
                    id_item = loads(id_r.text)
                    id_sublst = [d['code'].rsplit('/', 1)[-1] for d in id_item['result'] if d['rootSource']==self.sont and ('SCD' in d['termType'] or 'SBD' in d['termType'])]
                    ids.extend(id_sublst)
                else:
                    continue
           
            if verbose:
                print("Results parsed for page " + str(page)+"\n")          

            # collect result
            out = {"code_type":self.sont,
                   "code":ids,
                   "label":labels,
                   "cui":cuis}
            return out

