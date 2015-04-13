module.exports =
  #TODO add MapBox layers

  googleRoadmap:
    name: 'Google Streets'
    layerType: 'ROADMAP'
    type: 'google'

  googleHybrid:
    name: 'Google Hybrid'
    layerType: 'HYBRID'
    type: 'google'

  #NOTE OSM does not support a zoomLevel higher than 20
  osm:
    name: 'OpenStreetMap',
    type: 'xyz',
    url: 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    layerOptions:
      subdomains: ['a', 'b', 'c'],
      attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      continuousWorld: true

  googleSatellite:
    name: 'Google Satellite',
    layerType: 'SATELLITE',
    type: 'google'

  googleTerrain:
    name: 'Google Terrain'
    layerType: 'TERRAIN'
    type: 'google'
