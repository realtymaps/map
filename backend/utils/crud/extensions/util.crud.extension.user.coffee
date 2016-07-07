_ = require 'lodash'
logger = require '../../../config/logger'
clone = require 'clone'

withRestriction = (req, toBeQueryClause, restrict, cb) ->
  unless toBeQueryClause
    toBeQueryClause = req.query or {}
  _.extend toBeQueryClause, restrict
  # logger.debug toBeQueryClause, true
  # logger.debug req.query, true
  cb(toBeQueryClause) if cb?

cloneRequest = (req) ->
  params: clone req.params
  query: clone req.query
  body: clone req.body
  user: clone req.user

route =
  cloneRequest: cloneRequest

  ###
    Purpose is to extend some object to be used as the query clause of a query by a service.
    Most of the time this will be req.query to be used, However sometimes it could be req.body.
  ###
  withRestriction: withRestriction

  withUser: (req, toBeQueryClause, cb) ->
    if !req.user
      throw new Error('User not logged in')
    withRestriction req, toBeQueryClause, auth_user_id: req.user.id, cb

  withParent: (req, toBeQueryClause, cb) ->
    if !req.user
      throw new Error('User not logged in')
    withRestriction req, toBeQueryClause, parent_auth_user_id: req.user.id, cb

  ###
    Add query/post-data restrictions across all methods
  ###
  restrictAll: (restrictFn, doLog = false) ->
    for prefix in ['root', 'byId']
      do (prefix) =>
        for method in ['GET', 'POST', 'DELETE', 'PUT']
          do (method) =>
            name = "#{prefix}#{method}"
            wrapped = @[name]
            @[name] = (req, res, next) =>
              logger.debug "restrictFn: calling handle #{name}" if doLog
              toBeQueryClause = if method == 'POST' || method == 'PUT' then req.body else req.query
              restrictFn req, toBeQueryClause, =>
                logger.debug "restrictFn: handle #{name}: calling wrapped.call" if doLog
                wrapped.call @, req, res, next

  toLeafletMarker: (rows, deletes = [], deafaultCoordLocation = 'geometry_center') ->
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
