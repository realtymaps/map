app = require '../../app.coffee'

module.exports = app

app.controller 'rmapsRecipientInfoCtrl', ($rootScope, $uibModal, $scope, $log, $state, rmapsPropertiesService) ->
  $log = $log.spawn 'mail:recipientInfo'
  $log.debug 'rmapsRecipientInfoCtrl'

  $scope.property = []
  $scope.owner = []
  $scope.propertyAndOwner = []

  $scope.changeRecipients = () ->
    $scope.wizard.mail.campaign.recipients = $scope[$scope.wizard.mail.campaign.recipientType]

  $scope.showAddresses = (addresses) ->
    $scope.addressList = addresses
    modalInstance = $uibModal.open
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
          "#{a.street ? ''} #{a.unit ? ''} #{a.citystate ? ''} #{a.zip ? ''}".trim().toLowerCase()

        property = {}
        owner = {}
        for p in data
          pAddr = _.assign
            name: (p.owner_name ? p.owner_name_2 ? 'Homeowner')
            rm_property_id: p.rm_property_id
            type: 'property'
          , _.pick(p.address, 'co', 'street', 'unit', 'citystate', 'zip')

          if pKey = hash(pAddr)
            $log.debug "Adding #{pAddr.name}'s address: #{pKey}"
            property[pKey] = pAddr

          oAddr = _.assign
            name: (p.owner_name ?  p.owner_name_2 ? 'Homeowner')
            rm_property_id: p.rm_property_id
            type: 'owner'
          , _.pick(p.owner_address, 'co', 'street', 'unit', 'citystate', 'zip')

          if oKey = hash(oAddr)
            $log.debug "Adding #{oAddr.name}'s address: #{oKey}"
            # Save the property address along with the owner address for mail macros
            oAddr.property = _.pick(p.address, 'co', 'street', 'unit', 'citystate', 'zip')
            owner[oKey] = oAddr

        $scope.propertyAndOwner = _.values _.defaults {}, property, owner
        $scope.property = _.values property
        $scope.owner = _.values owner
