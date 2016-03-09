app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsMailCtrl', ($rootScope, $scope, $state, $log, rmapsPrincipalService, rmapsMailCampaignService) ->
  $log = $log.spawn 'mail:mailCampaigns'
  $log.debug 'rmapsMailCtrl'
  $scope.mailCampaigns = []

  $scope.searchName = ''

  $scope.loadMailCampaigns = () ->
    $log.debug 'getting campaign list'
    query = {
      # If we decide to restrict list to current project, uncomment this line
      # project_id: rmapsPrincipalService.getCurrentProjectId()
    }
    rmapsMailCampaignService.get query
    .then (list) ->
      $scope.mailCampaigns = list

  $scope.deleteCampaign = (campaign) ->
    rmapsMailCampaignService.remove campaign.id
    .then () ->
      _.remove $scope.mailCampaigns, 'id', campaign.id

  $scope.statusNames =
    'ready': 'draft'
    'sending': 'pending'
    'paid': 'sent'

  $scope.loadMailCampaigns()
