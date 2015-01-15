db = require('../config/dbs').properties
model = require '../models/model.propertyDetail'
Promise = require 'bluebird'
logger = require '../config/logger'
requestUtil = require '../utils/util.http.request'
sqlHelpers = require './../utils/util.sql.helpers'
validators = requestUtil.query.validators
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'

transforms =
  rm_property_id:  validators.string(minLength: 1)

#required with default values
required =
  rm_property_id: undefined

module.exports =

  getDetail: (state, request, next) -> Promise.try () ->
    requestUtil.query.validateAndTransform(request, transforms, required)
    .then (request) ->

      query = db.knex
      .select().from(sqlHelpers.tableName(model))
      .where(rm_property_id: request.rm_property_id)
      .limit(1)

      #logger.sql query.toString()

      query.then (data) ->
        if not data or not data.length
          return next new ExpressResponse("property with id #{request.rm_property_id} not found", httpStatus.NOT_FOUND)
        return data[0]
