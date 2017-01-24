tables = require '../../../config/tables'
logger = require('../../../config/logger').spawn("service.paymentMethod")
{expectSingleRow} = require '../../../utils/util.sql.helpers'


module.exports = (stripe) ->

  customerService = require('./service.payment.impl.stripe.customers')(stripe)

  _verifyUser = (user_id, cb) ->
    return throw new Error "Stripe API not ready" if !customerService
    tables.auth.user()
    .select 'stripe_customer_id'
    .where id: user_id
    .then (authUser) ->
      expectSingleRow(authUser)

  getAll = (user_id) ->
    _verifyUser(user_id).then (authUser) ->
      customerService.getSources(authUser)

  ### servicing, and db / stripe API for payment method operations ###
  getDefault = (user_id) ->
    _verifyUser(user_id).then (authUser) ->
      customerService.getDefaultSource(authUser)
      .then (source) ->
        logger.debug -> "default payment method:\n#{JSON.stringify(source,null,2)}"
        source

  replaceDefault = (user_id, source) ->
    _verifyUser(user_id).then (authUser) ->
      customerService.replaceDefaultSource(authUser, source)
      .then (res) ->
        logger.debug -> "new default payment method:\n#{JSON.stringify(source,null,2)}"
        res

  {
    getDefault
    replaceDefault
    getAll
  }
