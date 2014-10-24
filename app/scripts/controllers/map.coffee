app = require '../app.coffee'
require '../factories/mapOptions.coffee'
require '../factories/map.coffee'

###
  Our Main Map Controller, logic
  is in a specific factory where Map is a GoogleMap
###
map = undefined
module.exports = app.controller 'MapCtrl'.ourNs(), [
  '$scope','Map'.ourNs(), 'MapOptions'.ourNs()
  ($scope, Map, PromisedOptions) ->
      map = null
      PromisedOptions.then (options) ->
        map = new Map($scope, options)
      .catch (e) ->
        console.error e
]
