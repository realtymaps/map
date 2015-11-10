app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsRecipientCtrl', ($rootScope, $scope, $state, rmapsprincipal) ->
