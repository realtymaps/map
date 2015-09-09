mod = require '../module.coffee'
mod.factory 'rmapsGridModal', ($log) ->
  ->
    [ '$scope', '$modalInstance', 'columnDefs', 'record', 'gridName', 'fieldTypeMap',
      ($scope, $modalInstance, columnDefs, record, gridName, fieldTypeMap) ->
        $log.log '#### columnDefs:'
        $log.log columnDefs
        $log.log "#### fieldTypeMap:"
        $log.log fieldTypeMap

        $scope.gridName = gridName
        $scope.record = record
        $scope.fieldTypeMap = fieldTypeMap

        _.each columnDefs, (c) ->
          if (v = c.defaultValue)?
            $scope.record[c.name] = if _.isFunction v then v() else v

        $log.log "#### record:"
        $log.log $scope.record

        $scope.ok = () ->
          $modalInstance.close($scope.record)

        $scope.cancel = () ->
          $modalInstance.dismiss('cancel')
  ]
