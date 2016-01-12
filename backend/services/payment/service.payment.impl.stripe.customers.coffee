{onMissingArgsFail} = require '../../utils/errors/util.errors.args'
userService = require('../services.user').user

module.exports = (stripe) ->
  # at this point a user should already be in auth_user
  create: (opts, extraDescription = '') ->
    onMissingArgsFail
      authUser: {val:opts.authUser, required: true}
      plan: {val:opts.plan, required: true}
      safeCard: {val:opts.plan, required: true} #client side card info we can save to user_credit_cards

    token = opts.safeCard.id

    stripe.customers.create
      source: token
      plan: opts.plan
      description: opts.authUser.email + extraDescription

    .then (customer) ->
      userService.update opts.authUser.id, stripe_customer_id: customer.id, ['stripe_customer_id']
      .then (savedId) ->
        if opts.authUser.id != savedId
          throw new Error 'Invalid user update of stripe_customer_id. id mismatch!!'
        customer

  get: (authUser) ->
    stripe.customers.retrieve authUser.stripe_customer_id
