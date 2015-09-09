app = require '../app.coffee'

app.controller 'rmapsJobsTaskCtrl', ($scope, $rootScope, $injector, Restangular, rmapsJobsService, rmapsGridFactory) ->

  $scope.getData = rmapsJobsService.getTasks

  $scope.runTask = rmapsJobsService.runTask

  $scope.cancelTask = rmapsJobsService.cancelTask

  $scope.gridName = 'Task'

  $scope.columnDefs = [
      field: 'name'
      displayName: 'Name'
      cellTemplate: '<div class="ui-grid-cell-contents"><a ui-sref="jobsHistory({ task: \'{{COL_FIELD}}\' })">{{COL_FIELD}}</a></div>'
      width: 100
      enableCellEdit: false
      pinnedLeft: true
    ,
      field: 'description'
      displayName: 'Description'
      defaultValue: ''
      width: 300
    ,
      field: 'data'
      displayName: 'Data'
      type: 'object'
      enableCellEdit: true
      editableCellTemplate: require '../../html/views/templates/jsonInput.jade'
      defaultValue: "{}"
      width: 250
    ,
      field: 'ignore_until'
      displayName: 'Ignore Until'
      type: 'date'
      width: 125
      cellFilter: 'date:"MM/dd/yy HH:mm"'
    ,
      field: 'repeat_period_minutes'
      displayName: 'Repeat min'
      type: 'number'
      defaultValue: 60
      width: 125
    ,
      field: 'warn_timeout_minutes'
      displayName: 'Warn TO min'
      type: 'number'
      defaultValue: 5
      width: 125
    ,
      field: 'kill_timeout_minutes'
      displayName: 'Kill TO min'
      type: 'number'
      defaultValue: 5
      width: 125
    ,
      field: 'active'
      displayName: 'Active?'
      type: 'boolean'
      defaultValue: false
      width: 100
    ,
      field: '_run'
      displayName: 'Run'
      enableCellEdit: false
      cellTemplate: '<div class="ui-grid-cell-contents"><a href="#" ng-click="grid.appScope.runTask(row.entity)">RUN</a></div>'
      width: 100
    ,
      field: '_cancel'
      displayName: 'Cancel'
      enableCellEdit: false
      cellTemplate: '<div class="ui-grid-cell-contents"><a href="#" ng-click="grid.appScope.cancelTask(row.entity)">CANCEL</a></div>'
      width: 100
  ]

  new rmapsGridFactory($scope)
