db = require('../config/dbs').properties
PropertyDetails = require '../models/model.propertyDetails.coffee'
Promise = require 'bluebird'
logger = require '../config/logger'
validation = require '../utils/util.validation'
sqlHelpers = require './../utils/util.sql.helpers'
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'

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

      query = sqlHelpers.select(db.knex, parameters.columns)
      .from(sqlHelpers.tableName(PropertyDetails))
      .where(rm_property_id: parameters.rm_property_id)
      .limit(1)

      #logger.sql query.toString()

      query.then (data) ->
        return data?[0]
