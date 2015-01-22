app = require '../app.coffee'
numeral = require 'numeral'
casing = require 'case'
moment = require 'moment'


# turns a duration object into a humanized string, but with '1' instead of 'a' for single units
_humanize = (duration) ->
  readable = duration.humanize()
  if readable[0] == 'a'
    return '1'+readable.substring(1)
  return readable
  
# turns a number and a plural unit into a string with singular or plural as appropriate
_humanizePartial = (val, unit) ->
  readable = "#{val} #{unit}"
  if val == 1
    return readable.slice(0,-1)
  return readable

app.service 'FormattersService'.ourNs(), [ 'Logger'.ourNs(), ($log) ->
  _json =
    readable: (json) ->
      JSON.stringify(json).replace(/"/g,'').replace(/:/g,': ').replace(/,/g,', ').replace('{','').replace('}','')
  #public
  JSON: _json
  Common:
    getYear: (time) ->
      moment(time).format('YYYY')

    getPrice: (price) ->
      if !price
        return 'N/A'
      numeral(price).format('$0,0')

    orNa: (val) ->
      String.orNA val
      
    # turns a json duration into a humanized string description e.g.:
    #   {days: 600} --> "about 1 year, 8 months"
    #   {years: 1, months: 0, days: 2} --> "about 1 year"
    humanizeDays: (sourceDays) ->
      if sourceDays <= 0
        return "less than 1 day"

      duration = moment.duration(sourceDays, "days")
      years = duration.get("years")
      months = duration.get("months")
      days = duration.get("days")
      
      if years > 0 and days >= 15
        months++
        days = 0
      if months == 12
        years++
        months = 0
      
      if years > 0
        result = "about #{_humanizePartial(years, "years")}"
        if months > 0
          result += ", #{_humanizePartial(months, "months")}"
      else if months > 0
        result = "#{_humanizePartial(months, "months")}"
        if days > 0
          result += ", #{_humanizePartial(days, "days")}"
      else if days > 0
        result = "#{_humanizePartial(days, "days")}"
      return result

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