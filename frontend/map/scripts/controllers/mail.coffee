app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsMailCtrl', ($rootScope, $scope, $state, $log, rmapsPrincipalService, rmapsMailCampaignService) ->
  $log = $log.spawn 'mail:mailCampaigns'
  $log.debug 'rmapsMailCtrl'
  $scope.mailCampaigns = []

  $scope.searchName = ''

  $scope.loadMailCampaigns = () ->
    rmapsPrincipalService.getIdentity()
    .then (identity) ->
      $log.debug 'getting campaign list'
      rmapsMailCampaignService.get auth_user_id: identity.id
      .then (list) ->
        $scope.mailCampaigns = list

  $scope.deleteCampaign = (campaign) ->
    rmapsMailCampaignService.remove campaign.id
    .then () ->
      _.remove $scope.mailCampaigns, 'id', campaign.id

  $rootScope.registerScopeData () ->
    $scope.loadMailCampaigns()
