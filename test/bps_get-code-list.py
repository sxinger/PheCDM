from json import loads 
import urllib.request, urllib.error, urllib.parse
import time

API_URL = 'http://data.bioontology.org'
api_key = 'acee53f2-26bc-4e89-aafc-db37c7e4c292'
sterm = 'white blood count'
sont = 'LOINC'

def get_json(url):
        opener = urllib.request.build_opener()
        opener.addheaders = [('Authorization', 'apikey token=' + api_key)]
        return loads(opener.open(url).read())

def get_code_list(sterm,sont) -> dict:
        '''
        parse returned json file and return as tabular data
        '''
        labels = [] 
        tuis = []
        cuis = []
        ids = [] 
        out = dict()       
        
        sterm = sterm.replace(' ','+')
        result = get_json(f'{API_URL}/search?q={sterm}&ontologies={sont}')
        page = 1
        next_page = page 
        while next_page:
            '''loop over all items in the collection list'''
            for cls in result["collection"]:
                labels.append(cls["prefLabel"])
                tuis.append(';'.join(cls.get("semanticType","NA")))
                cuis.append(';'.join(cls.get("cui","NA")))
                ids.append(cls["@id"].rsplit('/', 1)[-1])

            '''go to next page'''
            next_page = result["nextPage"]
            page_url = result["links"]["nextPage"]
            time.sleep(3)
            try: 
                result = get_json(page_url)
            except:
                pass

        out = [labels,tuis,cuis,ids]
        return out


get_code_list_inst = get_code_list(sterm, sont)
print(get_code_list_inst)
