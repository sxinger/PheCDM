import bioportal_api_get as bps
import numpy as np
import pandas as pd

# get api key
api_key=bps.get_access_info("./.config/config.json")['bioportal']['api_key']

# generate a bps batch write instance
bps.batch_write_code_list(
     api_key
    ,'C:/repo/PheCDM/concept_set/autogen_set'
    ,'als-endpoint_input'
    )

bps.batch_write_code_list(
     api_key
    ,'C:/repo/PheCDM/concept_set/autogen_set'
    ,'als-diagnostic_input'
    )
