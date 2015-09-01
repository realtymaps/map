_ = require 'lodash'
createTemplate = require('../../../common/html/views/templates/gridCreateModal.jade')()

module.exports = ($scope, $rootScope, $modal, Restangular) ->
  console.log "#### gridController()"
  $scope.modalAnimationsEnabled = true # modal animations
  @gridName = @gridName or 'Grid'

  $scope.gridName = @gridName[0].toUpperCase() + @gridName.slice(1)

  $scope.grid =
    enableColumnMenus: false
    columnDefs: @columnDefs
    onRegisterApi: (gridApi) ->
      gridApi.edit.on.afterCellEdit $scope, (rowEntity, colDef, newValue, oldValue) ->
        if newValue != oldValue
          $scope.$apply()
          rowEntity.save()

  $scope.exists = () ->
    idx = _.findIndex $scope.grid.data, name: $scope.recordName
    $scope.nameExists = idx != -1


  $scope.create = () =>
    if !$scope.recordName
      return

    modalInstance = $modal.open
      animation: $scope.modalAnimationsEnabled
      template: createTemplate
      resolve:
        columnDefs: () =>
          return @columnDefs
        record: () ->
          return name: $scope.recordName
        gridName: () =>
          return @gridName
        fieldTypeMap: () =>
          return @fieldTypeMap

      controller: ['$scope', '$modalInstance', 'columnDefs', 'record', 'gridName', 'fieldTypeMap', ($scope, $modalInstance, columnDefs, record, gridName, fieldTypeMap) ->
        console.log '#### columnDefs:'
        console.log columnDefs
        console.log "#### fieldTypeMap:"
        console.log fieldTypeMap

        $scope.gridName = gridName
        $scope.record = record
        $scope.fieldTypeMap = fieldTypeMap

        _.each columnDefs, (c) ->
          # console.log "#### checking c:"
          # console.log c
          if (v = c.defaultValue)?
            # console.log "#### checking v:"
            # console.log v
            $scope.record[c.name] = if _.isFunction v then v() else v

        console.log "#### record:"
        console.log $scope.record

        $scope.ok = () ->
          $modalInstance.close($scope.record)

        $scope.cancel = () ->
          $modalInstance.dismiss('cancel')

      ]

    modalInstance.result
    .then (record) =>
      for k, v of record
        if @fieldTypeMap[k] == 'object'
          record[k] = JSON.parse(v)
      console.log "#### modal result, created record:"
      console.log record

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

  $rootScope.registerScopeData () =>
    $scope.load()
    @fieldTypeMap = {}
    for c in @columnDefs
      @fieldTypeMap[c.name] = c.type

