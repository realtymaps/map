_ = require 'lodash'
mod = require '../module.coffee'
createTemplate = require('../../../common/html/views/templates/gridCreateModal.jade')()

mod.factory 'rmapsGridFactory', ($log, $rootScope, $uibModal, Restangular, rmapsGridModalFactory) ->
  ($scope, opts = {}) ->
    $scope.nameFilters = ""

    $scope.gridName = $scope.gridName or 'Grid'

    $scope.gridName = $scope.gridName[0].toUpperCase() + $scope.gridName.slice(1)

    _gridApi = null

    ###
      Private: Area to handle different custom fields

      Returns boolean
    ###
    handleCustomColDefFields = (rowEntity, colDef, newValue, oldValue) ->
      okToSave = true

      #note if this a number col use type:number instead as it handles nulls correctly
      if colDef.handleEmptyString && newValue == ''
        if _.isFunction(colDef.handleEmptyString)
          return okToSave = colDef.handleEmptyString(rowEntity, newValue, oldValue)
        rowEntity.value = null

      if colDef.handleNull && !newValue?
        if _.isFunction(colDef.handleNull)
          return okToSave = colDef.handleNull(rowEntity, newValue, oldValue)
        window.alert("#{colDef.displayName} cannot be undefined.")
        #revert
        rowEntity[colDef.field] = oldValue || colDef.defaultValue?() || colDef.defaultValue
        okToSave = false

      okToSave

    $scope.grid = _.extend
      enableColumnMenus: false
      enablePinning: true
      enableCellEditOnFocus: true
      getGridApi: () -> _gridApi
      onRegisterApi: (gridApi) ->
        _gridApi = gridApi
        gridApi.edit.on.afterCellEdit $scope, (rowEntity, colDef, newValue, oldValue) ->
          okToSave = handleCustomColDefFields(rowEntity, colDef, newValue) #GTFO possibly
          if !okToSave
            return
          if newValue != oldValue
            $scope.$apply()
            rowEntity.save()
          # CellEditOnFocus selects cells as part of focusing, so clear focus after edit since we dont care for the selection to remain
          gridApi.grid.cellNav.clearFocus()
    , opts

    $scope.exists = () ->
      idx = _.findIndex $scope.grid.data, name: $scope.recordName
      $scope.nameExists = idx != -1

    $scope.create = () ->
      $scope.refreshFieldTypes()
      if !$scope.recordName
        return

      modalInstance = $uibModal.open
        animation: $scope.modalAnimationsEnabled
        template: createTemplate
        resolve:
          columnDefs: () ->
            return $scope.grid.columnDefs
          record: () ->
            return name: $scope.recordName
          gridName: () ->
            return $scope.gridName
          fieldTypeMap: () ->
            return $scope.fieldTypeMap

        controller: rmapsGridModalFactory()

      modalInstance.result
      .then (record) ->
        for k, v of record
          if $scope.fieldTypeMap[k] == 'object'
            record[k] = JSON.parse(v)

        $scope.gridBusy = $scope.grid.data.post(record)
        .then () ->
          route = [record.name]
          data = $scope.grid.data
          while data
            route.unshift data.route
            data = data.parentResource

          record = Restangular.restangularizeElement(null, record, route.join('/'))
          record.fromServer = true
          $scope.grid.data.push(record)
          $scope.exists()
          $scope.recordName = ""

    $scope.delete = () ->
      check = confirm "Are you sure you want to delete #{$scope.recordName}?"
      if !check
        return
      idx = _.findIndex $scope.grid.data, name: $scope.recordName
      if idx > -1
        $scope.jobsBusy = $scope.grid.data[idx].remove()
        .then () ->
          $scope.grid.data.splice(idx, 1)
          $scope.exists()
          $scope.recordName = ""

    $scope.load = (filters) ->
      filters ?= opts.filters || {"search": $scope.nameFilters}
      $scope.jobsBusy = $scope.getData(filters)
      .then (data) ->
        $scope.grid.data = data

    $scope.refreshFieldTypes = () ->
      $scope.fieldTypeMap = {}
      for c in $scope.grid.columnDefs
        $scope.fieldTypeMap[c.name] = c.type

    $scope.load()
    $scope.refreshFieldTypes()
