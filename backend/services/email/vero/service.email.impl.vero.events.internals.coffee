_ = require 'lodash'
Promise = require 'bluebird'
{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'
backendRoutes = require '../../../../common/config/routes.backend'
{clsFullUrl} = require '../../../utils/util.route.helpers'
logger = require('../../../config/logger').spawn('vero')
{EMAIL_PLATFORM} = require '../../../config/config'
veroErrors = require '../../../utils/errors/util.errors.vero'
veroEvents = require '../../../enums/enum.vero.events'
analyzeValue = require '../../../../common/utils/util.analyzeValue'

emailRoutes = backendRoutes.email

inErrorSupportPhrase = """
PS:

If this was not initiated by you or feel this is in error please contact [contact me] (support@realtymaps.com) .
"""

module.exports = (vero) ->

  {createOrUpdate} = require('./service.email.impl.vero.user')(vero)

  cancelPlanOptions = (opts) -> Promise.try () ->
    onMissingArgsFail args: opts, required: ['authUser']

    delete opts.cancelPlanUrl
    cancelPlanUrl = clsFullUrl emailRoutes.cancelPlan.replace(":cancelPlan", opts.authUser.cancel_email_hash)

    _.merge opts,
      eventData:
        cancel_plan_url: cancelPlanUrl


  callAndRetry = ({opts, attempt, recallFn, errorName, eventName}) ->
    attempt ?= 0

    logger.debug.cyan "#{recallFn.name} ATTEMPT: #{attempt}"

    createOrUpdate _.merge {}, opts,
      eventName: veroEvents[eventName]
      eventData:
        in_error_support_phrase: inErrorSupportPhrase
    .catch (err) ->
      logger.error "#{recallFn.name} error!"
      logger.error analyzeValue.getSimpleMessage(err)

      if attempt >= EMAIL_PLATFORM.MAX_RETRIES - 1
        logger.error "MAX_RETRIES reached for #{recallFn.name}"
        #add to a JobQueue task to complete later?
        throw new veroErrors[errorName](opts)

      setTimeout ->
        recallFn opts, attempt++
      , EMAIL_PLATFORM.RETRY_DELAY_MILLI



  ###
  Main goal is to move the main extra option of `properties` to eventData for the template
  ###
  notificationProperties = ({opts, attempt, recallFn, name, errorName, eventName}) ->

    {authUser, properties} = onMissingArgsFail args: opts, required: ['authUser', 'properties']

    opts = {
      authUser
      eventData: {
        properties
      }
    }

    @name = name
    logger.debug "handling vero #{@name}"

    callAndRetry {
      opts
      attempt
      recallFn
      errorName
      eventName
    }

  {
    inErrorSupportPhrase
    callAndRetry
    cancelPlanOptions
    notificationProperties
  }
