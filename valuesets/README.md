## About BioPortal
- [bioportal](https://bioportal.bioontology.org/) 
- [biopoartal API](http://data.bioontology.org/documentation#nav_usage)
- [NCBO wiki](https://www.bioontology.org/wiki/Main_Page)
- [RestAPI Get Reuqest Sample codes](https://github.com/ncbo/ncbo_rest_sample_code)
- [UMLS Semantic Type](https://gist.github.com/joelkuiper/4869d148333f279c2b2e)
- [URI Component Encoder and Encoder](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURI)

## How To Search
Search file contains the following two columns:
- search_term: key terms to be searched, no acronyms, all lower cases
- search_ont: target ontology you want to the term to be searched under
- one search_term could have multiple rows with respect to different ontologies
- to increase search accuracy, make sure to follow the following rules: 
    - use more generic medical terms ([sample references](https://www.health.harvard.edu/diagnostic-tests-and-medical-procedures))
    - procedure first, body system second

## Need To Know
API Call limits: 
- throttle API requests at 15 per second per IP address. We don’t disable accounts that exceed the limit, instead issuing a “429 Too Many Requests” response code.

Glossary: 
- tui: type unique identifier, or full semantic type name. See [UMLS Semantic Type](https://gist.github.com/joelkuiper/4869d148333f279c2b2e) for full list