clientEntrySvc = require '../services/service.clientEntry'
userSessionRte = require './route.userSession'
{createPasswordHash} =  require '../services/service.userSession'
{mergeHandles, wrapHandleRoutes} = require '../utils/util.route.helpers'

handles = wrapHandleRoutes handles:

  getClientEntry: (req) ->
    clientEntrySvc.getClientEntry req.query.key

  setPasswordAndBounce: (req, res, next) ->
    clientEntrySvc.setPasswordAndBounce req.body
    .then (client) ->
      req.body = client
      userSessionRte.login.handle(req, res, next)
      

module.exports = mergeHandles handles,
  getClientEntry:
    method: 'get'

  setPasswordAndBounce:
    method: 'put'
