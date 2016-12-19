_ = require 'lodash'
Promise = require 'bluebird'
{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'
backendRoutes = require '../../../../common/config/routes.backend'
{clsFullUrl} = require '../../../utils/util.route.helpers'
veroErrors = require '../../../utils/errors/util.errors.vero'
veroUserSvc = require './service.email.impl.vero.user'
analyzeValue = require '../../../../common/utils/util.analyzeValue'
logger = require('../../../config/logger').spawn('vero')
emailRoutes = backendRoutes.email

inErrorSupportPhrase = """
PS:

If this was not initiated by you or feel this is in error please contact [contact me] (support@realtymaps.com) .
"""

VeroEvents = (vero) ->

  _send = (authUser, eventName, override = {}) ->
    p = _.defaultsDeep override,
      id: veroUserSvc.getUniqueUserId(authUser)
      email: authUser.email
      userData: _.extend(_.pick(authUser, ['first_name','last_name']))
      eventName: eventName
      eventData:
        in_error_support_phrase: inErrorSupportPhrase

    logger.debug -> "Tracking on VERO: #{eventName}, parameters:\n#{JSON.stringify(p)}"
    vero.createUserAndTrackEvent(p.id, p.email, p.userData, p.eventName, p.eventData)

  subscriptionSignUp = (authUser) -> Promise.try () ->
    logger.debug "subscriptionSignUp()"

    verify_url = clsFullUrl emailRoutes.verify.replace(":hash", authUser.email_validation_hash)
    logger.debug "VERIFY URL"
    logger.debug.yellow verify_url

    _send(authUser, "customer.subscription.created", {eventData: {verify_url}})
    .catch (err) ->
      throw new veroErrors.SubscriptionSignUpError(err, analyzeValue.getFullDetails(err))

  subscriptionTrialEnding = (authUser) -> Promise.try () ->
    logger.debug "subscriptionTrialEnding()"

    cancel_plan_url = clsFullUrl emailRoutes.cancelPlan.replace(":cancelPlan", authUser.cancel_email_hash)
    logger.debug "CANCEL PLAN URL"
    logger.debug.yellow cancel_plan_url

    _send(authUser, "customer.subscription.trial_will_end", {eventData: {cancel_plan_url}})
    .catch (err) ->
      throw new veroErrors.SubscriptionTrialEndedError(err, analyzeValue.getFullDetails(err))

  # Purpose To send a Welcome Email stating that the account validation was successful
  subscriptionVerified = (authUser) ->
    logger.debug "subscriptionVerified()"
    _send(authUser, "customer.subscription.verified")
    .catch (err) ->
      throw new veroErrors.SubscriptionVerifiedError(err, analyzeValue.getFullDetails(err))

  subscriptionUpdated = (authUser) ->
    logger.debug "subscriptionUpdated()"
    _send(authUser, "customer.subscription.updated")
    .catch (err) ->
      throw new veroErrors.SubscriptionUpdatedError(err, analyzeValue.getFullDetails(err))


  subscriptionDeactivated = (authUser) ->
    logger.debug "subscriptionDeactivated()"
    _send(authUser, "subscription_deactivated")
    .catch (err) ->
      throw new veroErrors.SubscriptionDeactivatedError(err, analyzeValue.getFullDetails(err))


  subscriptionExpired = (authUser) ->
    logger.debug "subscriptionExpired()"
    _send(authUser, "subscription_expired")
    .catch (err) ->
      throw new veroErrors.SubscriptionExpiredError(err, analyzeValue.getFullDetails(err))


  notificationPropertiesSaved = (opts) ->
    logger.debug "notificationPropertiesSaved()"
    {
      authUser
      properties
      type
      frequency
      notification_id
      project_id
      from
    } = onMissingArgsFail args: opts, required: ['authUser', 'properties', 'notification_id']

    eventData = {
      properties
      type
      frequency
      notification_id
      project_id
      from
      in_error_support_phrase: inErrorSupportPhrase
    }

    _send(authUser, "notification_properties_saved", {eventData})
    .catch (err) ->
      throw new veroErrors.NotificationPropertiesSavedError(err, analyzeValue.getFullDetails(err))

#
# public expose
#

  {
    subscriptionSignUp
    subscriptionVerified
    subscriptionTrialEnding
    subscriptionUpdated
    subscriptionDeactivated
    subscriptionExpired
    notificationPropertiesSaved
    inErrorSupportPhrase
  }

module.exports = VeroEvents
