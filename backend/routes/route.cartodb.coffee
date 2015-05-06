Promise = require 'bluebird'
logger = require '../config/logger'
validation = require '../utils/util.validation'
{getByFipsCode} = require('../services/service.cartodb').restful
ExpressResponse = require '../utils/util.expressResponse'
httpStatus = require '../../common/utils/httpStatus'
_ = require 'lodash'
JSONStream = require 'JSONStream'

_getByFipsCode = (req, res, next, headersCb) ->
  Promise.try ->
    headersCb(req, res) if headersCb
    # logger.debug(req, true)
    getByFipsCode(_.extend {}, req.params, req.query)
    .stream()
    .pipe(JSONStream.stringify())
    .pipe(res)
    # .then (data) ->
      # res.json(data)

  .catch (error) ->
    if _.isString error
      return next new ExpressResponse(alert: {msg: "#{error} for #{req.path}."}, httpStatus[error])
    throw error


module.exports =
  getByFipsCodeAsFile: (req, res, next) ->
    _getByFipsCode req, res, next, (req,res) ->
      if req.params.fipscode? #error handled in service
        res.setHeader 'Content-disposition', "attachment; filename=#{req.params.fipscode}.json"
        res.setHeader 'Content-type', 'application/json'

  getByFipsCodeAsStream: (req, res, next) ->
    #limiting the size since this endppoint is for testing
    req.query.limit = 100
    _getByFipsCode req, res, next
