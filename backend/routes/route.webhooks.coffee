# auth = require '../utils/util.auth'
{mergeHandles} = require '../utils/util.route.helpers'
logger = require('../config/logger').spawn("route:webhooks")
{wrapHandleRoutes} = require '../utils/util.route.helpers'
{validateAndTransformRequest} = require '../utils/util.validation'
stripeTransforms = require '../utils/transforms/transforms.webhooks.stripe'
veroTransforms = require '../utils/transforms/transforms.webhooks.vero'
veroWebhookEvents = require '../enums/enum.vero.webhook.events'
# {emailPlatform} = require '../services/services.email'
paymentServices = require('../services/services.payment').then (services) ->
  paymentServices = services

notificationQueueSvc = require('../services/service.notification.queue').instance

handles = wrapHandleRoutes handles:
  #https://dashboard.stripe.com/account/webhooks
  #https://stripe.com/docs/api#events
  #https://stripe.com/docs/webhooks
  #https://stripe.com/docs/recipes/sending-emails-for-failed-payments
  stripe: (req) ->
    validateAndTransformRequest req, stripeTransforms.event
    .then (validReq) ->
      {body} = validReq
      logger.debug "valid stripe event: #{JSON.stringify validReq}"
      paymentServices.events.handle(body)

  #http://help.getvero.com/articles/setting-up-veros-webhooks.html
  vero: (req) ->
    logger.debug "incoming unvalidated request body"
    logger.debug req.body

    veroTransforms.validateAndTransformRequest req
    .then (validReq) ->

      if !veroWebhookEvents.delivered == validReq.body.type
        logger.debug 'VERO WEBHOOK IGNORING'
        logger.debug validReq.body
        return

      logger.debug 'VERO WEBHOOK DELIVERED'
      logger.debug validReq.body

      if /notification/.test validReq.body.campaign["trigger-event"]
        notificationQueueSvc.update {
          id: validReq.body.event.data.notification_id
          status: 'delivered'
        }
        return
      logger.debug "ignoring event.name: #{validReq.body.campaign["trigger-event"]}"





module.exports = mergeHandles handles,
  stripe:
    method: 'post'
  vero:
    method: 'post'
