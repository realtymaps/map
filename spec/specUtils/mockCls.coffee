cls = require 'continuation-local-storage'
{NAMESPACE} = require "../../backend/config/config"

module.exports = () ->

  namespace = cls.createNamespace(NAMESPACE)
  ctx = namespace.createContext()
  namespace.enter(ctx)

  @addItem = (name, thing) ->
    namespace.set name, thing

  @getItem = (name) ->
    namespace.get name

  @kill = () ->
    namespace.exit(ctx)

  @
