app = require '../../app.coffee'

module.exports = app

app.controller 'rmapsRecipientInfoCtrl', ($rootScope, $modal, $scope, $log, $state, rmapsPropertiesService) ->
  $log = $log.spawn 'mail:recipientInfo'
  $log.debug 'rmapsRecipientInfoCtrl'

  $scope.property = []
  $scope.owner = []
  $scope.propertyAndOwner = []

  $scope.changeRecipients = () ->
    $scope.wizard.mail.campaign.recipients = $scope[$scope.wizard.mail.campaign.recipientType]

  $scope.showAddresses = (addresses) ->
    $scope.addressList = addresses
    modalInstance = $modal.open
      template: require('../../../html/views/templates/modals/addressList.jade')()
      windowClass: 'address-list-modal'
      scope: $scope

    $scope.close = modalInstance.dismiss

  if !$scope.wizard.mail.campaign.recipients?.length

    $scope.property_ids = $state.params.property_ids

    if !$scope.property_ids?.length
      $state.go 'mail'

    else
      rmapsPropertiesService.getProperties $scope.property_ids, 'filter'
      .then ({data}) ->

        hash = (a) ->
          "#{a.street_address_num} #{a.street_address_name} #{a.street_address_unit} #{a.city} #{a.state} #{a.zip}".trim()

        property = {}
        owner = {}
        for addr in data
          pAddr =
            name: addr.owner_name ?  addr.owner_name_2 ? 'Current Resident'
            street_address_num: addr.street_address_num ? ''
            street_address_name: addr.street_address_name ? ''
            street_address_unit: addr.owner_street_address_unit ? ''
            city: addr.city ? ''
            state: addr.state ? ''
            zip: addr.zip ? ''
            rm_property_id: addr.rm_property_id
            type: 'property'

          if pKey = hash(pAddr)
            $log.debug "Adding #{pAddr.name}'s address: #{pKey}"
            property[pKey] = pAddr

          oAddr =
            name: addr.owner_name ? addr.owner_name_2 ? 'Homeowner'
            street_address_num: addr.owner_street_address_num ? ''
            street_address_name: addr.owner_street_address_name ? ''
            street_address_unit: addr.owner_street_address_unit ? ''
            city: addr.owner_city ? ''
            state: addr.owner_state ? ''
            zip: addr.owner_zip ? ''
            rm_property_id: addr.rm_property_id
            type: 'owner'

          if oKey = hash(oAddr)
            $log.debug "Adding #{oAddr.name}'s address: #{oKey}"
            owner[oKey] = oAddr

        $scope.propertyAndOwner = _.values _.defaults {}, property, owner
        $scope.property = _.values property
        $scope.owner = _.values owner
