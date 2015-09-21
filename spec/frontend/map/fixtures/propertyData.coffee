###
TODO: REFACTOR
The fact all this position data is sent as an URL is rediculous the was the whole point of
bounds via googles hashing of geohash64

Both position and zoom can be sent via that which can eliminate the entire map_position obj.
###
geojsonPolys =
  route: """api/properties/filter_summary/?
    bounds=wt~~CjojrNglB_lD
    &returnType=geojsonPolys
    &status%5B0%5D=for%20sale
    &status%5B1%5D=pending
    &status%5B2%5D=recently%20sold
    &map_position%5Bcenter%5D%5Blng%5D=-81.80125951766968
    &map_position%5Bcenter%5D%5Blat%5D=26.221501806466513
    &map_position%5Bcenter%5D%5Blon%5D=-81.8043242553263
    &map_position%5Bcenter%5D%5Blatitude%5D=26.2209050698381
    &map_position%5Bcenter%5D%5Blongitude%5D=-81.8043242553263
    &map_position%5Bcenter%5D%5Bzoom%5D=16
    &map_position%5Bcenter%5D%5BautoDiscover%5D=false
    &map_toggles%5BshowResults%5D=true
    &map_toggles%5BshowDetails%5D=false
    &map_toggles%5BshowFilters%5D=false
    &map_toggles%5BshowSearch%5D=false
    &map_toggles%5BisFetchingLocation%5D=false
    &map_toggles%5BhasPreviousLocation%5D=false
    &map_toggles%5BshowAddresses%5D=true
    &map_toggles%5BshowPrices%5D=true
    &map_toggles%5BshowLayerPanel%5D=false
    &map_results%5BselectedResultId%5D=12021_15955040003_001"""

  response: require './geojsonPolys.json'


clusterOrDefault =
  route: """api/properties/filter_summary/?
    bounds=wt~~CjojrNglB_lD
    &returnType=clusterOrDefault
    &status%5B0%5D=for%20sale
    &status%5B1%5D=pending
    &status%5B2%5D=recently%20sold
    &map_position%5Bcenter%5D%5Blng%5D=-81.80125951766968
    &map_position%5Bcenter%5D%5Blat%5D=26.221501806466513
    &map_position%5Bcenter%5D%5Blon%5D=-81.8043242553263
    &map_position%5Bcenter%5D%5Blatitude%5D=26.2209050698381
    &map_position%5Bcenter%5D%5Blongitude%5D=-81.8043242553263
    &map_position%5Bcenter%5D%5Bzoom%5D=16
    &map_position%5Bcenter%5D%5BautoDiscover%5D=false
    &map_toggles%5BshowResults%5D=true
    &map_toggles%5BshowDetails%5D=false
    &map_toggles%5BshowFilters%5D=false
    &map_toggles%5BshowSearch%5D=false
    &map_toggles%5BisFetchingLocation%5D=false
    &map_toggles%5BhasPreviousLocation%5D=false
    &map_toggles%5BshowAddresses%5D=true
    &map_toggles%5BshowPrices%5D=true&map_toggles%5BshowLayerPanel%5D=false
    &map_results%5BselectedResultId%5D=12021_15955040003_001"""

  response: require './clusterOrDefault.json'

module.exports =
  geojsonPolys: geojsonPolys
  clusterOrDefault: clusterOrDefault
  hash: 'wt~~CjojrNglB_lD'
