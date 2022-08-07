import api_get_bioportal as apibp
import api_get_rxnav as apirxnav

# diagnostics 
# apibp.batch_write_vs_json(
#      'C:/repo/PheCDM/valuesets/valueset_autogen'
#     ,'als-dx_input'
#     )

# # real world endpoints
# apibp.batch_write_vs_json(
#      'C:/repo/PheCDM/valuesets/valueset_autogen'
#     ,'als-tx_input'
#     )

# medications
sterms = ['riluzole']
apirxnav.batch_write_ndc_json('C:/repo/PheCDM/valuesets/valueset_autogen',
                              'als-rx_output',sterms)
     