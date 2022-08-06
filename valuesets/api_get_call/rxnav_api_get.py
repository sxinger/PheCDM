from json import load,loads,dump
from re import search
import os
import requests
import pandas as pd
import api_call_utils as apiutil

# Authentication
url = apiutil.get_access_info()['vsac-api']['auth-url']
tgt_endpoint = apiutil.get_access_info()['vsac-api']['auth-url']
apikey = apiutil.get_access_info()['vsac-api']['api-key']
apiutil.two_factor_auth(url,tgt_endpoint)

# 