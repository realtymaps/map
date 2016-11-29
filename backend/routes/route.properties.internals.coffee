logger = require('../config/logger').spawn('route:properties:internals')
Promise = require 'bluebird'
moment = require 'moment'

profileService = require '../services/service.profiles'
profileError = require '../utils/errors/util.error.profile'
{validateAndTransformRequest, DataValidationError} = require '../utils/util.validation'
httpStatus = require '../../common/utils/httpStatus'
ExpressResponse = require '../utils/util.expressResponse'
analyzeValue = require '../../common/utils/util.analyzeValue'
ourTransforms = require '../utils/transforms/transforms.properties'
propSaveSvc = require '../services/service.properties.save'
userUtils = require '../utils/util.user'
tables = require '../config/tables'
keystoreSvc = require '../services/service.keystore'
profileSvc = require '../services/service.profiles'

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

refreshPins = () ->
  (req, res, next) ->
    # If cached profile is older than pin_refresh_minutes, load fresh pins
    Promise.join keystoreSvc.cache.getValue('pin_refresh_minutes', namespace: 'time_limits'),
      profileSvc.getCurrentSessionProfile(req.session),
      (pin_refresh_minutes, profile) ->
        logger.debug profile
        logger.debug 'comparing', moment(profile.rm_modified_time).add(pin_refresh_minutes, 'minutes').format(),  moment.utc().format()
        if moment(profile.rm_modified_time).add(pin_refresh_minutes, 'minutes').isBefore(moment.utc())
          logger.debug "Profile is older than #{pin_refresh_minutes} minutes, reloading pins"
          tables.user.project()
          .select('pins')
          .where('id', profile.project_id)
          .then ([project]) ->
            profile.pins = project.pins
            profile.rm_modified_time = moment.utc()
            next()
        else
          logger.debug "Profile is still fresh"
          next()
    .catch (err) ->
      next(err)

handleRoute = (res, next, serviceCall) ->
  Promise.try () ->
    serviceCall()
  .then (data) ->
    res.json(data)
  .catch DataValidationError, (err) ->
    next new ExpressResponse({alert: {msg: err.message}}, {status: httpStatus.BAD_REQUEST, quiet: err.quiet})
  .catch profileError.CurrentProfileError, (err) ->
    next new ExpressResponse({profileIsNeeded: true, alert: {msg: err.message}}, {status: httpStatus.BAD_REQUEST, quiet: err.quiet})
  .catch (err) ->
    logger.error analyzeValue.getFullDetails(err)
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
  refreshPins
  appendProjectId
  save
  saves
  getPva
}
