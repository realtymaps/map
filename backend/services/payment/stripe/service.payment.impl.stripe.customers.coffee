{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'
tables = require '../../../config/tables'
logger = require '../../../config/logger'
_ = require 'lodash'

StripeCustomers = (stripe) ->

  remove = (customer) ->
    onMissingArgsFail
      id: {val:customer.trx, required: true}

    stripe.customers.del customer.id

  handleStripeDisaster = (originalError, customer) ->
    logger.error 'Some Error workflow error has ocurred with stripe. Therefore a customer must be backed out.'
    logger.error originalError

    remove(customer).catch (removeError) ->
      #TODO: OMFG put it in a JOB task to clean up mess
      #https://realtymaps.atlassian.net/browse/MAPD-795
      logger.error "Critical Error on backing a cusomter out."
      logger.error removeError
      logger.info "Putting customer clean up into a job."
  # at this point a user should already be in auth_user
  create = (opts, extraDescription = '') ->
    onMissingArgsFail
      trx: {val:opts.trx, required: true}
      authUser: {val:opts.authUser, required: true}
      plan: {val:opts.plan, required: true}
      safeCard: {val:opts.plan, required: true} #client side card info we can save to user_credit_cards

    token = opts.safeCard.id
    {authUser, plan, trx} = opts

    stripe.customers.create
      source: token
      plan: plan
      description: authUser.email + ' ' + extraDescription

    .then (customer) ->
      tables.auth.user(trx)
      .update stripe_customer_id: customer.id
      .where id: authUser.id
      .then () ->
        authUser: _.extend authUser, stripe_customer_id: customer.id
        customer: customer
      .catch (error) ->
        handleStripeDisaster error, customer

  get = (authUser) ->
    stripe.customers.retrieve authUser.stripe_customer_id

  remove: remove
  create: create
  get: get

module.exports = StripeCustomers
