Promise = require 'bluebird'
_ = require 'lodash'

detailService = require '../services/service.properties.combined.details'
filterSummaryService = require '../services/service.properties.filterSummary'
DrawnShapesFiltSvc = require '../services/service.properties.drawnShapes.filterSummary'
parcelService = require '../services/service.properties.parcels'
addressService = require '../services/service.properties.addresses'
httpStatus = require '../../common/utils/httpStatus'
ExpressResponse = require '../utils/util.expressResponse'
auth = require '../utils/util.auth'
internals = require './route.properties.internals'
ourTransforms = require '../utils/transforms/transforms.properties'
logger = require('../config/logger').spawn('route:properties')
profileSvc = require '../services/service.profiles'

module.exports =

  mapState:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      internals.captureMapFilterState(handleStr:'mapState', transforms: ourTransforms.state)
    ]
    handle: (req, res) -> res.json req.validBody

  filterSummary:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      internals.captureMapFilterState(handleStr: "filterSummary")
      internals.refreshPins()
    ]
    handle: (req, res, next) ->
      internals.handleRoute res, next, () ->
        filterSummaryService.getFilterSummary(
          profile: profileSvc.getCurrentSessionProfile(req.session)
          validBody: req.validBody
        )

  parcelBase:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      internals.captureMapFilterState(handleStr: "parcelBase")
    ]
    handle: (req, res, next) ->
      internals.handleRoute res, next, () ->
        parcelService.getBaseParcelData(profileSvc.getCurrentSessionProfile(req.session), req.validBody)

  addresses:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      internals.captureMapFilterState(handleStr:"address")
    ]
    handle: (req, res, next) ->
      internals.handleRoute res, next, () ->
        addressService.get(profileSvc.getCurrentSessionProfile(req.session), req.validBody)

  detail:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      internals.captureMapFilterState(handleStr:"detail", transforms: ourTransforms.detail.property)
    ]
    handle: (req, res, next) ->
      internals.handleRoute res, next, () ->
        detailService.getProperty(
          query: _.omit(req.validBody, 'trump')
          profile: profileSvc.getCurrentSessionProfile(req.session)
        )
        .then (property) -> Promise.try () ->
          if req.validBody.rm_property_id? && !property
            if !req.validBody.no_alert
              return next( new ExpressResponse(
                alert: {msg: "property with id #{req.validBody.rm_property_id} not found"},
                {status: httpStatus.NOT_FOUND, quiet: true}))

            return next(new ExpressResponse({status: httpStatus.NOT_FOUND, quiet: true}))


          property

  details:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      internals.captureMapFilterState(handleStr:"details", saveState: false)
    ]
    handle: (req, res, next) ->
      internals.handleRoute res, next, () ->
        detailService.getProperties(
          query: _.omit(req.validBody, 'trump')
          profile: profileSvc.getCurrentSessionProfile(req.session)
          trump: req.validBody.trump
        )

  drawnShapes:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      internals.captureMapFilterState(handleStr:"drawnShapes")
      internals.refreshPins()
    ]
    handle: (req, res, next) ->
      internals.handleRoute res, next, () ->
        internals.appendProjectId(req, req.validBody)
        filterSummaryService.getFilterSummary(
          validBody: req.validBody
          profile: profileSvc.getCurrentSessionProfile(req.session)
          filterSummaryImpl: DrawnShapesFiltSvc
        )

  inArea:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: (req, res, next) ->
      internals.handleRoute res, next, () ->
        DrawnShapesFiltSvc.getPropertyIdsInArea(
          queryParams: req.body
          profile: profileSvc.getCurrentSessionProfile(req.session)
        )

  inGeometry:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      internals.captureMapFilterState(handleStr: "filterSummary")
    ]
    handle: (req, res, next) ->
      internals.handleRoute res, next, () ->
        filterSummaryService.getFilterSummary(
          profile: profileSvc.getCurrentSessionProfile(req.session)
          validBody: req.validBody
          ignoreSaved: true
        )

  saves:
    middleware:
      auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      internals.saves({res, next})

  pin:
    method: "post"
    middleware:
      auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      logger.debug 'pin !!!!!!!!!!!!!!!!!!!!!!!!!!'
      internals.save({req, res, next, type: 'pin'})

  unPin:
    method: "post"
    middleware:
      auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      logger.debug 'unPin !!!!!!!!!!!!!!!!!!!!!!!!!!'
      internals.save({req, res, next, type: 'unPin'})

  favorite:
    method: "post"
    middleware:
      auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      internals.save({req, res, next, type: 'favorite'})

  unFavorite:
    method: "post"
    middleware:
      auth.requireLogin(redirectOnFail: true)
    handle: (req, res, next) ->
      internals.save({req, res, next, type: 'unFavorite'})

  pva:
    handle: (req, res, next) ->
      res.set 'Access-Control-Allow-Origin', "*"
      internals.getPva({req, res, next})
