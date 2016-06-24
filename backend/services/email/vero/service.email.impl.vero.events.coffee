_ = require 'lodash'
Promise = require 'bluebird'
{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'
backendRoutes = require '../../../../common/config/routes.backend'
{clsFullUrl} = require '../../../utils/util.route.helpers'
logger = require('../../../config/logger').spawn('vero')
internals = null
emailRoutes = backendRoutes.email


VeroEvents = (vero) ->

  internals = require('./service.email.impl.vero.events.internals')(vero)

  # Returns the vero-promise response as Promise([user, event]).
  subscriptionSignUp = (opts, attempt) -> Promise.try () ->
    @name = "subscriptionSignUp"

    onMissingArgsFail args: opts, required: ['authUser']

    {authUser} = opts

    verifyUrl = clsFullUrl emailRoutes.verify.replace(":hash", authUser.email_validation_hash)

    logger.debug "VERIFY URL"
    logger.debug.yellow verifyUrl

    _.merge opts,
      eventData:
        verify_url: verifyUrl

    internals.callAndRetry {
      opts
      attempt
      recallFn: @
      errorName: "SubscriptionSignUpError"
      eventName: "customerSubscriptionCreated"
    }


  subscriptionTrialEnding = (opts) -> Promise.try () ->
    @name = "subscriptionTrialEnding"
    logger.debug "handling vero #{@name}"

    internals.cancelPlanOptions opts

    internals.callAndRetry {
      opts
      errorName: "SubscriptionTrialEndedError"
      eventName: "customerSubscriptionTrialWillEnd"
    }

  #Purpose To send a Welcome Email stating that the account validation was successful
  subscriptionVerified = (opts) ->
    @name = "subscriptionVerified"
    logger.debug "handling vero #{@name}"

    internals.callAndRetry {
      opts
      errorName: "SubscriptionVerifiedError"
      eventName: "customerSubscriptionVerified"
    }

  subscriptionUpdated = (opts) ->
    @name = "subscriptionUpdated"
    logger.debug "handling vero #{@name}"

    internals.callAndRetry {
      opts
      errorName: "SubscriptionUpdatedError"
      eventName: "customerSubscriptionUpdated"
    }

  subscriptionDeleted = (opts) ->
    @name = "subscriptionDeleted"
    logger.debug "handling vero #{@name}"

    internals.callAndRetry {
      opts
      errorName: "SubscriptionDeletedError"
      eventName: "customerSubscriptionDeleted"
    }


  notificationFavorited = (opts) ->
    opts.type = 'Favorited'
    internals.notificationProperties {
      opts
      name: "notificationFavorite"
      errorName: "NotificationFavoriteError"
      eventName: "notificationPropertiesSaved"
    }


  notificationPinned = (opts) ->
    opts.type = 'Pinned'
    internals.notificationProperties {
      opts
      name: "notificationPinned"
      errorName: "NotificationPinnedError"
      eventName: "notificationPropertiesSaved"
    }


  {
    subscriptionSignUp
    subscriptionVerified
    subscriptionTrialEnding
    subscriptionUpdated
    subscriptionDeleted
    notificationFavorited
    notificationPinned
  }

module.exports = VeroEvents
