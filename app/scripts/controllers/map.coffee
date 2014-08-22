requires = './baseGoogleMap.coffee'

app = require '../app.coffee'

###
  Our Main Map Controller which can swap out its main map implementation
###
module.exports = app.controller 'MapCtrl'.ourNs(), [
  '$scope',
  'Logger'.ns(),
  '$http',
  '$timeout',
  'GoogleMapApi'.ns(),
  'BaseGoogleMap'.ourNs(),
  require('../factories/googleMap.coffee')
]