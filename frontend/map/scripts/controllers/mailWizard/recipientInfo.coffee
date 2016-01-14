app = require '../../app.coffee'

module.exports = app

app.controller 'rmapsRecipientInfoCtrl', ($rootScope, $scope, $state, $log, rmapsPropertiesService) ->
  $log = $log.spawn 'mail:recipient'

  $scope.property = []
  $scope.owner = []
  $scope.propertyAndOwner = []

  if $scope.property_ids?.length
    rmapsPropertiesService.getProperties $scope.property_ids, 'filter'
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
    $scope.mailCampaign.recipients = $scope[$scope.recipientType]
