logger = require '../config/logger'
auth = require '../config/auth'
permissionsService = require '../services/service.permissions'
routes = require '../../common/config/routes'


# I'm not sure that we'll actually need this route, but it was convenient for testing

module.exports = (app) ->

  logger.infoRoute 'userPermissions', routes.userPermissions
  app.get routes.userPermissions
  , auth.requireLogin(redirectOnFail: true)
  , (req, res, next) ->
    logger.debug "getting user permissions for id: #{req.params.id}"
    permissionsService.getPermissionsForUserId(req.params.id)
      .then (userPermissions) ->
        logger.debug "got user permissions for id: #{req.params.id}"
        res.json(userPermissions)
      .catch (err) ->
        message = "error getting user permissions for id: #{req.params.id}"
        logger.error message
        logger.error ''+(err.stack ? err)
        res.status(500).json(message)

  logger.infoRoute 'groupPermissions', routes.groupPermissions
  app.get routes.groupPermissions
  , auth.requireLogin(redirectOnFail: true)
  , (req, res, next) ->
    logger.debug "getting group permissions for id: #{req.params.id}"
    permissionsService.getPermissionsForGroupId(req.params.id)
      .then (groupPermissions) ->
        logger.debug "got group permissions for id: #{req.params.id}"
        res.json(groupPermissions)
      .catch (err) ->
        message = "error getting group permissions for id: #{req.params.id}"
        logger.error message
        logger.error ''+(err.stack ? err)
        res.status(500).json(message)
