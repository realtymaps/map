_ = require 'lodash'

module.exports = ($scope, $rootScope, Restangular) ->

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

  $scope.create = () ->
    if !$scope.recordName
      return

    record = name: $scope.recordName
    _.each @columnDefs, (c) ->
      if (v = c.defaultValue)?
        record[c.name] = if _.isFunction v then v() else v

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
