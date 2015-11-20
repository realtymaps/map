cls = require 'continuation-local-storage'
{NAMESPACE} = require "../../backend/config/config"
patchNamespaceForPromise = require 'cls-bluebird'


module.exports = () ->

  namespace = cls.createNamespace(NAMESPACE)
  patchNamespaceForPromise namespace
  ctx = namespace.createContext()
  namespace.enter(ctx)

  @addItem = (name, thing) ->
    namespace.set name, thing

  @getItem = (name) ->
    namespace.get name

  @kill = () ->
    namespace.exit(ctx)

  @
