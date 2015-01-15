logger = require '../config/logger'
Promise = require "bluebird"
detailService = require '../services/service.properties.details.coffee'
filterSummaryService = require '../services/service.properties.filterSummary'
parcelService = require '../services/service.properties.parcels'
requestUtil = require '../utils/util.http.request'
httpStatus = require '../../common/utils/httpStatus'
ExpressResponse = require '../utils/util.expressResponse'


handleRoute = (res, next, serviceCall) ->
  Promise.try () ->
    serviceCall()
  .then (data) ->
    res.json(data)
  .catch requestUtil.query.ParamValidationError, (err) ->
    next new ExpressResponse(alert: {msg: err.message}, httpStatus.BAD_REQUEST)
  .catch (err) ->
    logger.error err.stack||err.toString()
    next(err)


module.exports =

  filterSummary: (req, res, next) ->
    handleRoute res, next, () ->
      filterSummaryService.getFilterSummary(req.session.state, req.query)

  parcelBase: (req, res, next) ->
    handleRoute res, next, () ->
      parcelService.getBaseParcelData(req.session.state, req.query)

  detail: (req, res, next) ->
    handleRoute res, next, () ->
      detailService.getDetail(req.session.state, req.query, next)
