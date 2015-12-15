_lng = -81.80125951766968
_lat = 26.221501806466513
filterSummary =
  route: "/api/properties/filter_summary/"
  geojsonPolys: require './geojsonPolys.json'
  clusterOrDefault: require './clusterOrDefault.json'

module.exports =
  filterSummary: filterSummary
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
