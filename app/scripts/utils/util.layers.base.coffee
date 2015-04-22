httpSync = require './util.httpSync.coffee'
googleStyles = require './styles/util.style.google.coffee'
googleOptions = _.extend {}, googleStyles
routes = require '../../../common/config/routes.backend.coffee'

_mapboxKey = httpSync.get routes.config.mapboxKey

_mapBoxFactory = (name, id) ->
  name: 'Mapbox ' + name
  url: 'http://api.tiles.mapbox.com/v4/{mapid}/{z}/{x}/{y}.png?access_token={apikey}'
  type: 'xyz'
  layerOptions:
    apikey: _mapboxKey
    mapid: id

_googleFactory = (name, type, options) ->
  ret =
    name: 'Google ' + name,
    layerType: type,
    type: 'google'

  if options? #see L.Google._initMapObject
    _.extend ret, layerOptions: options
  ret

module.exports =

  googleRoadmap: _googleFactory 'Streets', 'ROADMAP', mapOptions: googleOptions

  googleHybrid: _googleFactory 'Hybrid', 'HYBRID'

  googleTerrain: _googleFactory 'Terrain', 'TERRAIN'

  #example of custom map via an account
  mapbox_street: _mapBoxFactory 'Street', 'nmccready.k54j1lpg'

  mapbox_comic: _mapBoxFactory 'Comic', 'mapbox.comic'

  mapbox_dark: _mapBoxFactory 'Dark', 'mapbox.dark'

  #NOTE OSM does not support a zoomLevel higher than 20
  osm:
    name: 'OpenStreetMap',
    type: 'xyz',
    url: 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    layerOptions:
      subdomains: ['a', 'b', 'c'],
      attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      continuousWorld: true
