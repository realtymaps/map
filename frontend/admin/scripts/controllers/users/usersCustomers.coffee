app = require '../../app.coffee'
_ = require 'lodash'
gridCellView = require '../../../../common/html/views/templates/gridCellView.jade'
gridButton = require '../../../../common/html/views/templates/gridButton.jade'

app.controller 'rmapsUsersCustomersCtrl', (
$scope, $rootScope, $injector, $q, Restangular,
rmapsUsersService,
rmapsGridFactory,
rmapsUsStates,
rmapsAccountUseTypesService,
rmapsCompanyService,
uiGridConstants) ->

  $scope.getData = rmapsUsersService.get

  $scope.gridName = 'Customers'

  ###
  complicated cells:
  FK Cells:
    - stripe_id -> go stripe console to edit settings there?

  Permissions:
   - many to many table of users to perms
   - Will need a modified version of 'ui-grid/dropdownEditor' to allow multi selection

  MLS Permissions: (same as permissions)
   - fips_codes - combination with following tables:
     - auth_m2m_user_locations (mod) in relation to
     - lookup_fips_codes
   - mlses_verified - combination with following tables:
     - auth_m2m_user_mls (mod) in relation to
     - lookup_mls

   editDropdownOptionsArray:[] for fk relations

  ###

  new rmapsGridFactory $scope,
    filters: {}
    enableFiltering: true
    columnDefs: [
        field: 'email'
        displayName: 'Email'
        width: 175
        enableCellEdit: false
        pinnedLeft: true
      ,
        field: '_del'
        displayName: 'Delete'
        width: 65
        enableCellEdit: false
        pinnedLeft: true
        cellTemplate: gridButton(
          content: "Delete"
          clz: "btn btn-danger btn-xs"
          click: "col.colDef.remove(row.entity)"
        )
        remove: (entity) ->
          entity.remove()
          .then ->
            $scope.load()
      ,
        field: 'parent_id'
        displayName: 'Parent'
        type: 'number'
        width: 124
        sort:
          direction: uiGridConstants.ASC
        cellClass: 'clickable-cell'
        editableCellTemplate: 'ui-grid/dropdownEditor'
        editDropdownValueLabel: 'email'
        cellTemplate: gridCellView(id: 'row.entity.parent_id')
      ,
        field: 'is_superuser'
        displayName: 'SU'
        width: 75
        type: 'boolean'
        defaultValue: false
        sort:
          direction: uiGridConstants.ASC
        cellClass: 'clickable-cell'
      ,
        field: 'is_staff'
        displayName: 'Staff'
        width: 75
        type: 'boolean'
        defaultValue: false
        sort:
          direction: uiGridConstants.ASC
        cellClass: 'clickable-cell'
      ,
        field: 'is_active'
        displayName: 'Active'
        width: 75
        type: 'boolean'
        defaultValue: false
        sort:
          direction: uiGridConstants.ASC
        cellClass: 'clickable-cell'
      ,
        field: 'mlses_verified'
        cellEditableCondition: false
        displayName: 'Approved MLSes'
        width: 125
        defaultValue: false
        sort:
          direction: uiGridConstants.ASC
        cellClass: 'clickable-cell'
      ,
        field: 'account_use_type_id'
        displayName: 'Account use'
        type: 'number'
        width: 124
        sort:
          direction: uiGridConstants.ASC
        cellClass: 'clickable-cell'
        editableCellTemplate: 'ui-grid/dropdownEditor'
        editDropdownValueLabel: 'type'
        cellTemplate: gridCellView(id: 'row.entity.account_use_type_id')
      ,
        field: 'first_name'
        displayName: 'First'
        type: 'string'
        width: 75
        sort:
          direction: uiGridConstants.ASC
        cellClass: 'clickable-cell'
      ,
        field: 'last_name'
        displayName: 'Last'
        type: 'string'
        width: 75
        sort:
          direction: uiGridConstants.ASC
        cellClass: 'clickable-cell'
      ,
        field: 'address_1'
        displayName: 'address 1'
        type: 'string'
        width: 75
        sort:
          direction: uiGridConstants.ASC
        cellClass: 'clickable-cell'
      ,
        field: 'address_2'
        displayName: 'address 2'
        type: 'string'
        width: 75
        sort:
          direction: uiGridConstants.ASC
        cellClass: 'clickable-cell'
      ,
        field: 'city'
        displayName: 'city'
        type: 'string'
        width: 75
        sort:
          direction: uiGridConstants.ASC
        cellClass: 'clickable-cell'
      ,
        field: 'us_state_id'
        displayName: 'state'
        type: 'number'
        width: 124
        cellClass: 'clickable-cell'
        editableCellTemplate: 'ui-grid/dropdownEditor'
        editDropdownOptionsArray: rmapsUsStates.all
        editDropdownValueLabel: 'name'
        getCellView: (id) ->
          rmapsUsStates.getById(id)?.name
        cellTemplate: gridCellView(id: 'row.entity.us_state_id')
      ,
        field: 'zip'
        displayName: 'zip'
        type: 'string'
        width: 75
        sort:
          direction: uiGridConstants.ASC
        cellClass: 'clickable-cell'
      ,
        field: 'website_url'
        displayName: 'website'
        type: 'string'
        width: 75
        sort:
          direction: uiGridConstants.ASC
        cellClass: 'clickable-cell'
      ,
        field: 'company_id'
        displayName: 'Company'
        type: 'number'
        width: 124
        sort:
          direction: uiGridConstants.ASC
        cellClass: 'clickable-cell'
        editableCellTemplate: 'ui-grid/dropdownEditor'
        editDropdownValueLabel: 'name'
        cellTemplate: gridCellView(id: 'row.entity.company_id')
    ]


  columnDefsHash = _.indexBy $scope.grid.columnDefs, 'field'

  $q.all({
    accountUseTypes: rmapsAccountUseTypesService.get()
    companies: rmapsCompanyService.get()
    parents: $scope.getData()
  }).then (promises) ->

    hashes = _.mapValues promises, (v) ->
      _.indexBy v, 'id'

    columnDefsHash.account_use_type_id.editDropdownOptionsArray = promises.accountUseTypes
    columnDefsHash.account_use_type_id.getCellView = (id) ->
      return if !id?
      hashes.accountUseTypes[id]?.type

    columnDefsHash.company_id.editDropdownOptionsArray = promises.companies
    columnDefsHash.company_id.getCellView = (id) ->
      return if !id?
      hashes.companies[id]?.name

    columnDefsHash.parent_id.editDropdownOptionsArray = promises.parents
    columnDefsHash.parent_id.getCellView = (id) ->
      return if !id?
      hashes.parents[id]?.email
