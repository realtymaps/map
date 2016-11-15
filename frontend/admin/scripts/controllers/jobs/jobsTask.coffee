app = require '../../app.coffee'

app.controller 'rmapsJobsTaskCtrl', ($scope, $rootScope, $injector, Restangular, rmapsJobsService, rmapsGridFactory, uiGridConstants) ->
  $scope.getData = rmapsJobsService.getTasks

  $scope.runTask = rmapsJobsService.runTask

  $scope.cancelTask = rmapsJobsService.cancelTask

  $scope.gridName = 'Task'

  new rmapsGridFactory $scope,
    enableFiltering: true
    columnDefs: [
        field: 'name'
        displayName: 'Name'
        cellTemplate: '<div class="ui-grid-cell-contents"><a ui-sref="jobsHistory({ task: \'{{COL_FIELD}}\' })">{{COL_FIELD}}</a></div>'
        width: 120
        enableCellEdit: false
        pinnedLeft: true
        sort:
          direction: uiGridConstants.ASC
      ,
        field: 'description'
        displayName: 'Description'
        defaultValue: ''
        width: 300
        cellClass: 'clickable-cell'
      ,
        field: 'data'
        displayName: 'Data'
        type: 'object'
        enableCellEdit: true
        editableCellTemplate: require '../../../html/views/templates/jsonInput.jade'
        defaultValue: "{}"
        width: 250
        cellClass: 'clickable-cell'
      ,
        field: 'blocked_by_tasks'
        displayName: 'Blocking Tasks'
        type: 'object'
        enableCellEdit: true
        editableCellTemplate: require '../../../html/views/templates/jsonInput.jade'
        defaultValue: "[]"
        width: 250
        cellClass: 'clickable-cell'
      ,
        field: 'blocked_by_locks'
        displayName: 'Blocking Locks'
        type: 'object'
        enableCellEdit: true
        editableCellTemplate: require '../../../html/views/templates/jsonInput.jade'
        defaultValue: "[]"
        width: 250
        cellClass: 'clickable-cell'
      ,
        field: 'ignore_until'
        displayName: 'Ignore Until'
        type: 'date'
        width: 125
        cellFilter: 'date:"MM/dd/yy HH:mm"'
        cellClass: 'clickable-cell'
      ,
        field: 'repeat_period_minutes'
        displayName: 'Repeat min'
        type: 'number'
        defaultValue: 60
        width: 125
        cellClass: 'clickable-cell'
      ,
        field: 'warn_timeout_minutes'
        displayName: 'Warn TO min'
        type: 'number'
        defaultValue: 5
        width: 125
        cellClass: 'clickable-cell'
      ,
        field: 'kill_timeout_minutes'
        displayName: 'Kill TO min'
        type: 'number'
        defaultValue: 5
        width: 125
        cellClass: 'clickable-cell'
      ,
        field: 'fail_retry_minutes'
        displayName: 'Fail Retry min'
        type: 'number'
        defaultValue: 5
        width: 125
        cellClass: 'clickable-cell'
      ,
        field: 'active'
        displayName: 'Active?'
        type: 'boolean'
        defaultValue: false
        width: 100
        cellClass: 'clickable-cell'
      ,
        field: '_run'
        displayName: 'Run'
        enableCellEdit: false
        cellTemplate: '<div class="ui-grid-cell-contents"><button type="button" class="btn btn-primary btn-xs" ng-click="grid.appScope.runTask(row.entity)">RUN</button></div>'
        width: 100
      ,
        field: '_cancel'
        displayName: 'Cancel'
        enableCellEdit: false
        cellTemplate: '<div class="ui-grid-cell-contents"><button type="button" class="btn btn-danger btn-xs" ng-click="grid.appScope.cancelTask(row.entity)">CANCEL</button></div>'
        width: 100
    ]
