auth = require '../utils/util.auth'
{exec} = require 'child_process'
httpStatus = require '../../common/utils/httpStatus'
tables = require("../config/tables")
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
        throw new PartiallyHandledError({returnStatus: httpStatus.BAD_REQUEST, quiet: true}, "missing cmd query param")
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

        Promise.try -> tables.history.shell().insert(entity)

        logger.info "stdout"
        logger.info stdout
        logger.info "stderr"
        logger.info stderr

        res.header('Content-Type', 'text/plain')
        res.send stdout or stderr
