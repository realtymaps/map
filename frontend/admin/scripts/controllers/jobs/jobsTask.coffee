app = require '../../app.coffee'
gridButton = require '../../../../common/html/views/templates/gridButton.jade'
jsonInput = require '../../../html/views/templates/jsonInput.jade'


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
        width: 140
        enableCellEdit: false
        pinnedLeft: true
        sort:
          direction: uiGridConstants.ASC
      ,
        field: 'active'
        displayName: 'Active?'
        type: 'boolean'
        defaultValue: false
        width: 65
        cellClass: 'clickable-cell'
        pinnedLeft: true
      ,
        field: '_run'
        displayName: 'Run'
        enableCellEdit: false
        cellTemplate: gridButton(click: "grid.appScope.runTask(row.entity)", content: "RUN", clz: "btn btn-primary btn-xs")
        width: 50
        enableFiltering: false
        pinnedLeft: true
    ,
        field: '_cancel'
        displayName: 'Cancel'
        enableCellEdit: false
        cellTemplate: gridButton(click: "grid.appScope.cancelTask(row.entity)", content: "CANCEL", clz: "btn btn-danger btn-xs")
        width: 68
        enableFiltering: false
        pinnedLeft: true
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
        editableCellTemplate: jsonInput
        defaultValue: "{}"
        width: 50
        cellClass: 'clickable-cell'
      ,
        field: 'blocked_by_tasks'
        displayName: 'Blocking Tasks'
        type: 'object'
        enableCellEdit: true
        editableCellTemplate: jsonInput
        defaultValue: "[]"
        width: 250
        cellClass: 'clickable-cell'
      ,
        field: 'blocked_by_locks'
        displayName: 'Blocking Locks'
        type: 'object'
        enableCellEdit: true
        editableCellTemplate: jsonInput
        defaultValue: "[]"
        width: 250
        cellClass: 'clickable-cell'
      ,
        field: 'ignore_until'
        displayName: 'Ignore Until'
        type: 'date'
        width: 95
        cellFilter: 'date:"MM/dd/yy HH:mm"'
        cellClass: 'clickable-cell'
        enableFiltering: false
      ,
        field: 'repeat_period_minutes'
        displayName: 'Repeat min'
        type: 'number'
        defaultValue: 60
        width: 92
        cellClass: 'clickable-cell'
        enableFiltering: false
      ,
        field: 'warn_timeout_minutes'
        displayName: 'Warn TO min'
        type: 'number'
        defaultValue: 5
        width: 105
        cellClass: 'clickable-cell'
        enableFiltering: false
      ,
        field: 'kill_timeout_minutes'
        displayName: 'Kill TO min'
        type: 'number'
        defaultValue: 5
        width: 90
        cellClass: 'clickable-cell'
        enableFiltering: false
      ,
        field: 'fail_retry_minutes'
        displayName: 'Fail Retry min'
        type: 'number'
        defaultValue: 5
        width: 106
        cellClass: 'clickable-cell'
        enableFiltering: false
    ]
