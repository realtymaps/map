logger = require '../config/logger'
Promise = require 'bluebird'

detailServiceOld = require '../services/service.properties.details'
detailService = require '../services/service.properties.combined.details'
filterSummaryService = require '../services/service.properties.filterSummary'
DrawnShapesFiltSvc = require '../services/service.properties.drawnShapes.filterSummary'
parcelService = require '../services/service.properties.parcels'
addressService = require '../services/service.properties.addresses'
profileService = require '../services/service.profiles'
{validators, validateAndTransformRequest, DataValidationError} = require '../utils/util.validation'
httpStatus = require '../../common/utils/httpStatus'
ExpressResponse = require '../utils/util.expressResponse'
{currentProfile, CurrentProfileError} = require '../utils/util.route.helpers'
auth = require '../utils/util.auth'
{basicColumns} = require '../utils/util.sql.columns'
_ = require 'lodash'
analyzeValue = require '../../common/utils/util.analyzeValue'

_stateTransforms =
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

_transforms = _.extend {}, _stateTransforms,
  bounds: validators.string()
  returnType: validators.string()
  columns: validators.string()
  isNeighbourhood: validators.boolean(truthy: true, falsy: false)
  properties_selected: validators.object()
  geom_point_json: validators.object()
  rm_property_id: transform: any: [validators.string(minLength:1), validators.array()]


_appendProjectId = (req, obj) ->
  obj.project_id = currentProfile(req).project_id
  obj

captureMapFilterState =  (opts) -> (req, res, next) -> Promise.try () ->
  {handleStr, saveState, transforms} = opts
  saveState ?= true
  transforms ?= _transforms

  if handleStr
    logger.debug "handle: #{handleStr}"

  validateAndTransformRequest req.body, transforms
  .then (body) ->
    {state} = body
    if state? and saveState
      _appendProjectId(req, state)
      state.auth_user_id =  req.user.id
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
  .catch DataValidationError, (err) ->
    next new ExpressResponse(alert: {msg: err.message}, httpStatus.BAD_REQUEST)
  .catch CurrentProfileError, (err) ->
    next new ExpressResponse({profileIsNeeded: true,alert: {msg: err.message}}, httpStatus.BAD_REQUEST)
  .catch (err) ->
    logger.error analyzeValue.getSimpleDetails(err)
    next(err)


module.exports =

  mapState:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      captureMapFilterState(handleStr:'mapState', transforms: _stateTransforms)
    ]
    handle: (req, res) -> res.json req.validBody

  filterSummary:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      captureMapFilterState(handleStr: "filterSummary")
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        filterSummaryService.getFilterSummary(
          state: currentProfile(req)
          req: req.validBody
        )

  parcelBase:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      captureMapFilterState(handleStr: "parcelBase")
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        parcelService.getBaseParcelData(currentProfile(req), req.validBody)

  addresses:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      captureMapFilterState(handleStr:"address")
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        addressService.get(currentProfile(req), req.validBody)

  detail:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      captureMapFilterState(handleStr:"detail")
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        detailService.getDetail(req.validBody)
        .then (property) -> Promise.try () ->
          if req.validBody.rm_property_id? && !property
            throw new ExpressResponse(
              alert: {msg: "property with id #{req.validBody.rm_property_id} not found"},
               httpStatus.NOT_FOUND)

          property

  details:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      captureMapFilterState(handleStr:"details", saveState: false)
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        detailServiceOld.getDetails(req.validBody)

  drawnShapes:
    method: "post"
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      captureMapFilterState(handleStr:"drawnShapes")
    ]
    handle: (req, res, next) ->
      handleRoute res, next, () ->
        validBody = _appendProjectId(req, req.validBody)
        filterSummaryService.getFilterSummary(currentProfile(req), validBody, undefined, DrawnShapesFiltSvc)
