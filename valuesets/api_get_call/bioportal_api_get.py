from json import load,loads,dump
from re import search
import urllib.request, urllib.error, urllib.parse
# import requests #better library for API call
import time
import pandas as pd
from regex import F

'''
Note: search term has to be searchable, i.e., guarantee of returning at least one
matching results; otherwise, the program will be aborted. You can do a courtesy 
search at https://bioportal.bioontology.org/ to determine the right term included
'''

##search_str = '&'.join(['%s=%s' % (k,v) for k,v in self.api_params.iteritems()])

def get_access_info(path_to_key):
    with open(path_to_key) as config_file:
        key = load(config_file)
    return(key)

class BioPortalSearch:
    '''
    search bioportal API and return requested results in human-readable format
    '''
    API_URL = 'http://data.bioontology.org'

    def __init__(self,api_key,sterm,sont):
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
        
'''
batch run bioportal search and write search results to excel sheets
'''  
def batch_write_vs_excel(api_key,
                          path_to_search_catalog, #absolute path
                          search_catalog_name,
                          verbose=True):
    search_key = pd.read_csv(f'{path_to_search_catalog}/{search_catalog_name}.txt',sep=',').set_index("search_term")
    search_dict = {k: g.to_dict(orient='records') for k, g in search_key.groupby(level=0)}

    #initialize workbook
    with pd.ExcelWriter(f"{path_to_search_catalog}/{search_catalog_name.replace('input','output')}.xlsx") as writer: 
        search_key.to_excel(writer,sheet_name='search keys')

    #append worksheets
    for key in search_dict:   
        result = []
        for ont in search_dict[key]:
            bps_inst = BioPortalSearch(api_key,key,ont['search_ont']).get_code_list()
            result.append(pd.DataFrame(bps_inst))
        # list to pd dataframe
        result_df = pd.concat(result,ignore_index=True)
        with pd.ExcelWriter(f"{path_to_search_catalog}/{search_catalog_name.replace('input','output')}.xlsx",mode='a') as writer: 
            result_df.to_excel(writer,sheet_name=key[:30],index=False)
        # report progress
        if verbose:
            print(f'finish search for term:{key}')

def batch_write_vs_json(api_key,
                        path_to_search_catalog, #absolute path
                        search_catalog_name,
                        verbose=True):
    search_key = pd.read_csv(f'{path_to_search_catalog}/{search_catalog_name}.txt',sep=',').set_index("search_term")
    search_dict = {k: g.to_dict(orient='records') for k, g in search_key.groupby(level=0)}
    # collect aggregated dict
    dict_agg = {}
    for key in search_dict:
        result = [] 
        for ont in search_dict[key]:
            bps_inst = BioPortalSearch(api_key,key,ont['search_ont']).get_code_list()
            result.append(bps_inst)
        dict_agg[key] = result
        # report progress
        if verbose:
            print(f'finish search for term:{key}')
    # write single dictionary to json
    with open(f"{path_to_search_catalog}/{search_catalog_name.replace('input','output')}.json","w",encoding='utf-8') as writer: 
        dump(dict_agg, writer, ensure_ascii=False, indent=4)
