# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("route:monitor")
# coffeelint: enable=check_scope
tables = require '../config/tables'
Promise = require 'bluebird'
_ = require 'lodash'
session = require 'express-session'
uaParser = require 'ua-parser-js'
sqlHelpers = require '../utils/util.sql.helpers'
auth = require '../utils/util.auth'
errors = require '../utils/errors/util.error.partiallyHandledError'

module.exports =

  # Logs front-end errors to the history.browserError table
  error:
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

      tables.history.browserError()
      .insert(logEntity)
      .then () ->
        true
    .catch (err) ->
      throw new errors.PartiallyHandledError(err, "Problem logging browser error: #{JSON.stringify(req.body,null,2)}")
