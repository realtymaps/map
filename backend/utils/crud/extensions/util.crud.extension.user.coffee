_ = require 'lodash'

module.exports =
  route:
    ###
      Purpose is to extend some object to be used as the query clause of a query by a service.
      Most of the time this will be req.query to be used, However sometimes it could be req.body.
    ###
    withUser: (req, toBeQueryClause, cb) ->
      return @onError('User not logged in') unless req.user
      if _.isFunction toBeQueryClause
        cb = toBeQueryClause
        toBeQueryClause = undefined

      unless toBeQueryClause
        toBeQueryClause = req.query or {}

      _.extend toBeQueryClause, auth_user_id: req.user.id
      cb(toBeQueryClause) if cb?
