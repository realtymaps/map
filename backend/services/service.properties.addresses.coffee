db = require('../config/dbs').properties
Promise = require 'bluebird'
logger = require '../config/logger'
geohashHelper = require '../utils/validation/util.validation.geohash'
validation = require '../utils/util.validation'
{select, tableName, whereInBounds} = require './../utils/util.sql.helpers.coffee'
indexBy = require '../../common/utils/util.indexByWLength'
_ = require 'lodash'
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
      return getBaseParcelQueryByBounds(filters.bounds, 500)
    .then (data) ->
      obj = {}
      #hack for unique markerid on address markers (NEED TO FIX IN LEAFLET Marker Directive)
      data.forEach (val) ->
        val.type = val.geom_point_json.type
        val.coordinates = val.geom_point_json.coordinates
        obj['addr' + val.rm_property_id] = val
        delete val.geom_point_json
      # logger.debug obj, true
      obj
