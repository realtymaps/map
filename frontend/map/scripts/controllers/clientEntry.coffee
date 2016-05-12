app = require '../app.coffee'

module.exports = app.controller 'rmapsClientEntryCtrl', ($scope, $log, $state, rmapsClientEntryService) ->
  $log = $log.spawn 'rmapsClientEntryCtrl'
  console.log "rmapsClientEntryCtrl()"
  console.log "params:\n#{JSON.stringify($state.params,null,2)}"

  rmapsClientEntryService.getClientEntry $state.params.key
  .then (data) ->
    console.log "rmapsClientEntryCtrl service call,  getClientEntry:\n#{JSON.stringify(data,null,2)}"
    $scope.client = data.client
    $scope.parent = data.parent
    $scope.project = data.project
  .catch (err) ->
    console.log "err:\n#{JSON.stringify(err,null,2)}"

