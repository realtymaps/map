_lng = -81.80125951766968
_lat = 26.221501806466513
geojsonPolys =
  route: "/api/properties/filter_summary/"
  response: require './geojsonPolys.json'

clusterOrDefault =
  route: "/api/properties/filter_summary/"
  response: require './clusterOrDefault.json'

module.exports =
  geojsonPolys: geojsonPolys
  clusterOrDefault: clusterOrDefault
  hash: 'wt~~CjojrNglB_lD'
  zoom: 16
  mapState:
    map_position:
      center:
        lng: _lng
        lat: _lat
        lon: _lng
        latitude: _lat
        longitude: _lng
      zoom:16
      autoDiscover:false
    map_toggles:
      showResults:true
      showDetails:false
      showFilters:false
      showSearch:false
      isFetchingLocation:false
      hasPreviousLocation:false
      showAddresses:true
      showPrices:true
      showLayerPanel:false
    map_results:
      selectedResultId: "12021_15955040003_001"
