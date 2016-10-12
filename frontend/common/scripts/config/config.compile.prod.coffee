mod = require '../module.coffee'

#https://code.angularjs.org/1.5.5/docs/guide/production
mod.config ($compileProvider) ->
  $compileProvider.debugInfoEnabled false
