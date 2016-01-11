# auth = require '../utils/util.auth'
{mergeHandles} = require '../utils/util.route.helpers'
logger = require '../config/logger'
{wrapHandleRoutes} = require '../utils/util.route.helpers'
{validateAndTransformRequest} = require '../utils/util.validation'
stripeTransforms = require '../utils/transforms/transforms.webhooks.stripe'
{emailPlatform} = require '../services/services.email'
paymentPlatform = require '../services/service.payment.platform'

handles = wrapHandleRoutes
  #https://dashboard.stripe.com/account/webhooks
  #https://stripe.com/docs/api#events
  #https://stripe.com/docs/webhooks
  #https://stripe.com/docs/recipes/sending-emails-for-failed-payments
  stripe: (req) ->
    validateAndTransformRequest req, stripeTransforms.event
    .then (validReq) ->
      {body} = validReq
      logger.debug "valid stripe event: #{JSON.stringify validReq}"
      paymentPlatform.event.handle(body)


module.exports = mergeHandles handles,
  stripe:
    method: 'post'
