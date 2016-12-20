logger = require('../config/logger').spawn("route:webhooks")
{validateAndTransformRequest} = require '../utils/util.validation'
stripeTransforms = require '../utils/transforms/transforms.webhooks.stripe'
veroTransforms = require '../utils/transforms/transforms.webhooks.vero'
veroWebhookEvents = require '../enums/enum.vero.webhook.events'
paymentServices = require('../services/services.payment').then (services) ->
  # '../services/services.payment' is same as '../services/payment/stripe/service.payment.impl.stripe.events'
  paymentServices = services

notificationQueueSvc = require('../services/service.notification.queue').instance

module.exports =
  stripe:
    method: 'post'
    handleQuery: true
    #https://dashboard.stripe.com/account/webhooks
    #https://stripe.com/docs/api#events
    #https://stripe.com/docs/webhooks
    #https://stripe.com/docs/recipes/sending-emails-for-failed-payments
    handle: (req) ->
      validateAndTransformRequest req, stripeTransforms.event
      .then (validReq) ->
        {body} = validReq
        logger.debug "valid stripe event: #{JSON.stringify validReq}"
        paymentServices.events.handle(body)


  vero:
    method: 'post'
    handleQuery: true
    #http://help.getvero.com/articles/setting-up-veros-webhooks.html
    handle: (req) ->
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

        if /notification/.test validReq.body.campaign["trigger-event"] && validReq.body.event?.data?
          notificationQueueSvc.update {
            id: validReq.body.event.data.notification_id
            status: 'delivered'
          }
          return

        if !validReq.body.event?.data?
          return logger.debug "ignoring event.name: #{validReq.body.campaign["trigger-event"]}, MISSING validReq.body.event.data"
        logger.debug "ignoring event.name: #{validReq.body.campaign["trigger-event"]}"
