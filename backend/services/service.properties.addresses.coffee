Promise = require 'bluebird'
logger = require '../config/logger'
validation = require '../utils/util.validation'
{getBaseParcelQueryByBounds} = require './service.properties.parcels'


validators = validation.validators

transforms =
  bounds:
    transform: [
      validators.string(minLength: 1)
      validators.geohash
      validators.array(minLength: 2)
    ]
    required: true


module.exports =

  get: (state, filters) -> Promise.try () ->
    validation.validateAndTransform(filters, transforms)
    .then (filters) ->
      return getBaseParcelQueryByBounds({bounds: filters.bounds, limit: 500})
    .then (data) ->
      obj = {}
      #hack for unique markerid on address markers (NEED TO FIX IN LEAFLET Marker Directive)
      data.forEach (val) ->
        val.type = val.geometry_center.type
        val.coordinates = val.geometry_center.coordinates
        obj['addr' + val.rm_property_id] = val
        delete val.geometry_center
      # logger.debug obj, true
      obj
