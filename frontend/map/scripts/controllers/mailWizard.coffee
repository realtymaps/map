app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsMailWizardCtrl', ($rootScope, $scope, $log, $state, rmapsprincipal) ->
  $log.debug "#### state:"
  $log.debug $state
  $scope.step = $state.current.name
  $scope.templateType = "basicLetter"