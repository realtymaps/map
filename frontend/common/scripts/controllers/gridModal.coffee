mod = require '../module.coffee'
_ = require 'lodash'


mod.factory 'rmapsGridModalFactory', ($log) ->
  ->
    [ '$scope', '$uibModalInstance', 'columnDefs', 'record', 'gridName', 'fieldTypeMap',
      ($scope, $uibModalInstance, columnDefs, record, gridName, fieldTypeMap) ->
        $scope.gridName = gridName
        $scope.record = record
        $scope.fieldTypeMap = fieldTypeMap

        _.each columnDefs, (c) ->
          if (v = c.defaultValue)?
            $scope.record[c.name] = if _.isFunction v then v() else v

        $scope.ok = () ->
          $uibModalInstance.close($scope.record)

        $scope.cancel = () ->
          $uibModalInstance.dismiss('cancel')
  ]
