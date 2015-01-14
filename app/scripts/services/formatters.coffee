app = require '../app.coffee'
numeral = require 'numeral'
casing = require 'case'
moment = require 'moment'

app.service 'FormattersService'.ourNs(), [ 'Logger'.ourNs(), ($log) ->
  _json =
    readable: (json) ->
      JSON.stringify(json).replace(/"/g,'').replace(/:/g,': ').replace(/,/g,', ').replace('{','').replace('}','')
  #public
  JSON: _json
  Common:
    getYear:(time) ->
      moment(time).format('YYYY')

    getPrice: (price) ->
      numeral(price).format('$0,0.00')

    orNa: (val) ->
      String.orNA val

    getInterval: (val) ->
      #could use _json readable if the format is always { years: 1, months: 1, days: 1}
      return '' unless val
      ['years', 'months', 'days'].map (slice) ->
        return unless val[slice]?
        slice
      .filter((s) -> s?).reduce (prev, next) ->
        return "#{next}: #{val[next]}" unless prev
        "#{prev}, #{next}: #{val[next]}"
      , ''

  Google:
    getCurbsideImage: (geoObj) ->
      return 'http://placehold.it/100x75' unless geoObj
      lonLat = geoObj.geom_point_json.coordinates
      "http://cbk0.google.com/cbk?output=thumbnail&w=100&h=75&ll=#{lonLat[1]},#{lonLat[0]}&thumb=1"

    getStreetView: (geoObj, width, height, fov = '90', heading = '', pitch = '10', sensor = 'false') ->
      # https://developers.google.com/maps/documentation/javascript/reference#StreetViewPanorama
      # heading is better left as undefined as google figures out the best heading based on the lat lon target
      # we might want to consider going through the api which will gives us URL
      if heading
        heading = "&heading=#{heading}"
      return unless geoObj
      lonLat = geoObj.geom_point_json.coordinates
      "http://maps.googleapis.com/maps/api/streetview?size=#{width}x#{height}" +
      "&location=#{lonLat[1]},#{lonLat[0]}" +
      "&fov=#{fov}#{heading}&pitch=#{pitch}&sensor=#{sensor}"
]