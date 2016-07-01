{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'
{
  handler
  CustomerCreateFailedError
  StripeInvalidRequestError
} = require '../../../utils/errors/util.errors.stripe'
tables = require '../../../config/tables'
logger = require('../../../config/logger').spawn('stripe')
stripeErrorEnums = require '../../../enums/enum.stripe.errors'
_ = require 'lodash'

StripeCustomers = (stripe) ->

  remove = (authUser) ->
    onMissingArgsFail
      args:
        id: authUser.stripe_customer_id
      required: ['id']

    stripe.customers.del authUser.stripe_customer_id
    .then () ->
      logger.info "Success: removal of customer #{authUser.stripe_customer_id}"

  handleCreationError = (opts) ->
    onMissingArgsFail
      args: opts
      required: ['authUser', 'error']

    {error, trx, error, authUser, error_name, attempt} = opts

    logger.error 'Some Error workflow error has ocurred with stripe. Therefore a customer must be backed out.'
    logger.error error

    remove(authUser.stripe_customer_id)
    .catch (error) ->
      handleObj = {}

      handleObj["default"] = () ->
        logger.error "error.type: #{error.type}"
        logger.error "error.message: #{error.message}"
        logger.error "Critical Error on backing a customer out."

        logger.info "Putting customer clean up into a job."
        payload =
          auth_user_id: authUser.id
          error_name: error_name or stripeErrorEnums.stripeCustomerRemove
          data:
            errors: [error]
            customer: authUser.stripe_customer_id
            attempt: attempt or 1

        logger.debug payload, true
        tables.user.errors(transaction: trx).insert payload

      handleObj[StripeInvalidRequestError.type] = () ->
        return if /no such customer/i.test error.message
        handleObj.default()

      handler error, handleObj

      throw error

  # at this point a user should already be in auth_user
  create = (opts, extraDescription = '') ->
    onMissingArgsFail
      args: opts
      required: ['authUser','plan','token', 'trx']

    token = opts.token.id
    {authUser, plan, trx} = opts

    stripe.customers.create
      source: token
      plan: plan
      description: authUser.email + ' ' + extraDescription

    .then (customer) ->
      [subscription] = _.filter customer.subscriptions.data, (el) -> el.plan.id == plan
      _.extend authUser,
        stripe_customer_id: customer.id
        stripe_subscription_id: subscription.id

      tables.auth.user(transaction: trx)
      .update
        stripe_customer_id: customer.id
        stripe_subscription_id: subscription.id
      .where id: authUser.id
      .then () ->
        authUser: authUser
        customer: customer
      .catch (error) ->
        handleCreationError error, authUser
        throw new CustomerCreateFailedError(error) #rethrow so any db stuff is also reverted

  get = (authUser) ->
    logger.debug "stripe.customers.retrieve #{authUser.stripe_customer_id}"
    if !authUser.stripe_customer_id?
      throw new Error("`stripe_customer_id` is null for user #{authUser.id}.  Ensure session is updated, frontend refreshed, and stripe account made.")
    stripe.customers.retrieve authUser.stripe_customer_id

  getSources = (authUser) ->
    get(authUser)
    .then (customer) ->
      customer?.sources?.data

  getDefaultSource = (authUser) ->
    get(authUser)
    .then (customer) ->
      _.find customer?.sources?.data, 'id', customer?.default_source

  replaceDefaultSource = (authUser, source) ->
    stripe.customers.update authUser.stripe_customer_id, {source: source}
    .then (customer) ->
      _.find customer?.sources?.data, 'id', customer?.default_source

  charge = (opts, idempotency_key) ->
    _.defaults opts,
      currency: 'usd'
      capture: true

    onMissingArgsFail
      args: opts
      required: ['amount', 'currency', 'source', 'description']

    opts.amount = Math.round(opts.amount * 100) # dollars to cents

    if idempotency_key
      headers = {idempotency_key}

    logger.debug -> "Creating stripe charge: #{JSON.stringify opts} #{JSON.stringify headers}"
    stripe.charges.create opts, headers

  capture = (opts, idempotency_key) ->
    onMissingArgsFail
      args: opts
      required: [ 'charge' ]

    if opts.amount
      opts.amount = Math.round(opts.amount * 100) # dollars to cents

    logger.debug -> "Capturing stripe charge: #{JSON.stringify opts}"
    stripe.charges.capture opts.charge, _.pick opts, [ 'amount', 'receipt_email', 'statement_descriptor' ]

  remove: remove
  create: create
  get: get
  getDefaultSource: getDefaultSource
  replaceDefaultSource: replaceDefaultSource
  charge: charge
  capture: capture
  handleCreationError: handleCreationError

module.exports = StripeCustomers
