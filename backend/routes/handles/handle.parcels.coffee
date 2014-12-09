Promise = require "bluebird"
parcelService = require '../../services/service.properties.parcels'
requestUtil = require '../../utils/util.http.request'
status = require '../../../common/utils/httpStatus'
logger = require '../../config/logger'


module.exports =
  parcelBase: (req, res, next) ->
    Promise.try () ->
      parcelService.getBaseParcelData(req.query)
    .then (data) ->
      res.json(data)
    .catch requestUtil.query.ParamValidationError, (err) ->
      next(status: status.BAD_REQUEST, message: err.message)
    .catch (err) ->
      logger.error err.stack||err.toString()
      next(status: status.INTERNAL_SERVER_ERROR, message: err.message)
