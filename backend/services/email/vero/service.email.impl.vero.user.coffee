_ = require 'lodash'
{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'

module.exports = (vero) ->

  createOrUpdate = (opts) ->
    onMissingArgsFail
      authUser: {val:opts.authUser, required: true}
      eventName: {val:opts.eventName, required: true}
      eventData: {val:opts.eventName, required: true}

    {authUser, subscriptionStatus, eventName, eventData} = opts

    vero.createUserAndTrackEvent(
      authUser.email, authUser.email, _.extend(
        _.pick(authUser, [
          'first_name'
          'last_name'
          'plan'
          ])),
        subscription_status: subscriptionStatus or 'trial'
      , eventName, eventData)

  "delete": (id) ->
    vero.deleteUser(id)

  # * `subscriptionStatus`  identify a user as 'paid or default or more' {[string]}.
  #
  # Returns the vero-promise response as Promise([user, event]).
  signUp = (opts) ->
    onMissingArgsFail
      verifyUrl: {val:opts.verifyUrl, required: true}

    {verifyUrl} = opts
    delete opts.verifyUrl

    createOrUpdate _.extend {}, opts,
      eventName: 'New user email'
      eventData: verify_url: verifyUrl


  createOrUpdate: createOrUpdate
  signUp: signUp
