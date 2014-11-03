app = require '../app.coffee'

_this = app.config ['$locationProvider', ($locationProvider) ->
  $locationProvider.html5Mode(true)
  # $locationProvider.hashPrefix("!")
]

module.exports = _this
