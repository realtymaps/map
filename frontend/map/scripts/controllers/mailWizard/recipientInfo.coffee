app = require '../../app.coffee'

module.exports = app

app.controller 'rmapsRecipientInfoCtrl', ($rootScope, $modal, $scope, $log, rmapsPropertiesService, rmapsMailTemplateService) ->
  $log = $log.spawn 'mail:recipientInfo'
  $log.debug 'rmapsRecipientInfoCtrl'
  # $scope.mailCampaign = rmapsMailTemplateService.getCampaign()

  $scope.property = []
  $scope.owner = []
  $scope.propertyAndOwner = []

  $scope.changeRecipients = () ->
    rmapsMailTemplateService.setRecipients $scope[$scope.wizard.mail.campaign.recipientType]

  $scope.showAddresses = (addresses) ->
    $log.debug addresses
    $scope.addressList = addresses
    modalInstance = $modal.open
      template: require('../../../html/views/templates/modals/addressList.jade')()
      windowClass: 'address-list-modal'
      scope: $scope

  $rootScope.registerScopeData () ->
    $scope.ready()
    .then () ->
      # $scope.mailCampaign = campaign

      if not $scope.wizard.mail.campaign.recipients?.length and $scope.wizard.mail.campaign.property_ids?.length
        rmapsPropertiesService.getProperties $scope.wizard.mail.campaign.property_ids, 'filter'
        .then ({data}) ->

          hash = (a) ->
            "#{a.street_address_num} #{a.street_address_name} #{a.street_address_unit} #{a.city} #{a.state} #{a.zip}".trim()

          property = {}
          owner = {}
          for addr in data
            pAddr =
              name: addr.owner_name ?  addr.owner_name2 ? 'Current Resident'
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
              name: addr.owner_name ? addr.owner_name2 ? 'Homeowner'
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
