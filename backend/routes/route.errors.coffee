# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("route:errors")
# coffeelint: enable=check_scope
tables = require '../config/tables'
dbs = require '../config/dbs'
Promise = require 'bluebird'
_ = require 'lodash'
session = require 'express-session'
uaParser = require 'ua-parser-js'
sqlHelpers = require '../utils/util.sql.helpers'
auth = require '../utils/util.auth'
errors = require '../utils/errors/util.error.partiallyHandledError'
sourcemapSvc = require '../services/service.sourcemap'

module.exports =

  browserById:
    method: 'post'
    handleQuery: true
    middleware: [
      auth.requireLogin()
      auth.requirePermissions({all:['access_staff']})
    ]
    handle: (req, res) -> Promise.try ->
      if req.body.handled? && req.params.reference
        tables.history.browserError()
        .update('handled', req.body.handled)
        .where('reference', req.params.reference)
        .then -> true
      else
        false

  browser:
    handleQuery: true
    middleware: [
      auth.requireLogin()
      auth.requirePermissions({all:['access_staff']})
    ]
    handle: (req, res) -> Promise.try ->
      filter = (q) ->
        if req.query.reference
          q.where('reference', req.query.reference)
        if req.query.unhandled == 'true'
          q.where('handled', false)
        q

      if req.query.distinct == 'true'
        q = tables.history.browserError().from ->
          @select(dbs.get('main').raw('DISTINCT ON (message) *'))
          @from(tables.history.browserError().tableName)
          @orderBy('message')
          filter(@).as('sub')
      else
        q = tables.history.browserError().select()
        filter(q)

      if req.query.limit
        q.limit(req.query.limit)

      if req.query.offset
        q.offset(req.query.offset)

      q.orderBy('rm_inserted_time', 'desc')

      q.then (errorLogs) ->
        if !req.query.sourcemap
          return errorLogs
        else
          Promise.map errorLogs, (errorLog) ->
            if errorLog.mapped # browser already sourcemapped it, gtfo
              errorLog
            else
              sourceMapConfig = Promise.resolve() # default will use whatever url is in the errorLog
              if req.query.sourcemap == 's3'
                if !errorLog.git_revision
                  return errorLog
                sourceMapConfig = sourcemapSvc.fromS3Config(errorLog)
              else if req.query.sourcemap == 'network'
                if !errorLog.git_revision
                  return errorLog
                sourceMapConfig = sourcemapSvc.fromNetworkConfig(errorLog)
              else if req.query.sourcemap == 'local'
                sourceMapConfig = sourcemapSvc.fromLocalConfig(errorLog)
              sourceMapConfig.then (config) ->
                sourcemapSvc.pinpoint(errorLog.stack, config)
                .then (betterStack) ->
                  errorLog.betterStack = betterStack
                  errorLog
              .catch (err) ->
                logger.debug err
                errorLog

    .catch (err) ->
      throw new errors.PartiallyHandledError(err, "Problem loading stacks and/or sourcemap")

  # Logs front-end errors to the history.browserError table
  capture:
    method: 'post'
    handleQuery: true
    middleware: auth.sessionSetup
    handle: (req, res) -> Promise.try ->
      data = req.body.stack # stacktrace-js sends everything inside the stack object

      uaInfo = {}
      if req.headers?['user-agent']?
        uaInfo = uaParser(req.headers['user-agent'])

      session = _.omit(req.session, (val) -> if typeof(val) == 'function' then return true)
      if _.isEmpty(session)
        session = null

      logEntity =
        reference: data.errorRef
        count: data.count
        message: data.msg
        file: data.file
        line: data.line
        col: data.col
        stack: sqlHelpers.safeJsonArray(data.stack)
        url: data.url
        userid: req.user?.id || data.userid
        email: req.user?.email || data.email
        ip: req.ip
        referrer: req.headers?.referer || req.headers?.referrer || null
        ua: uaInfo.ua
        ua_browser: uaInfo.browser
        ua_engine: uaInfo.engine
        ua_os: uaInfo.os
        ua_device: uaInfo.device
        ua_cpu: uaInfo.cpu
        mapped: !!data.mapped
        git_revision: data.git_revision

      tables.history.browserError()
      .insert(logEntity)
      .then () ->
        true
    .catch (err) ->
      throw new errors.PartiallyHandledError(err, "Problem logging browser error: #{JSON.stringify(req.body,null,2)}")

  requestById:
    method: 'post'
    handleQuery: true
    middleware: [
      auth.requireLogin()
      auth.requirePermissions({all:['access_staff']})
    ]
    handle: (req, res) -> Promise.try ->
      if req.body.handled? && req.params.reference
        tables.history.requestError()
        .update('handled', req.body.handled)
        .where('reference', req.params.reference)
        .then -> true
      else
        false

  request:
    handleQuery: true
    middleware: [
      auth.requireLogin()
      auth.requirePermissions({all:['access_staff']})
    ]
    handle: (req, res) -> Promise.try ->
      filter = (q) ->
        if req.query.reference
          q.where('reference', req.query.reference)
        if req.query.unhandled == 'true'
          q.where('handled', false)
        if req.query.unexpected == 'true'
          q.where('unexpected', true)
        if req.query['404'] == 'false'
          q.whereNot('response_status', 404)
        q

      if req.query.distinct == 'true'
        q = tables.history.requestError().from ->
          @select(dbs.get('main').raw('DISTINCT ON (url,method) *'))
          @from(tables.history.requestError().tableName)
          @orderBy('url')
          @orderBy('method')
          filter(@).as('sub')
      else
        q = tables.history.requestError().select()
        filter(q)

      if req.query.limit
        q.limit(req.query.limit)

      if req.query.offset
        q.offset(req.query.offset)

      q.orderBy('rm_inserted_time', 'desc')

    .catch (err) ->
      throw new errors.PartiallyHandledError(err, "Problem loading request errors")
