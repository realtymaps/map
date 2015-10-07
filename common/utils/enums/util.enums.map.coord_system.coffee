WGS84 =  '4326'
UTM = '26910'

module.exports =
  WGS84: WGS84
  UTM: UTM
  crsFactory: (EPSG = UTM) ->
    type: 'name'
    properties:
      name: "EPSG:#{EPSG}"
