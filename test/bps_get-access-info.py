from json import load

path_to_key = "./.config/config.json"

def get_access_info():
    with open(path_to_key) as config_file:
            key = load(config_file)
    return(key)

key = get_access_info()

print(key)
print(key['bioportal']['url'])
print(key['bioportal']['api_key'])


