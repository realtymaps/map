app = require '../../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsSenderInfoCtrl', ($rootScope, $scope, $state, $log, rmapsprincipal, rmapsGeoLocations, rmapsMailTemplate) ->
  $scope.us_states = []

  # $log.debug "\n\n#### parent templateObj:"
  # # $log.debug $scope.$parent.templateObj
  # $log.debug $scope.$parent.superTemplateObj

  # $log.debug "(senderInfo) rmapsMailTemplate.getLobSenderData:"
  # $log.debug rmapsMailTemplate.getLobSenderData()

  $scope.templObj = rmapsMailTemplate

  $rootScope.registerScopeData () ->
    rmapsMailTemplate.procureSenderData()
    .then (senderData) ->
      $scope.templObj.senderData = senderData
      rmapsGeoLocations.states().then (states) ->
        $scope.us_states = states

    # rmapsprincipal.getIdentity().then (identity) ->
    #   $log.debug "\n\n#### identity:"
    #   $log.debug identity


