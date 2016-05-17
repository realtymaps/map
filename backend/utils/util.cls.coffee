{getNamespace} = require 'continuation-local-storage'
{NAMESPACE} = require '../config/config'

module.exports = (namespace = getNamespace(NAMESPACE)) ->

  getCurrentUserId = () ->
    req = namespace.get('req')
    req.user.id

  {
    namespace
    getCurrentUserId
  }
