app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsMailCtrl', ($rootScope, $scope, $state, rmapsprincipal) ->
