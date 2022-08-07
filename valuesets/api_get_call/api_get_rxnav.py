from json import load,loads,dump
from re import search
import requests
import api_call_utils as apiutil
import api_get_umls as apiumls

class RxNavSearch:
    '''
    search RxNav API and return requested results in human-readable format
    '''
    # global values
    AUTH_URI = apiutil.get_access_info()['uts-auth-api']['auth-uri']
    TGT_ENDPOINT = apiutil.get_access_info()['uts-auth-api']['auth-endpoint']
    ST_ENDPOINT = apiutil.get_access_info()['uts-auth-api']['service-endpoint']
    API_KEY = apiutil.get_access_info()['uts-auth-api']['api-key']
    API_URI = apiutil.get_access_info()['umls-api']['rxnav-endpoint']

    # instance values
    def __init__(self):
        # generate ticket granting ticket for the session
        self.authclient = apiutil.two_factor_auth(self.AUTH_URI,self.TGT_ENDPOINT,self.ST_ENDPOINT,self.API_KEY)
        self.tgt = self.authclient.get_tgt()
    
    # get list of ndc codes for given rxcui code
    def get_ndc_list(self,rxcui='000') -> list:
        '''
        rxnav call to collect NDC list for a given RXCUI code
        '''
        # time.sleep(0.05)
        tkt = self.authclient.get_st(self.tgt, verbose=False)
        query = {'ticket': tkt}
        response = requests.get(f'{self.API_URI}/rxcui/{rxcui}/ndcs.json',params=query)
        items  = loads(response.text)
        if not items["ndcGroup"]["ndcList"]:
            return ([])
        else:
            return(items["ndcGroup"]["ndcList"]["ndc"])       

def batch_write_ndc_json(path_to_save, #absolute path,
                         filename_to_save,
                         sterms:list,verbose=True):
    '''
    identify rxcui codes for each term in sterms, then
    search rxnav database to identify all cooresponding ndc codes
    '''
    dict_agg = {}
    for term in sterms:
        # search umls for all rxcui codes (SCD, SCDG, SBD, SBDG)
        rxcui_search_obj = apiumls.UmlsSearch(term,'RXNORM')
        rxcui_dict = rxcui_search_obj.get_code_list()

        # search rxnavf or ndc list of each rxcui code
        dict_term = []
        for idx, key in enumerate(rxcui_dict["code"]):
            rxnav_cls = RxNavSearch()
            ndc_lst = rxnav_cls.get_ndc_list(key)
            dict_term.append({'rxcui': key,
                              'label': rxcui_dict["label"][idx],
                              'ndc':ndc_lst})
        dict_agg[term] = dict_term

        # report progress
        if verbose:
            print(f'finish search for rxcui:{term}')

    # write single dictionary to json
    with open(f"{path_to_save}/{filename_to_save}.json","w",encoding='utf-8') as writer: 
        dump(dict_agg, writer, ensure_ascii=False, indent=4)

