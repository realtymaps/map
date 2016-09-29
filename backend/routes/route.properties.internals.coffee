logger = require '../config/logger'
Promise = require 'bluebird'
moment = require 'moment'

profileService = require '../services/service.profiles'
{validateAndTransformRequest, DataValidationError} = require '../utils/util.validation'
httpStatus = require '../../common/utils/httpStatus'
ExpressResponse = require '../utils/util.expressResponse'
analyzeValue = require '../../common/utils/util.analyzeValue'
ourTransforms = require '../utils/transforms/transforms.properties'
propSaveSvc = require '../services/service.properties.save'
userUtils = require '../utils/util.user'
tables = require '../config/tables'


appendProjectId = (req, obj) ->
  obj.project_id = profileService.getCurrentSessionProfile(req.session).project_id
  obj

captureMapFilterState =  ({handleStr, saveState = true, transforms = ourTransforms.body} = {}) ->
  (req, res, next) -> Promise.try () ->
    if handleStr
      logger.debug () -> "handle: #{handleStr}"

    # logger.debug () -> "body: #{util.inspect req.body, depth: null}"
    # logger.debug () -> ourTransforms.body

    validateAndTransformRequest req.body, transforms
    .then (body) ->
      # logger.debug () -> "validBody: #{util.inspect body, depth: null}"

      {state} = body
      if state? and saveState
        appendProjectId(req, state)
        state.auth_user_id =  req.user.id
        profileService.updateCurrent(req.session, state)
      body
    .then (body) ->
      req.validBody = body
      logger.debug "MapState saved"
      next()

    .catch (err) ->
      next new ExpressResponse({alert: {msg: err.message}}, {status: httpStatus.BAD_REQUEST, quiet: err.quiet})

handleRoute = (res, next, serviceCall) ->
  Promise.try () ->
    serviceCall()
  .then (data) ->
    res.json(data)
  .catch DataValidationError, (err) ->
    next new ExpressResponse({alert: {msg: err.message}}, {status: httpStatus.BAD_REQUEST, quiet: err.quiet})
  .catch profileService.CurrentProfileError, (err) ->
    next new ExpressResponse({profileIsNeeded: true, alert: {msg: err.message}}, {status: httpStatus.BAD_REQUEST, quiet: err.quiet})
  .catch (err) ->
    logger.error analyzeValue.getSimpleDetails(err)
    next(err)

save = ({req, res, next, type}) ->
  handleRoute res, next, () ->
    validateAndTransformRequest req, ourTransforms.save
    .then (validReq) ->
      propSaveSvc.save  {
        rm_property_id: validReq.body.rm_property_id
        type
      }
      .then () ->
        userUtils.cacheUserValues(req, profiles: true)
saves = ({res, next}) ->
  handleRoute res, next, () -> propSaveSvc.getAll()

getPva = ({req, res, next}) ->
  handleRoute res, next, () ->
    tables.config.pva()
    .where(fips_code: req.params.fips_code)
    .then (results) ->
      if !results?.length
        throw new Error("Can't find PVA config for FIPS code: #{req.params.fips_code}")
      res.set('Cache-Control', 'public, max-age=8640')
      res.set('Expires', moment.utc(new Date()).add(1, 'day').format('ddd, DD MMM YYYY HH:mm:ss [GMT]'))
      return results[0]

module.exports = {
  handleRoute
  captureMapFilterState
  appendProjectId
  save
  saves
  getPva
}
