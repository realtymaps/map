_ = require 'lodash'
{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'

VeroUser = (vero) ->

  createOrUpdate = (opts) ->
    onMissingArgsFail
      authUser: {val:opts.authUser, required: true}
      eventName: {val:opts.eventName, required: true}

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

   deleteMe =  (id) ->
    vero.deleteUser(id)

  createOrUpdate: createOrUpdate
  "delete": deleteMe

module.exports = VeroUser
