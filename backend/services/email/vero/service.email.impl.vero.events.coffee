_ = require 'lodash'
{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'
backendRoutes = require '../../../../common/config/routes.backend'
{clsFullUrl} = require '../../../utils/util.route.helpers'
logger = require '../../../config/logger'
{EMAIL_PLATFORM} = require '../../../config/config'
{SignUpError} = require '../../../utils/errors/util.errors.vero'

emailRoutes = backendRoutes.email

VeroEvents = (vero) ->

  createOrUpdate = require('./service.email.impl.vero.user')(vero)

  # Returns the vero-promise response as Promise([user, event]).
  signUp = (opts, attempt = 0) ->
    onMissingArgsFail
      authUser: {val:opts.authUser, required: true}

    {authUser} = opts

    verifyUrl = clsFullUrl "#{emailRoutes.verify}/#{authUser.email_validation_hash}"
    logger.debug.yellow verifyUrl

    createOrUpdate _.extend {}, opts,
      eventName: 'customer.subscription.new'
      eventData: verify_url: verifyUrl
    .catch (err) ->
      logger.error "signUp error!"
      logger.error err

      if attempt >= EMAIL_PLATFORM.MAX_RETRIES - 1
        logger.error "MAX_RETRIES reached for signUp for new user"
        throw new SignUpError(opts)

      setTimeout ->
        signUp opts, attempt++, err
      , EMAIL_PLATFORM.RETRY_DELAY_MILLI

  _cancelPlan = (opts) ->
    onMissingArgsFail
      authUser: {val:opts.authUser, required: true}

    {authUser, eventName} = opts
    delete opts.cancelPlanUrl

    createOrUpdate _.extend {}, opts,
      eventName: eventName
        eventData: cancel_plan_url: authUser.cancel_email_hash

  trialEnding = (opts) ->
    _cancelPlan _.extend {}, opts, eventName: 'user.trial.ending'

  signUp: signUp
  trialEnding: trialEnding

module.exports = VeroEvents
