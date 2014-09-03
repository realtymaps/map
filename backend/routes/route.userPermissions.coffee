logger = require '../config/logger'

# I'm not sure that we'll actually need this route, but it was convenient for testing

module.exports = (app) ->
  userPermissionsService = require('../services/service.userPermissions')(app)

  app.get '/user_permissions/:id', (req, res) ->
    logger.info "get user permissions for id: #{req.params.id}"
    userPermissionsService.getPermissionsForUserId req.params.id, (err, userPermissions) ->
      res.send(userPermissions)
