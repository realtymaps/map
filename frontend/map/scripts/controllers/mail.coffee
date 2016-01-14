app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsMailCtrl', ($rootScope, $scope, $state, $log, rmapsprincipal, rmapsMailCampaignService) ->
  $log = $log.spawn 'map:mailCampaigns'
  $log.debug 'rmapsMailCtrl'
  $scope.mailCampaigns = []

  $scope.searchName = ''

  $scope.loadMailCampaigns = () ->
    rmapsprincipal.getIdentity()
    .then (identity) ->
      $log.debug 'getting campaign list'
      rmapsMailCampaignService.getList auth_user_id: identity.id
      .then (list) ->
        $scope.mailCampaigns = list

  $rootScope.registerScopeData () ->
    $scope.loadMailCampaigns()
