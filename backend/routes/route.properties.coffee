logger = require '../config/logger'
Promise = require 'bluebird'
detailService = require '../services/service.properties.details'
filterSummaryService = require '../services/service.properties.filterSummary'
DrawnShapesFiltSvc = require '../services/service.properties.drawnShapes.filterSummary'
parcelService = require '../services/service.properties.parcels'
addressService = require '../services/service.properties.addresses'
validation = require '../utils/util.validation'
httpStatus = require '../../common/utils/httpStatus'
ExpressResponse = require '../utils/util.expressResponse'
{currentProfile, CurrentProfileError} = require '../utils/util.route.helpers'
auth = require '../utils/util.auth'
userSessionService = require '../services/service.userSession'

handleRoute = (res, next, serviceCall) ->
  Promise.try () ->
    serviceCall()
  .then (data) ->
    res.json(data)
  .catch validation.DataValidationError, (err) ->
    next new ExpressResponse(alert: {msg: err.message}, httpStatus.BAD_REQUEST)
  .catch CurrentProfileError, (err) ->
    next new ExpressResponse({profileIsNeeded: true,alert: {msg: err.message}}, httpStatus.BAD_REQUEST)
  .catch (err) ->
    logger.error err.stack||err.toString()
    next(err)


module.exports =

  filterSummary:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      userSessionService.captureMapFilterState
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        filterSummaryService.getFilterSummary(currentProfile(req), req.query)

  parcelBase:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      userSessionService.captureMapFilterState
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        parcelService.getBaseParcelData(currentProfile(req), req.query)

  addresses:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      userSessionService.captureMapFilterState
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        addressService.get(currentProfile(req), req.query)

  detail:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      userSessionService.captureMapFilterState
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        promise = detailService.getDetail(req.query)
        if req.query.rm_property_id?
          promise.then (property) ->
            if property
              return property
            return Promise.reject new ExpressResponse(alert: {msg: "property with id #{req.query.rm_property_id} not found"}), httpStatus.NOT_FOUND
        return promise

  details:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        detailService.getDetails(req.query)


  drawnShapes:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        logger.debug.cyan req.query.current_project_id, true
        # logger.functions DrawnShapesFiltSvc
        filterSummaryService.getFilterSummary(
          currentProfile(req),
          req.query,
          undefined,
          DrawnShapesFiltSvc
        )
