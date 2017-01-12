app = require '../../app.coffee'
_ = require 'lodash'
gridCellView =    require '../../../../common/html/views/templates/gridCellView.jade'
gridButton =      require '../../../../common/html/views/templates/gridButton.jade'
gridMultiSelect = require '../../../../common/html/views/templates/gridMultiSelect.jade'


app.controller 'rmapsUsersHistoryCtrl', (
$q, $uibModal, Restangular,
rmapsUsersService,
rmapsGridFactory,
rmapsUserHistoryService,
uiGridConstants
$scope) ->

  $scope.getData = rmapsUserHistoryService.get

  $scope.gridName = 'User History'

  mulit = {
    categories: []
    subcategories: []
  }


  $q.all({
    categories: []
    subcategories: []
  }).then (resolves) ->

    hashes = _.mapValues resolves, (v) ->
      _.indexBy v, 'id'

    mulit.categories = resolves.categories
    mulit.subcategories = resolves.subcategories

    new rmapsGridFactory $scope,
      filters: {}
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
            if window.confirm("Do you really want to delete this history row? It is permenant!")
              entity.remove()
              .then ->
                $scope.load()
        ,

          field: "category_id"
          displayName: 'Categories'
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
            # rmapsUserPermissionsService.save(entity, newValue, oldValue)?.catch () ->
            #   $scope.load()
            # return false
        field: "subcategory_id"
        displayName: 'Sub Categories'
        width: 170
        cellClass: 'clickable-cell'
        editDropdownOptionsArray: mulit.permissions
        editDropdownValueLabel: 'name'
        cellTemplate: gridCellView(contents: "{{ col.colDef.getCellView(COL_FIELD)}}",clz: "many-fields")
        getCellView: (permissions) ->
          permissions?.map (p) -> p.codename
          .join(', ')
        editableCellTemplate: gridMultiSelect({match: '$item.codename' ,item: 'item.codename', clz: "many-fields-edit large-input"})
        # handleCustomSave: (entity, newValue, oldValue) ->
          # rmapsUserPermissionsService.save(entity, newValue, oldValue)?.catch () ->
          #   $scope.load()
          # return false
        ,
          field: "description"
          displayName: 'Description'
          width: 200
          cellClass: 'clickable-cell'
          type:'string'

      ]

    columnDefsHash = _.indexBy $scope.grid.columnDefs, 'field'
    columnDefsHash.category_id.editDropdownOptionsArray = resolves.categories
    columnDefsHash.category_id.getCellView = (id) ->
      return if !id?
      hashes.categories[id]?.type

    columnDefsHash = _.indexBy $scope.grid.columnDefs, 'field'
    columnDefsHash.subcategory_id.editDropdownOptionsArray = resolves.subcategories
    columnDefsHash.subcategory_id.getCellView = (id) ->
      return if !id?
      hashes.subcategories[id]?.type


    $scope.ready = true
