Promise = require 'bluebird'
logger = require '../config/logger'
validation = require '../utils/util.validation'
{getByFipsCode} = require('../services/service.cartodb').restful
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'
_ = require 'lodash'
JSONStream = require 'JSONStream'
{validators} = require '../utils/util.validation'
{geoJsonFormatter} = require '../utils/util.streams'
auth = require '../utils/util.auth'

transforms =
  nesw:
    transform: validators.neSwBounds
    required: false
  fipscode:
    transform: validators.string(minLength:1)
    required: true
  limit: validators.integer()
  start_rm_property_id: validators.string(minLength: 5)
  api_key:
    transform: [
      validators.string(minLength: 36)
      validators.string(maxLength: 36)
    ]
    required: true

_getByFipsCode = (req, res, next, headersCb) ->
  Promise.try ->
    allParams = _.extend {}, req.params, req.query

    validation.validateAndTransformRequest(allParams, transforms)
    .then (validParams) ->
      headersCb(validParams, res) if headersCb
      # logger.debug(req, true)
      getByFipsCode(validParams)
      .stream()
      .pipe(geoJsonFormatter([
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


module.exports =
    getByFipsCodeAsFile:
      method: 'get'
      handle: (req, res, next) ->
        _getByFipsCode req, res, next, (validParams,res) ->
          dispistion = "attachment; filename=#{req.params.fipscode}"
          #if we have options set them to the file name seperated by "-"
          #fipscode-rm_property_id-limit.json
          if validParams.fipscode? #error handled in service
            ['start_rm_property_id', 'limit'].forEach (prop) ->
              if validParams[prop]?
                dispistion += "-#{validParams[prop]}"
            res.setHeader 'Content-disposition', dispistion + '.json'
            res.setHeader 'Content-type', 'application/json'

    getByFipsCodeAsStream:
      method: 'get'
      handle: (req, res, next) ->
        #limiting the size since this endppoint is for testing
        # req.query.limit = 100
        _getByFipsCode req, res, next
