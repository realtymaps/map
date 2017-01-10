# coffeelint: disable=check_scope
logger = require('../config/logger').spawn("route:monitor")
# coffeelint: enable=check_scope
tables = require '../config/tables'
analyzeValue = require '../../common/utils/util.analyzeValue'
_ = require 'lodash'
session = require 'express-session'
uaParser = require 'ua-parser-js'
sqlHelpers = require '../utils/util.sql.helpers'
auth = require '../utils/util.auth'

module.exports =

  # Logs front-end errors to the history.browserError table
  error:
    method: 'post'
    handleQuery: true
    middleware: auth.sessionSetup
    handle: (req, res, next) ->
      data = req.body

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
        logger.error("Problem while logging browser error!!!\nProblem: #{analyzeValue.getFullDetails(err)}\nOriginal request error log: #{JSON.stringify(logEntity,null,2)}")
        false
