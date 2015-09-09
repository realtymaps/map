_ = require 'lodash'
mod = require '../module.coffee'
createTemplate = require('../../../common/html/views/templates/gridCreateModal.jade')()

mod.factory 'rmapsGridFactory', ($log, $rootScope, $modal, Restangular, rmapsGridModal) ->
  ($scope) ->
    $scope.gridName = $scope.gridName or 'Grid'

    $scope.gridName = $scope.gridName[0].toUpperCase() + $scope.gridName.slice(1)

    $scope.grid =
      enableColumnMenus: false
      enablePinning: true
      columnDefs: $scope.columnDefs
      onRegisterApi: (gridApi) ->
        gridApi.edit.on.afterCellEdit $scope, (rowEntity, colDef, newValue, oldValue) ->
          if newValue != oldValue
            $scope.$apply()
            rowEntity.save()

    $scope.exists = () ->
      idx = _.findIndex $scope.grid.data, name: $scope.recordName
      $scope.nameExists = idx != -1

    $log.log "#### controller, columnDefs:"
    $log.log $scope.columnDefs

    $scope.create = () ->
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

        controller: rmapsGridModal()

      modalInstance.result
      .then (record) ->
        for k, v of record
          if $scope.fieldTypeMap[k] == 'object'
            record[k] = JSON.parse(v)
        $log.log "#### modal result, created record:"
        $log.log record

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

    $scope.delete = () ->
      idx = _.findIndex $scope.grid.data, name: $scope.recordName
      if idx > -1
        $scope.jobsBusy = $scope.grid.data[idx].remove()
        .then () ->
          $scope.grid.data.splice(idx, 1)
          $scope.exists()

    $scope.load = () ->
      $scope.jobsBusy = $scope.getData()
      .then (data) ->
        $scope.grid.data = data

    $rootScope.registerScopeData () ->
      $scope.load()
      $scope.fieldTypeMap = {}
      for c in $scope.columnDefs
        $scope.fieldTypeMap[c.name] = c.type
