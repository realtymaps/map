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


  sendVeroMsg = ({opts, errorName, eventName}) ->

    payload = _.merge {}, opts,
      eventName: veroEvents[eventName]
      eventData:
        in_error_support_phrase: inErrorSupportPhrase

    logger.debug "sendVeroMsg"
    logger.debug payload
    createOrUpdate payload

    .catch (err) ->
      throw new veroErrors[errorName](opts, analyzeValue.getSimpleDetails(err))



  ###
  Main goal is to move the main extra option of `properties` to eventData for the template
  ###
  notificationProperties = ({opts, name, errorName, eventName}) ->
    logger.debug "@@@@@@@@ notificationProperties @@@@@@@@"
    logger.debug {opts, name, errorName, eventName}
    logger.debug "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    {authUser, properties, type, frequency} = onMissingArgsFail args: opts, required: ['authUser', 'properties']

    opts = {
      authUser
      eventData: {
        properties
        type
        frequency
      }
    }

    logger.debug "handling vero #{@name}"

    sendVeroMsg {
      opts
      errorName
      eventName
    }

  {
    inErrorSupportPhrase
    sendVeroMsg
    cancelPlanOptions
    notificationProperties
  }
