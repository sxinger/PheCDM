from json import loads 
import urllib.request, urllib.error, urllib.parse

API_URL = 'http://data.bioontology.org'
api_key = 'acee53f2-26bc-4e89-aafc-db37c7e4c292'
sterm = 'ulcerative+colitis'
sont = 'ICD10'

def get_json(url):
        opener = urllib.request.build_opener()
        opener.addheaders = [('Authorization', 'apikey token=' + api_key)]
        return loads(opener.open(url).read())

get_json_inst = get_json(f'{API_URL}/search?q={sterm}&ontologies={sont}')

print(get_json_inst["totalCount"])
print(get_json_inst["nextPage"])
print(get_json_inst["collection"][1]["links"]["self"])
