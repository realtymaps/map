mod = require '../module.coffee'

mod.config ($provide, nemSimpleLoggerProvider) ->
  $provide.decorator nemSimpleLoggerProvider.decorator...
