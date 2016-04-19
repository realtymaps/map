tables = require '../config/tables'
logger = require('../config/logger').spawn("service.paymentMethod")
{expectSingleRow} = require '../utils/util.sql.helpers'

customerService = null
require('./services.payment').then (svc) ->
  customerService = svc.customers


### servicing, and db / stripe API for payment method operations ###


getDefaultSource = (user_id) ->
  return throw new Error "Stripe API not ready" if !customerService
  tables.auth.user()
  .select 'stripe_customer_id'
  .where id: user_id
  .then (authUser) ->
    expectSingleRow(authUser)
  .then (authUser) ->
    customerService.getDefaultSource authUser
    .then (source) ->
      logger.debug -> "default payment method:\n#{JSON.stringify(source,null,2)}"
      source

replaceDefaultSource = (user_id, source) ->
  return throw new Error "Stripe API not ready" if !customerService
  tables.auth.user()
  .select 'stripe_customer_id'
  .where id: user_id
  .then (authUser) ->
    expectSingleRow(authUser)
  .then (authUser) ->
    customerService.replaceDefaultSource authUser, source
    .then (res) ->
      logger.debug -> "new default payment method:\n#{JSON.stringify(source,null,2)}"
      res

module.exports =
  getDefaultSource: getDefaultSource
  replaceDefaultSource: replaceDefaultSource