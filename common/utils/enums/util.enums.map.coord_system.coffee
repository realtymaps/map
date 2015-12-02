WGS84 =  '4326'
UTM = '26910'

EARTH_MEAN_RADIUS_METERS = 6.371 * Math.pow(10,6)
METERS_PER_EARTH_RADIUS = EARTH_MEAN_RADIUS_METERS * Math.PI/180
#(Earth mean radius)*PI/180

module.exports =
  distance:
    EARTH_MEAN_RADIUS_METERS: EARTH_MEAN_RADIUS_METERS
    METERS_PER_EARTH_RADIUS: METERS_PER_EARTH_RADIUS
  WGS84: WGS84
  UTM: UTM
  crsFactory: (EPSG = UTM) ->
    if typeof EPSG != 'string'
      EPSG = UTM
    type: 'name'
    properties:
      name: "EPSG:#{EPSG}"
