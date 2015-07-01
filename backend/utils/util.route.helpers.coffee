_ = require 'lodash'
sessionHelper = require './util.session.helpers'
logger = require '../config/logger'

class CurrentProfileError extends Error

methodExec = (req, methods) ->
  do(methods[req.method] or -> next(badRequest("HTTP METHOD: #{req.method} not supported for route.")))

currentProfile = (req) ->
  try
    sessionHelper.currentProfile(req.session)
  catch e
    throw new CurrentProfileError(e.message)

module.exports =
  methodExec: methodExec
  currentProfile: currentProfile
  CurrentProfileError: CurrentProfileError
