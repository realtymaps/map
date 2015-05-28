app = require '../app.coffee'

module.exports = app.config [ '$locationProvider', ($locationProvider) ->
  $locationProvider.html5Mode(true)
]
