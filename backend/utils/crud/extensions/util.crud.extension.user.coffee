_ = require 'lodash'

toLeafletMarker = (rows, deletes, deafaultCoordLocation) ->
  for row in rows
    row.coordinates = row[deafaultCoordLocation].coordinates
    row.type = row[deafaultCoordLocation].type

    for del in deletes
      delete row[del]

  rows

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

    toLeafletMarker: (maybePromise, deletes = [], deafaultCoordLocation = 'geom_point_json') ->
      if maybePromise.then?
        return maybePromise.then (rows) ->
          toLeafletMarker(rows, deletes, deafaultCoordLocation)

      toLeafletMarker(maybePromise, deletes, deafaultCoordLocation)
