cls = require 'continuation-local-storage'
logger = require('../config/logger').spawn("utils:cls")
{NAMESPACE} = require '../config/config'

module.exports = (namespace = cls.getNamespace(NAMESPACE)) ->

  getCurrentUserId = () ->
    req = namespace.get('req')
    console.log "req keys: #{JSON.stringify(Object.keys(req))}"
    console.log "req.user: #{JSON.stringify(req.user)}"
    console.log "req.session: #{JSON.stringify(req.session)}"
    if !req.user?.id?
      return null
    return req.user.id
    # if !req.session?.userid?
    #   return null
    # return req.session.userid

  {
    namespace
    getCurrentUserId
  }
