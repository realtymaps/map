Promise = require 'bluebird'
_ = require 'lodash'
logger = require('../config/logger').spawn("route.onboarding:internals")
emailService = require('../services/services.email')
tables = require '../config/tables'
fipsCodesService = require '../services/service.fipsCodes'
points = require '../../common/utils/util.geometries'
mlsAgentService = require '../services/service.mls.agent'
errors = require '../utils/errors/util.errors.onboarding'
tables = require '../config/tables'
userSessionService =  require '../services/service.userSession'
planService = require '../services/service.plans'
sqlColumns = require '../utils/util.sql.columns'
config = require '../config/config'

emailServices = null
paymentServices = null

emailService.emailPlatform.then (svc) ->
  emailServices = svc
require('../services/services.payment').then (svc) ->
  paymentServices = svc


createNewUser = ({body, transaction, plan}) -> Promise.try ->

  return throw new Error "OnBoarding API not ready" if !emailServices or !paymentServices

  entity = _.pick body, sqlColumns.basicColumns.user
  entity.email_validation_hash = emailService.makeEmailHash()
  entity.is_test = !config.PAYMENT_PLATFORM.LIVE_MODE
  entity.is_active = true # if we demand email validation again, then remove this line

  userSessionService.createPasswordHash(entity.password)
  .then (password) ->
    # console.log.magenta "password"
    entity.password = password

    # INSERT THE NEW USER
    tables.auth.user({transaction}).returning("id").insert(entity)
    .then (id) ->
      # console.log.magenta "inserted user"
      #NOW LINK THE USER TO THEIR SPECIFIED PLAN
      planService.getPlanId(plan, transaction)
      .then (groupId) ->
        # console.log.magenta "planId/groupId: #{groupId}"
        logger.debug "auth_user_id: #{id}"
        #give plan / group permissions
        # (deprecated, we'll use subscription status and plan data off stripe instead)
        tables.auth.m2m_user_group({transaction})
        .insert user_id: parseInt(id), group_id: parseInt(groupId)
        .then ->
          id
    .then (id) ->
      logger.debug "new user (#{id}) inserted SUCCESS"
      #Making sure we have all the updated information / de-normalized
      tables.auth.user({transaction}).select(sqlColumns.basicColumns.user.concat("id")...)
      .where id: parseInt id


submitPaymentPlan = ({plan, token, authUser, transaction}) ->
  logger.debug -> "PaymentPlan: attempting to add user authUser.id #{authUser.id}, first_name: #{authUser.first_name}"
  paymentServices.customers.create
    authUser: authUser
    plan: plan
    token: token
    trx: transaction
  .then (result) ->
    logger.debug -> "@@@@ Customer Creation Success @@@@"
    logger.debug -> result.customer
    result

submitEmail = ({authUser, plan}) ->
  logger.debug "EmailService: attempting to add user authUser.id #{authUser.id}, first_name: #{authUser.first_name}"
  emailServices.events.subscriptionSignUp(authUser)
  .catch (error) ->
    logger.info "SignUp Failed, reverting Payment Customer"
    paymentServices.customers.handleCreationError
      error: error
      authUser:authUser
    throw error #rethrow error so transaction is reverted

setNewUserMapPosition = ({authUser, transaction}) ->
  logger.debugQuery(
    tables.auth.user({transaction})
    .select('fips_codes', 'mlses_verified')
    .where id: authUser.id
  )
  .then ([user]=[]) ->
    if !user?
      throw Error("No user exists to set map postion!")
    logger.debug -> "@@@@ user @@@@"
    logger.debug -> user
    _.extend authUser, user
    # set original map_center on the new user's profiles
    fipsCodesService.getCollectiveCenter({fipsCodes: user.fips_codes, mlses: user.mlses_verified})
    .then ([{geo_json}]) ->
      logger.debug -> '@@@@ geo_json @@@@'
      logger.debug -> geo_json
      center = (new points.GeoJsonCenter(geo_json, 16)).toJSON()
      logger.debug -> "@@@@@@@ Defining center for new user @@@@@@@"
      logger.debug -> center

      logger.debugQuery(
        tables.user.profile({transaction})
        .where auth_user_id: authUser.id
        .update map_position: {center}
      )

###
Set the users location permissions for an mls_agent / pro plan
###
setMlsPermissions = ({authUser, fips_code, mls_code, mls_id, plan, transaction}) ->
  logger.debug {fips_code, mls_code, mls_id, plan}, true
  if !fips_code && !(mls_code && mls_id)
    throw new Error("fips_code or mls_code or mls_id is required for user location restrictions.")

  promises = []
  if fips_code
    promises.push(tables.auth.m2m_user_locations({transaction})
    .insert(auth_user_id: authUser.id, fips_code: fips_code))

  if mls_id? && mls_code? && plan == config.SUBSCR.PLAN.PRO
    promises.push(
      mlsAgentService.exists(data_source_id: mls_code, license_number: mls_id)
      .then (is_verified) ->
        if !is_verified
          throw new errors.MlsAgentNotVierified("Agent not verified for mls_id: #{mls_id}, mls_code: #{mls_code} for email: #{authUser.email}")
        tables.auth.m2m_user_mls({transaction})
        .insert({auth_user_id: authUser.id, mls_code: mls_code, mls_user_id: mls_id, is_verified})
    )

  Promise.all(promises).then () ->
    logger.debug -> "PRE: setNewUserMapPosition"
    setNewUserMapPosition({authUser, transaction})
    .then ->
      logger.debug -> "POST: setNewUserMapPosition"
  .then () ->
    logger.debug -> "Returning authUser"
    logger.debug -> authUser
    authUser

module.exports = {
  createNewUser
  submitPaymentPlan
  submitEmail
  setNewUserMapPosition
  setMlsPermissions
}
