app = require '../app.coffee'
_ = require 'lodash'
require '../services/mlsConfig.coffee'
require '../services/normalize.coffee'
require '../directives/dragdrop.coffee'
require '../directives/listinput.coffee'
require '../factories/validatorBuilder.coffee'

app.controller 'rmapsNormalizeCtrl', [ '$scope', '$state', 'rmapsMlsService', 'rmapsNormalizeService', 'validatorBuilder', ($scope, $state, rmapsMlsService, rmapsNormalizeService, validatorBuilder) ->
  $scope.$state = $state

  $scope.mlsData =
    current: {}

  $scope.fieldData =
    current: {}

  $scope.columns = []

  $scope.transformOptions = [
    { label: 'Uppercase', value: 'forceUpperCase' },
    { label: 'Lowercase', value: 'forceLowerCase' },
    { label: 'Init Caps', value: 'forceInitCaps' }
  ];

  $scope.categories = [
      group: 'hidden'
      label: 'Hiden'
    ,
      group: 'general'
      label: 'General'
    ,
      group: 'details'
      label: 'Details'
    ,
      group: 'listing'
      label: 'Listing'
    ,
      group: 'building'
      label: 'Building'
    ,
      group: 'lot'
      label: 'Lot'
    ,
      group: 'location'
      label: 'Location & Schools'
    ,
      group: 'dimensions'
      label: 'Room Dimensions'
    ,
      group: 'restrictions'
      label: 'Taxes, Fees, and Restrictions'
    ,
      group: 'contacts'
      label: 'Listing Contacts (realtor only)'
    ,
      group: 'realtor'
      label: 'Listing Details (realtor only)'
    ,
      group: 'sale'
      label: 'Sale Details (realtor only)'
  ].map (c) ->
    _.extend c, items: []

  # Load list of MLS
  rmapsMlsService.getConfigs()
  .then (configs) ->
    $scope.mlsConfigs = configs

  # Load saved MLS config and MLS field list
  $scope.selectMls = () ->
    config = $scope.mlsData.current
    rmapsNormalizeService.getRules config.id
    .then (rules) ->
      # todo: place rules into categories here

    rmapsMlsService.getColumnList config.id, config.main_property_data.db, config.main_property_data.table
    .then (columns) ->
      $scope.columns = columns
      # todo: create un-assigned rules for any fields that weren't already configured

  # Show field options
  $scope.selectField = (field) ->
    config = $scope.mlsData.current
    $scope.fieldData.current = field
    field.type = lookupType(field)
    if not field.vOptions
      field.vOptions = {}
    if field.type?.name == 'string' and field.Interpretation.indexOf('Lookup') == 0
      rmapsMlsService.getLookupTypes config.id, config.main_property_data.db, field.SystemName
      .then (lookups) ->
        field.lookups = lookups

  # Move fields between categories
  $scope.onDrop = (drag, drop, target) ->
    _.pull drag.collection, drag.model
    drop.collection.splice _.indexOf(drop.collection, target), 0, drag.model
    $scope.$evalAsync()
    # todo: save

  # Map configuration options to transform JSON
  $scope.getTransform = () ->
    field = $scope.fieldData.current
    if field.DataType
      options =
        vOptions: _.pick field.vOptions, (v) -> v?
        type: lookupType(field)?.name
      field.transform = validatorBuilder(options)
      console.log field
      # todo: save

  lookupType = (field) ->
      types =
        Int:
          name: 'integer'
          label: 'Number'
        Decimal:
          name: 'float'
          label: 'Number'
        Long:
          name: 'float'
          label: 'Number'
        Character:
          name: 'string'
        DateTime:
          name: 'datetime'
          label: 'Date and Time'
        Boolean:
          name: 'boolean'
          label: 'Yes/No'

      type = types[field.DataType]

      if type?.name == 'string'
        if field.Interpretation == 'Lookup'
          type.label = 'Restricted Text (single value)'
        else if field.Interpretation == 'LookupMulti'
          type.label = 'Restricted Text (multiple values)'
        else
          type.label = 'User-Entered Text'

      type

]
