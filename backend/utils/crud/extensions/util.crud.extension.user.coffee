_ = require 'lodash'

withRestriction = (req, toBeQueryClause, restrict, cb) ->
  unless toBeQueryClause
    toBeQueryClause = req.query or {}
  _.extend toBeQueryClause, restrict
  cb(toBeQueryClause) if cb?

route =
  ###
    Purpose is to extend some object to be used as the query clause of a query by a service.
    Most of the time this will be req.query to be used, However sometimes it could be req.body.
  ###
  withRestriction: withRestriction

  withUser: (req, toBeQueryClause, cb) ->
    return @onError('User not logged in') unless req.user
    withRestriction req, toBeQueryClause, auth_user_id: req.user.id, cb

  withParent: (req, toBeQueryClause, cb) ->
    return @onError('User not logged in') unless req.user
    withRestriction req, toBeQueryClause, parent_auth_user_id: req.user.id, cb

  ###
    Add query/post-data restrictions across all methods
  ###
  restrictAll: (restrictFn) ->
    for prefix in ['root', 'byId']
      do (prefix) =>
        for method in ['GET', 'POST', 'DELETE', 'PUT']
          do (method) =>
            name = "#{prefix}#{method}"
            wrapped = @[name]
            @[name] = (req, res, next) =>
              toBeQueryClause = if method == 'POST' || method == 'PUT' then req.body else req.query
              restrictFn req, toBeQueryClause, =>
                wrapped.call @, req, res, next

  toLeafletMarker: (rows, deletes = [], deafaultCoordLocation = 'geom_point_json') ->
    for row in rows
      row.coordinates = row[deafaultCoordLocation].coordinates
      row.type = row[deafaultCoordLocation].type

      for del in deletes
        delete row[del]

    rows

module.exports.route = route
