Promise = require 'bluebird'
logger = require '../config/logger'
validation = require '../utils/util.validation'
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'
{validators} = require '../utils/util.validation'
_ = require 'lodash'
{getParcelJSON, getFormatedParcelJSON, uploadToParcelsDb} = require '../services/service.parcels.saver'
{defineImports} = require '../services/service.parcels.fetcher.digimaps'
getDigiCreds =  require '../utils/util.digimaps.creds'
uuid = require 'uuid'

JSONStream = require 'JSONStream'


transforms =
    fipscode:
        transform: validators.string(minLength:1)
        required: true
    fullpath:
        transform: validators.string(minLength:1)
        required: true


_handleRes = (ret, res, isStream = true) ->
    if isStream
        return ret.pipe(JSONStream.stringify()).pipe(res)
    res.json(ret)

_getByFipsCode = (req, res, next, fn = getParcelJSON, isStream = true) -> Promise.try ->
    allParams = _.extend {}, req.params, req.query

    validation.validateAndTransform(allParams, transforms)
    .then (validParams) ->
        getCredentials().then (creds) ->
            logger.debug validParams.fullpath
            fn(validParams.fipscode, validParams.fullpath, creds)
            .then (s) ->
                _handleRes(s, res, isStream)

    .catch validation.DataValidationError, (err) ->
        next new ExpressResponse(alert: {msg: err.message}, httpStatus.BAD_REQUEST)
    .catch (error) ->
        if _.isString error
            return next new ExpressResponse(alert: {msg: "#{error} for #{req.path}."}, httpStatus.NOT_FOUND)
        throw error

module.exports =
    getByFipsCode: _getByFipsCode
    getByFipsCodeFormatted: (req, res, next) ->
        _getByFipsCode(req, res, next, getFormatedParcelJSON)
    uploadToParcelsDb: (req, res, next) ->
        _getByFipsCode(req, res, next, uploadToParcelsDb, false)
    defineImports: (req, res, next) -> Promise.try ->
        logger.debug 'defineImports for digimaps_parcel_imports'
        logger.debug 'getting creds'
        getDigiCreds()
        .then (creds) ->
            #Basically create a mock subtask to satisfy all of defineImports deps
            defineImports(
                task_name: 'digimaps_define_imports_route'
                batch_id: uuid.v4()
            ,creds)
        .then (result) ->
            res.json(result)
        .catch validation.DataValidationError, (err) ->
            next new ExpressResponse(alert: {msg: err.message}, httpStatus.BAD_REQUEST)
        .catch (error) ->
            if _.isString error
                return next new ExpressResponse(alert: {msg: "#{error} for #{req.path}."}, httpStatus[error])
            throw error
