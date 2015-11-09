app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsSenderInfoCtrl', ($rootScope, $scope, $state, rmapsprincipal) ->
