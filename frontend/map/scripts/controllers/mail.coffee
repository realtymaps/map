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
      rmapsMailCampaignService.get auth_user_id: identity.id
      .then (list) ->
        $scope.mailCampaigns = list

  $scope.deleteCampaign = (campaign) ->
    rmapsMailCampaignService.remove campaign.id
    .then () ->
      _.remove $scope.mailCampaigns, 'id', campaign.id

  $rootScope.registerScopeData () ->
    $scope.loadMailCampaigns()
