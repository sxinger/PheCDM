import bioportal_api_get as bps
import numpy as np
import pandas as pd

# get api key
api_key=bps.get_access_info("./.config/config.json")['bioportal']['api-key']

# generate a bps batch write instance
# bps.batch_write_vs_excel(
#      api_key
#     ,'C:/repo/PheCDM/valuesets/valueset_autogen'
#     ,'als-tx_input'
#     )

# bps.batch_write_vs_excel(
#      api_key
#     ,'C:/repo/PheCDM/valuesets/valueset_autogen'
#     ,'als-dx_input'
#     )

# bps.batch_write_vs_json(
#      api_key
#     ,'C:/repo/PheCDM/valuesets/valueset_autogen'
#     ,'als-dx_input'
#     )


bps.batch_write_vs_json(
     api_key
    ,'C:/repo/PheCDM/valuesets/valueset_autogen'
    ,'als-tx_input'
    )