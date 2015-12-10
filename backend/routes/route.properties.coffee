logger = require '../config/logger'
Promise = require 'bluebird'

detailService = require '../services/service.properties.details'
filterSummaryService = require '../services/service.properties.filterSummary'
DrawnShapesFiltSvc = require '../services/service.properties.drawnShapes.filterSummary'
parcelService = require '../services/service.properties.parcels'
addressService = require '../services/service.properties.addresses'
profileService = require '../services/service.profiles'

validation = require '../utils/util.validation'
{validators, validateAndTransform} = validation
httpStatus = require '../../common/utils/httpStatus'
ExpressResponse = require '../utils/util.expressResponse'
{currentProfile, CurrentProfileError} = require '../utils/util.route.helpers'
auth = require '../utils/util.auth'
{basicColumns} = require '../utils/util.sql.columns'

_transforms =
  bounds: validators.string()
  returnType: validators.string()
  columns: validators.string()
  isNeighbourhood: validators.boolean(truthy: true, falsy: false)
  properties_selected: validators.object()
  geom_point_json: validators.object()
  rm_property_id: transform: any: [validators.string(minLength:1), validators.array()]
  state: [
    validators.object
      subValidateSeparate:
        account_image_id: validators.integer()
        filters: validators.object()
        favorites: validators.object()
        map_toggles: validators.object()
        map_position: validators.object()
        map_results: [validators.object(), validators.defaults(defaultValue: {})]
        auth_user_id: validators.integer()
        parent_auth_user_id: validators.integer()
    validators.defaults(defaultValue: {})
  ]

_appendProjectId = (req, obj) ->
  obj.project_id = currentProfile(req).project_id
  obj

captureMapFilterState =  (handleStr, saveState = true) -> (req, res, next) -> Promise.try () ->
  logger.debug "handle: #{handleStr}"
  validateAndTransform req.body, _transforms
  .then (body) ->
    {state} = body
    logger.debug body, true
    state = _appendProjectId(req, state)
    state.auth_user_id =  req.user.id
    if saveState
      profileService.updateCurrent(req.session, state, basicColumns.profile)
    body
  .then (body) ->
    req.validBody = body
    logger.debug "MapState saved"
    next()

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
    logger.error err.stack or err.toString()
    next(err)


module.exports =

  filterSummary:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      captureMapFilterState("filterSummary")
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        filterSummaryService.getFilterSummary(currentProfile(req), req.validBody)

  parcelBase:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      captureMapFilterState("parcelBase")
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        parcelService.getBaseParcelData(currentProfile(req), req.validBody)

  addresses:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      captureMapFilterState("address")
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        addressService.get(currentProfile(req), req.validBody)

  detail:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      captureMapFilterState("detail")
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        promise = detailService.getDetail(req.validBody)
        if req.validBody.rm_property_id?
          promise.then (property) ->
            if property
              return property
            return Promise.reject(new ExpressResponse(
              alert: {msg: "property with id #{req.validBody.rm_property_id} not found"}), httpStatus.NOT_FOUND)
        return promise

  details:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      captureMapFilterState("details", false)
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        detailService.getDetails(req.validBody)

  drawnShapes:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      captureMapFilterState("drawnShapes")
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        validBody = _appendProjectId(req, req.validBody)
        filterSummaryService.getFilterSummary(currentProfile(req), validBody, undefined, DrawnShapesFiltSvc)
