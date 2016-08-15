app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsMailCtrl', ($rootScope, $scope, $state, $log, rmapsPrincipalService,
rmapsMailCampaignService, rmapsMainOptions, rmapsMailTemplateTypeService) ->
  $log = $log.spawn 'mail:mailCampaigns'
  $log.debug 'rmapsMailCtrl'
  $scope.mailCampaigns = []

  $scope.searchName = ''

  $scope.sortField = 'rm_inserted_time'
  $scope.sortReverse = true

  $scope.loadMailCampaigns = () ->
    $log.debug 'getting campaign list'
    query = {
      # If we decide to restrict list to current project, uncomment this line
      # project_id: rmapsPrincipalService.getCurrentProjectId()
    }
    rmapsMailCampaignService.get query
    .then (list) ->
      $scope.mailCampaigns = list
      templateTypeMap = rmapsMailTemplateTypeService.getMeta()
      angular.forEach list, (el) ->
        if el.stripe_charge?.created?
          el.stripe_charge.created = el.stripe_charge.created * 1000 # js epoch is milliseconds, stripe epoch is seconds
        el.template_name = el.filename || templateTypeMap[el.template_type]?.name || "(none selected)"

  $scope.deleteCampaign = (campaign) ->
    rmapsMailCampaignService.remove campaign.id
    .then () ->
      _.remove $scope.mailCampaigns, 'id', campaign.id

  $scope.statusNames = rmapsMainOptions.mail.statusNames

  $scope.loadMailCampaigns()
