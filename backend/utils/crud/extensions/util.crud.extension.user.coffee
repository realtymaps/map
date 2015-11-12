_ = require 'lodash'
logger = require '../../../config/logger'

withRestriction = (req, toBeQueryClause, restrict, cb) ->
  unless toBeQueryClause
    toBeQueryClause = req.query or {}
  _.extend toBeQueryClause, restrict
  # logger.debug toBeQueryClause, true
  # logger.debug req.query, true
  cb(toBeQueryClause) if cb?

withAuthRestriction = (req, toBeQueryClause, restrict, cb) ->
  if !req.user
    throw new Error('User not logged in')
  withRestriction(req, toBeQueryClause, restrict, cb)

restrict = (restrictFn, doLog = false, prefixes = ['root', 'byId'], methods = ['GET', 'POST', 'DELETE', 'PUT']) ->
  if doLog
    logger.debug "prefixes: #{prefixes}"
    logger.debug "methods: #{methods}"
  for prefix in prefixes
    do (prefix) =>
      for method in methods
        do (method) =>
          name = "#{prefix}#{method}"
          wrapped = @[name]
          @[name] = (req, res, next) =>
            logger.debug "restrictFn: calling handle #{name}" if doLog
            toBeQueryClause = if method == 'POST' || method == 'PUT' then req.body else req.query
            restrictFn req, toBeQueryClause, =>
              if doLog
                logger.debug "restrictFn: handle #{name}: calling wrapped.call"
                logger.debug toBeQueryClause
              wrapped.call @, req, res, next

route =
  ###
    Purpose is to extend some object to be used as the query clause of a query by a service.
    Most of the time this will be req.query to be used, However sometimes it could be req.body.
  ###
  withRestriction: withRestriction

  withAuthRestriction: withAuthRestriction

  withUser: (userIdKey = "auth_user_id") -> (req, toBeQueryClause, cb) ->
    obj = {}
    obj[userIdKey] = req.user.id
    withAuthRestriction req, toBeQueryClause, obj, cb

  withParent: (req, toBeQueryClause, cb) ->
    withAuthRestriction req, toBeQueryClause, parent_auth_user_id: req.user.id, cb

  withParamId: (paramsMap, overrideClauseCb, doLog) -> (req, toBeQueryClause, cb) ->
    for key, val of paramsMap
      origVal = req.params[key]
      req.params[val] = origVal
      delete req.params[key]

    if doLog
      logger.debug req.params, true

    overrideClause = overrideClauseCb?(req)
    withAuthRestriction req, overrideClause or toBeQueryClause, req.params, cb

  ###
    Add query/post-data restrictions across all methods
  ###
  restrictAll: (restrictFn, doLog = false, methods) ->
    restrict.call(@, restrictFn, doLog, undefined, methods)

  restrictById: (restrictFn, doLog = false, methods) ->
    logger.debug "restrictById"
    restrict.call(@, restrictFn, doLog, ['byId'], methods)

  restrict: restrict

  toLeafletMarker: (rows, deletes = [], deafaultCoordLocation = 'geom_point_json') ->
    if !_.isArray rows
      originallyObject = true
      rows = [rows]

    for row in rows
      # logger.debug row, true
      row.coordinates = row[deafaultCoordLocation]?.coordinates
      row.type = row[deafaultCoordLocation]?.type

      for del in deletes
        delete row[del]

    if originallyObject
      return rows[0]
    rows

module.exports.route = route
