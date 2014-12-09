Promise = require "bluebird"
filterSummaryService = require '../../services/service.properties.filterSummary'
parcelService = require '../../services/service.properties.parcels'
requestUtil = require '../../utils/util.http.request'
status = require '../../../common/utils/httpStatus'
logger = require '../../config/logger'


handleRoute = (res, next, serviceCall) ->
  Promise.try () ->
    serviceCall()
  .then (data) ->
    res.json(data)
  .catch requestUtil.query.ParamValidationError, (err) ->
    next(status: status.BAD_REQUEST, message: err.message)
  .catch (err) ->
    logger.error err.stack||err.toString()
    next(status: status.INTERNAL_SERVER_ERROR, message: err.message)


module.exports = 
  
  filterSummary: (req, res, next) ->
    handleRoute res, next, () ->
      filterSummaryService.getFilterSummary(req.query)

  parcelBase: (req, res, next) ->
    handleRoute res, next, () ->
      parcelService.getBaseParcelData(req.query)
