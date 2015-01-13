db = require('../config/dbs').properties
model = require "../models/model.propertyDetail.coffee"
Promise = require "bluebird"
logger = require '../config/logger'
requestUtil = require '../utils/util.http.request'
validators = requestUtil.query.validators

transforms =
  rm_property_id:  validators.string(minLength: 1)

#required with default values
required =
  rm_property_id: undefined

module.exports =

  getDetail: (state, request) -> Promise.try () ->
    requestUtil.query.validateAndTransform(request, transforms, required)
    .then (rm_property_id) ->
      query = db.knex.select().from(sqlHelpers.tableName(model))
      query.where(rm_property_id: rm_property_id)
      query.limit(1)  # TODO: if there are multiple, we just grab one... revisit once we deal with multi-unti parcels
      query.then (data) ->
        return data?[0]
