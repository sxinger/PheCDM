from json import load,loads,dump
from re import search
import urllib.request, urllib.error, urllib.parse
# import requests #better library for API call
import time
import pandas as pd
from regex import F

def get_access_info(path_to_key):
    with open(path_to_key) as config_file:
        key = load(config_file)
    return(key)
