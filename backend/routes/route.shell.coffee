auth = require '../utils/util.auth'
ExpressResponse = require '../utils/util.expressResponse'
{exec} = require 'child_process'
httpStatus = require '../../common/utils/httpStatus'
logger = require("../config/logger").spawn("route:shell")

module.exports =
  shell:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['access_staff']}, logoutOnFail:true)
    ]
    handle: (req, res, next) ->
      if !req.query.cmd
        return next new ExpressResponse(alert: "misssing cmd query param", httpStatus.BAD_REQUEST)
      exec req.query.cmd, (err, stdout, stderr) ->
        logger.info "executing command '#{req.query.cmd}'"
        logger.info stdout
        if err
          logger.error err

        logger.info "stdout"
        logger.info stdout
        logger.info "stderr"
        logger.info stderr

        res.header('Content-Type', 'text/plain')
        res.send stdout or stderr
