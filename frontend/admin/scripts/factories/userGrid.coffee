app = require '../app.coffee'
_ = require 'lodash'
gridCellView =    require '../../../common/html/views/templates/gridCellView.jade'
gridButton =      require '../../../common/html/views/templates/gridButton.jade'
gridMultiSelect = require '../../../common/html/views/templates/gridMultiSelect.jade'
loginTokenView =  require '../../html/includes/loginToken.jade'


app.factory 'rmapsUsersGridFactory', (
$q, $uibModal, Restangular,
rmapsUsersService,
rmapsGridFactory,
rmapsUsStates,
rmapsAccountUseTypesService,
rmapsCompanyService,
rmapsPermissionsService,
rmapsUserPermissionsService,
rmapsGroupsService,
rmapsUserGroupsService,
uiGridConstants) ->
  ($scope, filter = {}) ->

    $scope.getData = rmapsUsersService.get

    $scope.gridName = 'Customers'


    ###
    TODO: Handle later
    MLS Permissions: (same as permissions)
     - fips_codes - combination with following tables:
       - auth_m2m_user_locations (mod) in relation to
       - lookup_fips_codes
     - mlses_verified - combination with following tables:
       - auth_m2m_user_mls (mod) in relation to
       - lookup_mls

    ###

    mulit = {
      permissions: []
      mlses: []
      fipsCodes: []
    }


    $q.all({
      accountUseTypes: rmapsAccountUseTypesService.get()
      companies: rmapsCompanyService.get()
      parents: $scope.getData()
      permissions: rmapsPermissionsService.get()
      groups: rmapsGroupsService.get()
    }).then (resolves) ->

      hashes = _.mapValues resolves, (v) ->
        _.indexBy v, 'id'

      mulit.permissions = resolves.permissions
      mulit.groups = resolves.groups

      new rmapsGridFactory $scope,
        filters: filter
        enableFiltering: true
        paginationPageSizes: [10, 25, 50, 75],
        paginationPageSize: 25,
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
              if window.confirm("Do you really want to delete this user? It is permenant!")
                entity.remove()
                .then ->
                  $scope.load()
          ,
            field: '_spoof'
            displayName: 'Login'
            width: 75
            enableCellEdit: false
            pinnedLeft: true
            cellTemplate: gridButton(
              content: "Login As"
              clz: "btn btn-primary btn-xs"
              click: "col.colDef.loginTokenModal(row.entity)"
            )
            loginTokenModal: (entity) ->
              $uibModal.open
                template: loginTokenView()
                size: 'lg'
                controller: 'rmapsLoginTokenCtrl'
                resolve: user: () -> entity
          ,
            field: "permissions"
            displayName: 'Permissions'
            width: 170
            cellClass: 'clickable-cell'
            editDropdownOptionsArray: mulit.permissions
            editDropdownValueLabel: 'name'
            cellTemplate: gridCellView(contents: "{{ col.colDef.getCellView(COL_FIELD)}}",clz: "many-fields")
            getCellView: (permissions) ->
              permissions?.map (p) -> p.codename
              .join(', ')
            editableCellTemplate: gridMultiSelect({match: '$item.codename' ,item: 'item.codename', clz: "many-fields-edit large-input"})
            handleCustomSave: (entity, newValue, oldValue) ->
              rmapsUserPermissionsService.save(entity, newValue, oldValue)?.catch () ->
                $scope.load()
              return false
          ,
            field: "stripe_customer_id"
            displayName: 'Stripe Customer'
            width: 142
            cellClass: 'clickable-cell'
            cellTemplate: "<div class='.ui-grid-cell-contents'><a href='https://dashboard.stripe.com/test/customers/{{COL_FIELD}}'>{{COL_FIELD}}</a></div>"
          ,
          # NOTE: this is commented out as groups is possibly not used anymore
          #   field: "groups"
          #   displayName: 'Groups'
          #   width: 124
          #   cellClass: 'clickable-cell'
          #   editDropdownOptionsArray: mulit.groups
          #   editDropdownValueLabel: 'name'
          #   cellTemplate: gridCellView(contents: "{{ col.colDef.getCellView(COL_FIELD)}}", clz: "many-fields")
          #   getCellView: (many) ->
          #     many?.map (p) -> p.name
          #     .join(', ')
          #   editableCellTemplate: gridMultiSelect({match: '$item.name' ,item: 'item.name', clz: "many-fields-edit large-input"})
          #   handleCustomSave: (entity, newValue, oldValue) ->
          #     rmapsUserGroupsService.save(entity, newValue, oldValue)?.catch () ->
          #       $scope.load()
          #     return false
          # ,
            field: 'parent_id'
            displayName: 'Parent'
            type: 'number'
            width: 124
            sort:
              direction: uiGridConstants.ASC
            cellClass: 'clickable-cell'
            editableCellTemplate: 'ui-grid/dropdownEditor'
            editDropdownValueLabel: 'email'
            cellTemplate: gridCellView(contents: "{{col.colDef.getCellView(COL_FIELD)}}")
          ,
            field: 'cell_phone'
            displayName: 'Cell Phone'
            width: 120
            type: 'string'
            sort:
              direction: uiGridConstants.ASC
            cellClass: 'clickable-cell'
            cellTemplate: "<div class='.ui-grid-cell-contents'><a href='tel:{{COL_FIELD}}'>{{COL_FIELD}}</a></div>"
          ,
            field: 'work_phone'
            displayName: 'Work Phone'
            width: 120
            type: 'string'
            sort:
              direction: uiGridConstants.ASC
            cellClass: 'clickable-cell'
            cellTemplate: "<div class='.ui-grid-cell-contents'><a href='tel:{{COL_FIELD}}'>{{COL_FIELD}}</a></div>"
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
            cellTemplate: gridCellView(contents: "{{col.colDef.getCellView(COL_FIELD)}}")
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
            cellTemplate: gridCellView(contents: "{{col.colDef.getCellView(COL_FIELD)}}")
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
            cellTemplate: gridCellView(contents: "{{col.colDef.getCellView(COL_FIELD)}}")
        ]

      columnDefsHash = _.indexBy $scope.grid.columnDefs, 'field'
      columnDefsHash.account_use_type_id.editDropdownOptionsArray = resolves.accountUseTypes
      columnDefsHash.account_use_type_id.getCellView = (id) ->
        return if !id?
        hashes.accountUseTypes[id]?.type

      columnDefsHash.company_id.editDropdownOptionsArray = resolves.companies
      columnDefsHash.company_id.getCellView = (id) ->
        return if !id?
        hashes.companies[id]?.name

      columnDefsHash.parent_id.editDropdownOptionsArray = resolves.parents
      columnDefsHash.parent_id.getCellView = (id) ->
        return if !id?
        hashes.parents[id]?.email

      $scope.ready = true
