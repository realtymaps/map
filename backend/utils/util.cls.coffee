cls = require 'continuation-local-storage'
logger = require('../config/logger').spawn("utils:cls")
{NAMESPACE} = require '../config/config'

module.exports = (namespace = cls.getNamespace(NAMESPACE)) ->

  getCurrentUserId = () ->
    req = namespace.get('req')
    req.user?.id

  {
    namespace
    getCurrentUserId
  }
