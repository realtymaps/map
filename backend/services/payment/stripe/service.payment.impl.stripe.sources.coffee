Promise = require 'bluebird'
tables = require '../../../config/tables'
logger = require('../../../config/logger').spawn("service:paymentMethod")
{expectSingleRow} = require '../../../utils/util.sql.helpers'


module.exports = (stripe) ->

  customerService = require('./service.payment.impl.stripe.customers')(stripe)

  _verifyUser = (user_id, cb) -> Promise.try ->
    return throw new Error "Stripe API not ready" if !customerService
    tables.auth.user()
    .select 'stripe_customer_id'
    .where id: user_id
    .then (authUser) ->
      expectSingleRow(authUser)

  getAll = (user_id) -> Promise.try ->
    _verifyUser(user_id).then (authUser) ->
      customerService.getSources(authUser)

  ### servicing, and db / stripe API for payment method operations ###
  getDefault = (user_id) -> Promise.try ->
    l = logger.spawn('getDefault')
    _verifyUser(user_id).then (authUser) ->
      customerService.getDefaultSource(authUser)
      .then (source) ->
        l.debug -> "default payment method:\n#{JSON.stringify(source,null,2)}"
        source

  replaceDefault = (user_id, source) -> Promise.try ->
    l = logger.spawn('replaceDefault')
    _verifyUser(user_id).then (authUser) ->
      customerService.replaceDefaultSource(authUser, source)
      .then (res) ->
        l.debug -> "new default payment method:\n#{JSON.stringify(source,null,2)}"
        res

  add = (user_id, source) -> Promise.try ->
    l = logger.spawn('add')
    _verifyUser(user_id).then (authUser) ->
      customerService.addSource(authUser, source)
      .then (res) ->
        l.debug -> "new payment method:\n#{JSON.stringify(source,null,2)}"
        res

  #note there is no stripe.sources.delete/remove, only deleteCard
  #so there may be a conflict in context, but for now this is fine
  remove = (user_id, source) -> Promise.try ->
    l = logger.spawn('remove')
    _verifyUser(user_id).then (authUser) ->
      stripe.customers.deleteCard(authUser.stripe_customer_id, source)
      .then (res) ->
        l.debug -> "payment method removed:\n#{JSON.stringify(source,null,2)}"
        res

  setDefault = (user_id, source) -> Promise.try ->
    l = logger.spawn('makeDefaultSource')
    _verifyUser(user_id).then (authUser) ->
      customerService.setDefaultSource(authUser, source)
      .then (res) ->
        l.debug -> "new payment method:\n#{JSON.stringify(source,null,2)}"
        res

  {
    getDefault
    replaceDefault
    getAll
    add
    setDefault
    remove
  }
