requires = './baseGoogleMap.coffee'

app = require '../app.coffee'

###
  Our Main Map Controller, logic
  is in a specific factory where Map is a GoogleMap
###
module.exports = app.controller 'MapCtrl'.ourNs(), [
  '$scope', 'Map'.ourNs(),
  ($scope, Map) ->
    new Map($scope)
]
