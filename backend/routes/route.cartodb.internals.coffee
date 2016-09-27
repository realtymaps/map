_ = require 'lodash'
cartodbConfig = require '../config/cartodb/cartodb'
cartodbService = require '../services/service.cartodb'
validation = require '../utils/util.validation'
transforms = require '../utils/transforms/transform.cartodb'
streamUtil = require '../utils/util.streams'
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'
logger = require('../config/logger').spawn("route:cartodb:internals")

getByFipsCode = (req, res, next, headersCb) ->
  Promise.try ->
    allParams = _.extend {}, req.params, req.query

    validation.validateAndTransformRequest(allParams, transforms)
    .then (validParams) ->
      headersCb(validParams, res) if headersCb
      # logger.debug(req, true)
      cartodbConfig()
      .then (config) ->
        if validParams?.api_key != config.API_KEY_TO_US
          throw new Error('UNAUTHORIZED')
        if !validParams.fips_code?
          throw new Error('BADREQUEST')
      .then () ->
        cartodbService.getByFipsCode(validParams)
        .stream()
        .pipe(streamUtil.geoJsonFormatter([
          'rm_property_id'
          'street_address_num'
          'is_active'
          'fips_code'
          'num_updates'
        ]))
        .pipe(res)

  .catch validation.DataValidationError, (err) ->
    next new ExpressResponse({alert: {msg: err.message}}, {status: httpStatus.BAD_REQUEST, quiet: err.quiet})
  .catch (error) ->
    # we shouldn't be throwing strings!!  see: http://www.devthought.com/2011/12/22/a-string-is-not-an-error/
    if _.isString error
      return next new ExpressResponse({alert: {msg: "#{error} for #{req.path}."}}, {status: httpStatus[error]})
    throw error


module.exports = {
  getByFipsCode
}
