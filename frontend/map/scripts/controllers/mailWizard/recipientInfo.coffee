app = require '../../app.coffee'

module.exports = app

app.controller 'rmapsRecipientInfoCtrl', ($scope, $log, rmapsPropertiesService, rmapsMailTemplate) ->
  $log = $log.spawn 'frontend:map:recipientInfo'
  $log.debug 'rmapsRecipientInfoCtrl'
  $scope.mailCampaign = rmapsMailTemplate.getCampaign()

  $scope.property = []
  $scope.owner = []
  $scope.propertyAndOwner = []

  if not $scope.mailCampaign.recipients?.length and $scope.mailCampaign.property_ids?.length
    rmapsPropertiesService.getProperties $scope.mailCampaign.property_ids, 'filter'
    .then ({data}) ->
      for detail, i in data
        data[i] = detail = _.omit detail, _.isEmpty
        p = "#{detail.street_address_num} #{detail.street_address_name} #{detail.street_address_unit} #{detail.city} #{detail.state} #{detail.zip}"
        o = "#{detail.owner_street_address_num} #{detail.owner_street_address_name} #{detail.owner_street_address_unit} #{detail.owner_city} #{detail.owner_state} #{detail.owner_zip}"
        detail.property_address = p.trim()
        detail.owner_address = o.trim()

      $scope.property = _.indexBy data, 'property_address'
      $scope.owner = _.indexBy data, 'owner_address'
      $scope.propertyAndOwner = _.values _.defaults $scope.property, $scope.owner
      $scope.property = _.values $scope.property
      $scope.owner = _.values $scope.owner

  $scope.changeRecipients = () ->
    rmapsMailTemplate.setRecipients $scope[$scope.mailCampaign.recipientType]
