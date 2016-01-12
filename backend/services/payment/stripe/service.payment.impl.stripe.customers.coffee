{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'
userService = require('../../services.user').user
_ = require 'lodash'

StripeCustomers = (stripe) ->
  # at this point a user should already be in auth_user
  create: (opts, extraDescription = '') ->
    onMissingArgsFail
      authUser: {val:opts.authUser, required: true}
      plan: {val:opts.plan, required: true}
      safeCard: {val:opts.plan, required: true} #client side card info we can save to user_credit_cards

    token = opts.safeCard.id
    {authUser, plan} = opts

    stripe.customers.create
      source: token
      plan: plan
      description: authUser.email + ' ' + extraDescription

    .then (customer) ->
      userService.update authUser.id, stripe_customer_id: customer.id, ['stripe_customer_id']
      .then () ->
        authUser: _.extend authUser, stripe_customer_id: customer.id
        customer: customer


  get: (authUser) ->
    stripe.customers.retrieve authUser.stripe_customer_id

module.exports = StripeCustomers
