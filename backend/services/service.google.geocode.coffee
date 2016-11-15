through = require 'through2'
logger = require('../config/logger').spawn('service:google:geocode')
util = require 'util'
googleService = require './service.google'
errors = require '../utils/errors/util.errors.fipsCodesLocality'
geojson = require 'geojson'
{crsFactory} = require '../../common/utils/enums/util.enums.map.coord_system'

geoCodeFactory = () ->
  googleService.getGoogleClient(api: 'geocode')

localityObjectsStream = (fipsCodeStream) ->

  geoCodeFactory()
  .then (geocode) ->

    setLocality = (row, encoding, cb) ->
      # Making sure to add the word County in the address search as it produces better results
      # as it limits the confusion between towns and counties.
      address = "#{row.county.replace(/county/ig,'')} County, #{row.state}"

      fipsCode = row.code
      logger.debug -> "Attempting to geocode fipsCode: #{fipsCode}, address: #{address}"

      geocode({address})
      .asPromise()
      .then (response) =>
        if response.json.error_message?
          return cb(new errors.Message(row, response.json.error_message))

        # logger.debug -> 'response'
        # logger.debug -> response
        if response.json?.results?.length
          logger.debug -> 'response.json.results'
          result = response.json.results[0]
          result.fips_code = row.code
          result.origin =
            county: row.county
            state: row.state

          logger.debug -> util.inspect result, 3
          @push(result)
          return cb()

        cb(new errors.NoResults(row,'Empty Results'))

    return fipsCodeStream.pipe(through.obj(setLocality))

normalize = (rawRow = {}) ->
  crs = crsFactory()
  doThrows = invalidGeometry: true
  isPostgres = true

  {json, rm_raw_id, rm_error_msg} = rawRow
  if rm_error_msg
    throw new errors.HasRawError(rawRow)

  json = JSON.parse(json)

  try
    split = json.formatted_address.split(',')
    if split.length < 2
      throw new Error "County and State split missing. To resolve you may want to add 'county' to #{json.origin.county} to become '#{json.origin.county} County'."
    [county, state] = split
    county = county.replace(/county/ig, '')
    state = state.replace(/\d/g, '').replace(/\s/g, '')

    geometry_center = geojson.parse(
      json.geometry.location, {
        #yeilds:[lng, lat], I tried the reverse Point: ['lng', 'lat'] and it yeilded [lat, lng] , not intuitive
        Point: ['lat', 'lng']
        doThrows
        crs
        isPostgres
      }
    )

    bounds = json.geometry.bounds || json.geometry.viewport

    if bounds?
      geometry = geojson.parse(bounds, {
        Polygon:
          northeast: ['lat', 'lng']
          southwest: ['lat', 'lng']
        doThrows
        crs
        isPostgres
      })
    code = json.fips_code
  catch e
    throw new errors.NormalizeError(rawRow, e)

  return {rm_raw_id, county, state, geometry_center, geometry, code}


normalizeTransform = through.obj (rawRow, encoding, cb) ->
  try
    @push(normalize(rawRow))
    cb()
  catch error
    cb(error)

module.exports = {
  geoCodeFactory
  localityObjectsStream
  normalize
  normalizeTransform
}
