logger = require('../config/logger').spawn("route.onboarding:internals")
emailServices = null
paymentServices = null
{emailPlatform} = require('../services/services.email')
emailPlatform.then (svc) ->
  emailServices = svc
require('../services/services.payment').then (svc) ->
  paymentServices = svc
tables = require '../config/tables'
_ = require 'lodash'
fipsCodesService = require '../services/service.fipsCodes'
points = require '../../common/utils/util.geometries'

submitPaymentPlan = ({plan, token, authUser, trx}) ->
  logger.debug "PaymentPlan: attempting to add user authUser.id #{authUser.id}, first_name: #{authUser.first_name}"
  paymentServices.customers.create
    authUser: authUser
    plan: plan
    token: token
    trx: trx

submitEmail = ({authUser, plan}) ->
  logger.debug "EmailService: attempting to add user authUser.id #{authUser.id}, first_name: #{authUser.first_name}"
  emailServices.events.subscriptionSignUp
    authUser: authUser
    plan: plan
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
  .then ([user]) ->
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


module.exports = {
  submitPaymentPlan
  submitEmail
  setNewUserMapPosition
}
