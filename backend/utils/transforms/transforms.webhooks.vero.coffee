_ = require 'lodash'
{validators} = require '../util.validation'
commonConfig = require '../../../common/config/commonConfig'
webhookEvents = require '../../enums/enum.vero.webhook.events'
veroEvents = require '../../enums/enum.vero.events'
validation = require '../util.validation'
Case = require 'case'

#http://help.getvero.com/articles/setting-up-veros-webhooks.html

common =
  type: validators.string(minLength: 2, in: Object.keys(webhookEvents))
  user: validators.object subValidateSeparate:
    #our id system is setup to emails (configurable)
    id: validators.string(minLength: 2, regex: commonConfig.validation.email)
    email: validators.string(minLength: 2, regex: commonConfig.validation.email)

event =
  params: validators.object isEmptyProtect: true
  query:  validators.object isEmptyProtect: true
  body: validators.object subValidateSeparate: common

#separate since unsubscribed does not contain the compaign portion
campaignEvent =
  params: validators.object isEmptyProtect: true
  query:  validators.object isEmptyProtect: true
  body: validators.object subValidateSeparate: _.extend {}, common,
    campaign: validators.object()
    event: validators.object subValidateSeparate:
      name: validators.string(minLength: 2, in: _.values(veroEvents).concat(_.values(veroEvents).map (c) -> Case.snake c))
      data: validators.object()

validateAndTransformRequest = (req) ->
  validation.validateAndTransformRequest req, event
  .then (validReq) ->
    if validReq.body.type == webhookEvents.unsubscribed
      return validReq
    validation.validateAndTransformRequest req, campaignEvent

module.exports = {
  event
  campaignEvent
  validateAndTransformRequest
}
