_ = require 'lodash'
mod = require '../module.coffee'
createTemplate = require('../../../common/html/views/templates/gridCreateModal.jade')()

mod.factory 'rmapsGridFactory', ($log, $rootScope, $modal, Restangular, rmapsGridModalFactory) ->
  ($scope) ->
    $scope.nameFilters = ""

    $scope.gridName = $scope.gridName or 'Grid'

    $scope.gridName = $scope.gridName[0].toUpperCase() + $scope.gridName.slice(1)

    $scope.grid =
      enableColumnMenus: false
      enablePinning: true
      columnDefs: $scope.columnDefs
      enableCellEditOnFocus: true
      onRegisterApi: (gridApi) ->
        gridApi.edit.on.afterCellEdit $scope, (rowEntity, colDef, newValue, oldValue) ->
          if newValue != oldValue
            $scope.$apply()
            rowEntity.save()
          # CellEditOnFocus selects cells as part of focusing, so clear focus after edit since we dont care for the selection to remain
          gridApi.grid.cellNav.clearFocus()

    $scope.exists = () ->
      idx = _.findIndex $scope.grid.data, name: $scope.recordName
      $scope.nameExists = idx != -1

    $scope.create = () ->
      $scope.refreshFieldTypes()
      if !$scope.recordName
        return

      modalInstance = $modal.open
        animation: $scope.modalAnimationsEnabled
        template: createTemplate
        resolve:
          columnDefs: () ->
            return $scope.columnDefs
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

    $scope.load = () ->
      $scope.jobsBusy = $scope.getData({"search": $scope.nameFilters})
      .then (data) ->
        $scope.grid.data = data

    $scope.refreshFieldTypes = () ->
      $scope.fieldTypeMap = {}
      for c in $scope.columnDefs
        $scope.fieldTypeMap[c.name] = c.type

    $rootScope.registerScopeData () ->
      $scope.load()
      $scope.refreshFieldTypes()

