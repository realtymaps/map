Promise = require 'bluebird'
logger = require '../config/logger'
validation = require '../utils/util.validation'
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'
{validators} = require '../utils/util.validation'
_ = require 'lodash'
{getParcelJSON} = require '../services/service.parcels.saver'
JSONStream = require 'JSONStream'

transforms =
    fipscode:
        transform: validators.string(minLength:1)
        required: true

_getByFipsCode = (req, res, next) ->
    Promise.try ->
        allParams = _.extend {}, req.params, req.query

        validation.validateAndTransform(allParams, transforms)
        .then (validParams) ->
            logger.debug validParams
            getParcelJSON(validParams.fipscode)
            .then (s) ->
                s.pipe(JSONStream.stringify()).pipe(res)
    .catch validation.DataValidationError, (err) ->
        next new ExpressResponse(alert: {msg: err.message}, httpStatus.BAD_REQUEST)
    .catch (error) ->
        if _.isString error
            return next new ExpressResponse(alert: {msg: "#{error} for #{req.path}."}, httpStatus[error])
        throw error

module.exports =
    getByFipsCode: _getByFipsCode
