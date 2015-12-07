{getNamespace} = require 'continuation-local-storage'
{NAMESPACE} = require '../config/config'

module.exports = (namespace = getNamespace(NAMESPACE)) ->
  namespace: namespace
  getCurrentUserId: () ->
    req = namespace.get('req')
    req.user.id
