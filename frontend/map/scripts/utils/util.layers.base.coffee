app = require '../app.coffee'

###globals _###
# googleStyles = require './styles/style.google.json'
# googleOptions = _.extend {}, styles: googleStyles
backendRoutes = require '../../../../common/config/routes.backend.coffee'
analyzeValue = require '../../../../common/utils/util.analyzeValue.coffee'

_mapboxKey = ''

_mapBoxClassic = (name, id) ->
  name: 'Mapbox ' + name
  url: 'http://api.tiles.mapbox.com/v4/{mapid}/{z}/{x}/{y}.png?access_token={apikey}'
  type: 'xyz'
  layerOptions:
    apikey: _mapboxKey
    mapid: id
    maxZoom: 21

_mapBoxStyle = (name, id) ->
  name: 'Mapbox ' + name
  url: 'http://api.mapbox.com/styles/v1/mapbox/{mapid}/tiles/256/{z}/{x}/{y}?access_token={apikey}'
  type: 'xyz'
  layerOptions:
    apikey: _mapboxKey
    mapid: id
    maxZoom: 21

_googleFactory = (name, type, options) ->
  ret =
    name: 'Google ' + name,
    layerType: type,
    type: 'google'

  if options? #see L.Google._initMapObject
    _.extend ret, layerOptions: options
  ret

_baseLayers =
  # googleRoadmap: _googleFactory 'Streets', 'ROADMAP', mapOptions: googleOptions
  googleHybrid: _googleFactory 'Hybrid', 'HYBRID'

app.factory 'rmapsUtilLayersBase', ($http, $rootScope, rmapsEventConstants) ->
  $http.getData(backendRoutes.config.protectedConfig)
  .then ({mapbox} = {}) ->
    _mapboxKey = mapbox

    if _mapboxKey
      _baseLayers.mapbox_street = _mapBoxClassic 'Street', 'realtymaps.f33ce76e'
      _baseLayers.mapbox_street.top = true
      _baseLayers.mapbox_street_style = _mapBoxStyle 'Style Street', 'streets-v9'


      _baseLayers.mapbox_street_gybrid = _mapBoxStyle 'MapBox Sat Street', 'satellite-streets-v9'
      _baseLayers.mapbox_comic =  _mapBoxClassic 'Comic', 'mapbox.comic'
      _baseLayers.mapbox_light = _mapBoxStyle 'Light', 'light-v9'
      _baseLayers.mapbox_dark = _mapBoxStyle 'Dark', 'dark-v9'


    _baseLayers
  .catch (err) ->
    msgPart = analyzeValue err
    $rootScope.$emit rmapsEventConstants.alert.spawn, msg: "Overlays failed to load with error #{msgPart}."
