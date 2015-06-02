Promise = require 'bluebird'
logger = require '../config/logger'
validation = require '../utils/util.validation'
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'
{validators} = require '../utils/util.validation'
_ = require 'lodash'
{getParcelJSON, getFormatedParcelJSON, uploadToParcelsDb} = require '../services/service.parcels.saver'
JSONStream = require 'JSONStream'
config = require '../config/config'
encryptor = new (require '../utils/util.encryptor')(cipherKey: config.ENCRYPTION_AT_REST)
db = require('../config/dbs').users

transforms =
    fipscode:
        transform: validators.string(minLength:1)
        required: true

_handleRes = (ret, res, isStream = true) ->
    if isStream
        return ret.pipe(JSONStream.stringify()).pipe(res)
    res.json(ret)

_getByFipsCode = (req, res, next, fn = getParcelJSON, isStream = true) ->
    Promise.try ->


        allParams = _.extend {}, req.params, req.query

        validation.validateAndTransform(allParams, transforms)
        .then (validParams) ->
            logger.debug validParams
            logger.debug 'running query'
            db.knex.select()
            .from('jq_task_config')
            .where(name:'parcel_update')
            .then (rows) ->
                logger.debug rows
                logger.debug 'ran query'
                return unless rows.length
                row = rows[0]
                logger.debug row
                for k, val of row.data.DIGIMAPS
                    row.data.DIGIMAPS[k] = encryptor.decrypt(val)
                fn(validParams.fipscode, row.data.DIGIMAPS)
                .then (s) ->
                    _handleRes(s, res, isStream)

    .catch validation.DataValidationError, (err) ->
        next new ExpressResponse(alert: {msg: err.message}, httpStatus.BAD_REQUEST)
    .catch (error) ->
        if _.isString error
            return next new ExpressResponse(alert: {msg: "#{error} for #{req.path}."}, httpStatus[error])
        throw error

module.exports =
    getByFipsCode: _getByFipsCode
    getByFipsCodeFormatted: (req, res, next) ->
        _getByFipsCode(req, res, next, getFormatedParcelJSON)
    uploadToParcelsDb: (req, res, next) ->
        _getByFipsCode(req, res, next, uploadToParcelsDb, false)
