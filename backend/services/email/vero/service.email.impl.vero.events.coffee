_ = require 'lodash'
{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'

module.exports = (vero) ->
  createOrUpdate = require('./service.email.impl.vero.user')(vero)

  # * `subscriptionStatus`  identify a user as 'paid or default or more' {[string]}.
  #
  # Returns the vero-promise response as Promise([user, event]).
  signUp = (opts) ->
    onMissingArgsFail
      verifyUrl: {val:opts.verifyUrl, required: true}

    {verifyUrl} = opts
    delete opts.verifyUrl

    createOrUpdate _.extend {}, opts,
      eventName: 'customer.subscription.new'
      eventData: verify_url: verifyUrl

  _cancelPlan = (opts) ->
    onMissingArgsFail
      cancelPlanUrl: {val:opts.cancelPlanUrl, required: true}
      authUser: {val:opts.authUser, required: true}

    {cancelPlanUrl, eventName} = opts
    delete opts.cancelPlanUrl

    createOrUpdate _.extend {}, opts,
      eventName: eventName
      eventData: cancel_plan_url: authUser.cancel_email_hash

  trialEnding = (opts) ->
    _cancelPlan _.extend {}, opts, eventName: 'user.trial.ending'

  signUp: signUp
  trialEnding: trialEnding
