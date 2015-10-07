Promise = require 'bluebird'
logger = require '../config/logger'
validation = require '../utils/util.validation'
sqlHelpers = require './../utils/util.sql.helpers'
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'
tables = require '../config/tables'

columnSets = ['filter', 'address', 'detail', 'all']

transforms =
  rm_property_id:
    transform: validation.validators.string(minLength: 1)
    required: true
  columns:
    transform: validation.validators.choice(choices: columnSets)
    required: true

module.exports =

  getDetail: (request) -> Promise.try () ->
    validation.validateAndTransform(request, transforms)
    .then (parameters) ->

      query = sqlHelpers.select(tables.property.propertyDetails(), parameters.columns)
      .where(rm_property_id: parameters.rm_property_id)
      .limit(1)

      #logger.sql query.toString()

      query.then (data) ->
        return data?[0]
