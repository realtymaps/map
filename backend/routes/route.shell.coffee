auth = require '../utils/util.auth'
ExpressResponse = require '../utils/util.expressResponse'
{exec} = require 'child_process'
httpStatus = require '../../common/utils/httpStatus'
{shellHistory} = require("../config/tables").user
logger = require("../config/logger").spawn("route:shell")
Promise = require 'bluebird'
_ = require 'lodash'

module.exports =
  shell:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['execute_shell']}, logoutOnFail:true)
    ]
    handle: (req, res, next) ->
      if !req.query.cmd
        return next new ExpressResponse({alert: "misssing cmd query param"}, {status: httpStatus.BAD_REQUEST, quiet: true})
      exec req.query.cmd, (err, stdout, stderr) ->
        logger.info "executing command '#{req.query.cmd}'"

        entity =
          auth_user_id: req.user.id
          executed_cmd: req.query.cmd

        if stdout
          logger.info stdout
          _.extend entity, {stdout}

        if err
          logger.error err

          _.extend entity, error: err || stderr

        Promise.try -> shellHistory().insert entity

        logger.info "stdout"
        logger.info stdout
        logger.info "stderr"
        logger.info stderr

        res.header('Content-Type', 'text/plain')
        res.send stdout or stderr
