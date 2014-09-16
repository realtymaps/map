app = require '../app.coffee'
require '../factories/mapOptions.coffee'
require '../factories/map.coffee'

###
  Our Main Map Controller, logic
  is in a specific factory where Map is a GoogleMap
###
map = undefined
module.exports = app.controller 'MapCtrl'.ourNs(), [
  '$scope', 'Map'.ourNs(), 'MapOptions'.ourNs()
  ($scope, Map, PromisedOptions) ->
    PromisedOptions.then (options) ->
      map = unless map then new Map($scope, options) else map
    .catch (e) ->
      console.error e
]
