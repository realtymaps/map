app = require '../app.coffee'
numeral = require 'numeral'
casing = require 'case'
moment = require 'moment'


# must be ordered from largest to smallest
units = [
  'years'
  'months'
  'days'
]

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
      
    # turns a json duration into a humanized string description using the biggest applicable duration and
    # the next biggest duration (rounded), if it has a non-zero value.  e.g.:
    #   {days: 600} --> "about 1 year, 8 months"
    #   {years: 1, months: 0, days: 2} --> "about 1 year"
    # JWI: this code is a little more complicated than it probably has to be, because I started with writing something
    # that could handle date-time durations, not just date durations, but after my struggles with moment (see below)
    # and then realizing we currently only get creation date and close date, not timestamps, I took some shortcuts
    # that are specific to dealing with only year-month-day units, but didn't want to take the time to refactor this
    # function again.  I've spent too much time on it already, and it works for dates, so I'm moving on.
    humanizeDays: (days) ->
      duration = moment.duration(days, "days")
      for unit,i in units
        val = duration.get(unit)
        if val > 0
          result = "#{_humanizePartial(val, unit)}"
          if unit == "years"
            result = "about "+result
          if units[i+1] && duration.get(units[i+1])
            # the below is an awkward way to get the remaining duration excluding the partial above, but we can't trust
            # duration math to be consistent any other way: https://github.com/moment/moment/issues/2166
            remainingDurationJson = {}
            for unit2,j in units
              if j<=i
                continue
              remainingDurationJson[unit2] = duration.get(unit2)
            duration = moment.duration(remainingDurationJson)
            result += ", #{_humanize(duration)}"
          return result
      return "less than 1 day"

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