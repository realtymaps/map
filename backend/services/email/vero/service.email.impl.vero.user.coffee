_ = require 'lodash'
{onMissingArgsFail} = require '../../../utils/errors/util.errors.args'
config = require '../../../config/config'

VeroUser = (vero) ->

  createOrUpdate = (opts) ->
    onMissingArgsFail args: opts, required: ['authUser', 'eventName']

    {authUser, subscriptionStatus, eventName, eventData} = opts

    vero.createUserAndTrackEvent(
      @getUniqueUserId(authUser), authUser.email,
        _.extend(
          _.pick(authUser, ['first_name','last_name']),
          subscription_status: subscriptionStatus || 'trial'
        ), eventName, eventData)

  deleteMe = (id) ->
    vero.deleteUser(id)

  getUniqueUserId = (authUser) ->
    if !authUser?.id
      throw new Error("Cannot get Vero id for user")
    if config.ENV == 'production'
      return "production_#{authUser.id}"
    else
      if config.RMAPS_MAP_INSTANCE_NAME
        return "#{config.RMAPS_MAP_INSTANCE_NAME}_#{config.ENV}_#{authUser.id}"
      else
        throw new Error("Please set RMAPS_MAP_INSTANCE_NAME")

  createOrUpdate: createOrUpdate
  "delete": deleteMe
  getUniqueUserId: getUniqueUserId

module.exports = VeroUser
