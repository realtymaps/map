app = require '../app.coffee'

_this = app.config ($locationProvider) ->
  $locationProvider.html5Mode(true)

module.exports = _this
