_ = require 'lodash'
Promise = require 'bluebird'
cartodbConfig = require '../config/cartodb/cartodb'
cartodbService = require '../services/service.cartodb'
validation = require '../utils/util.validation'
transforms = require '../utils/transforms/transform.cartodb'
streamUtil = require '../utils/util.streams'
httpStatus = require '../../common/utils/httpStatus'
logger = require('../config/logger').spawn("route:cartodb:internals")
{PartiallyHandledError} = require '../utils/errors/util.error.partiallyHandledError'


getByFipsCode = (req, res, next, headersCb) ->
  Promise.try ->
    allParams = _.extend {}, req.params, req.query

    logger.debug -> "allParams"
    logger.debug -> allParams

    validation.validateAndTransformRequest(allParams, transforms)
    .then (validParams) ->
      logger.debug -> "validParams"
      logger.debug -> validParams

      if headersCb
        headersCb(validParams, res)
      # logger.debug(req, true)
      cartodbConfig()
      .then (config) ->
        logger.debug -> "config.API_KEY_TO_US"
        logger.debug -> config.API_KEY_TO_US
        if validParams?.api_key != config.API_KEY_TO_US
          throw new PartiallyHandledError('ApiKeyError', {returnStatus: httpStatus.UNAUTHORIZED}, "bad API key given: #{validParams?.api_key}")
      .then () ->
        cartodbService.getByFipsCode(validParams).stream()
        .pipe(streamUtil.geoJsonFormatter([
          'rm_property_id'
          'street_address_num'
          'is_active'
          'fips_code'
          'num_updates'
        ]))
        .pipe(res)

  .catch validation.DataValidationError, (err) ->
    throw new PartiallyHandledError(err, 'error interpreting query string parameters')
  .catch _.isString, (err) ->
    # we shouldn't be throwing strings!!  see: http://www.devthought.com/2011/12/22/a-string-is-not-an-error/
    throw new Error(err)


module.exports = {
  getByFipsCode
}
