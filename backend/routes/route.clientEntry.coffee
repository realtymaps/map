clientEntrySvc = require '../services/service.clientEntry'
userSessionRte = require './route.userSession'
{createPasswordHash} =  require '../services/service.userSession'
{mergeHandles, wrapHandleRoutes} = require '../utils/util.route.helpers'

handles = wrapHandleRoutes handles:

  getClientEntry: (req) ->
    clientEntrySvc.getClientEntry req.query.key

  setPasswordAndBounce: (req, res, next) ->
    console.log "res:\n#{res}"
    console.log "next:\n#{JSON.stringify(next,null,2)}"
    console.log "req.params:\n#{JSON.stringify(req.params,null,2)}"
    console.log "req.query:\n#{JSON.stringify(req.query,null,2)}"
    console.log "req.body:\n#{JSON.stringify(req.body,null,2)}"
    console.log "req.session:\n#{JSON.stringify(req.session,null,2)}"
    console.log "setPasswordAndBounce()"
    clientEntrySvc.setPasswordAndBounce req.body
    .then (client) ->
      req.body = client
      userSessionRte.login.handle(req, res, next)
      

module.exports = mergeHandles handles,
  getClientEntry:
    method: 'get'
    # handle: getClientEntry

  setPasswordAndBounce:
    method: 'put'
    # handle: setPasswordAndBounce

  # setPasswordAndBounce:
  #   method: 'put'
  #   handle: setPasswordAndBounce

