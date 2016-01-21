{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'
{CustomerCreateFailed} = require '../../../utils/errors/util.errors.stripe'
tables = require '../../../config/tables'
logger = require('../../../config/logger').spawn('backend:stripe')
_ = require 'lodash'

StripeCustomers = (stripe) ->

  remove = (customer) ->
    onMissingArgsFail
      id: {val:customer.id, required: true}

    stripe.customers.del customer.id
    .then () ->
      logger.info "Success: removal of customer #{customer.id}"
    .catch (error) ->
      logger.info "ERROR: removal of customer #{customer.id}"
      logger.error error
      #TODO: removal failed so add it to clean up JOB TASK
      throw error


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
      token: {val:opts.token, required: true} #client side card info we can save to user_credit_cards

    token = opts.token.id
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
        throw new CustomerCreateFailed(error) #rethrow so any db stuff is also reverted

  get = (authUser) ->
    stripe.customers.retrieve authUser.stripe_customer_id

  remove: remove
  create: create
  get: get

module.exports = StripeCustomers
