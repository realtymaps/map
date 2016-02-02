{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'
{CustomerCreateFailed} = require '../../../utils/errors/util.errors.stripe'
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

    {error, trx, error, authUser, error_name} = opts

    logger.error 'Some Error workflow error has ocurred with stripe. Therefore a customer must be backed out.'
    logger.error error

    remove(authUser.stripe_customer_id).catch (removeError) ->
      logger.error "Critical Error on backing a customer out."
      logger.error removeError
      logger.info "Putting customer clean up into a job."
      tables.auth.toM_errors(trx).insert
        auth_user_id: authUser.id
        error_name: error_name or stripeErrorEnums.stripeCusomerRemove
        data: error: error
      throw error

  # at this point a user should already be in auth_user
  create = (opts, extraDescription = '') ->
    onMissingArgsFail
      args: opts
      required: ['trx', 'authUser','plan','token']

    token = opts.token.id
    {authUser, plan, trx} = opts

    stripe.customers.create
      source: token
      plan: plan
      description: authUser.email + ' ' + extraDescription

    .then (customer) ->
      _.extend authUser, stripe_customer_id: customer.id

      tables.auth.user(trx)
      .update stripe_customer_id: customer.id
      .where id: authUser.id
      .then () ->
        authUser: authUser
        customer: customer
      .catch (error) ->
        handleCreationError error, authUser
        throw new CustomerCreateFailed(error) #rethrow so any db stuff is also reverted

  get = (authUser) ->
    stripe.customers.retrieve authUser.stripe_customer_id

  remove: remove
  create: create
  get: get
  handleCreationError: handleCreationError

module.exports = StripeCustomers
