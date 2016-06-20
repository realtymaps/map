_ = require 'lodash'
{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'

VeroUser = (vero) ->

  createOrUpdate = (opts) ->
    onMissingArgsFail args: opts, required: ['authUser', 'eventName']

    {authUser, subscriptionStatus, eventName, eventData} = opts

    vero.createUserAndTrackEvent(
      authUser.email, authUser.email,
        _.extend(
          _.pick(authUser, ['first_name','last_name']),
          subscription_status: subscriptionStatus || 'trial'
        ), eventName, eventData)

  deleteMe = (id) ->
    vero.deleteUser(id)

  createOrUpdate: createOrUpdate
  "delete": deleteMe

module.exports = VeroUser
