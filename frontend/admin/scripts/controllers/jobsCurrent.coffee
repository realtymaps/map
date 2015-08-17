app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsJobsCurrentCtrl',
($window, $scope, $rootScope, rmapsJobsService, uiGridConstants, $state) ->

  numericDefaults =
    aggregationType: uiGridConstants.aggregationTypes.sum
    type: 'number'
    width: 75
    cellClass: 'numberCell'
    footerCellTemplate: '<div class="numberCell">{{ col.getAggregationValue() }}</div>'

  dateFilter = 'date:"MM/dd HH:mm"'

  $scope.jobsGrid =
    enableColumnMenus: false
    showColumnFooter: true
    columnDefs:[
      field: 'name'
      displayName: 'Task'
      width: 100
      cellTemplate: '<div class="ui-grid-cell-contents"><a ui-sref="jobsHistory({ task: \'{{COL_FIELD}}\' })">{{COL_FIELD}}</a></div>'
      footerCellTemplate: '<div>Totals</div>'
      sort:
        direction: uiGridConstants.ASC
    ,
      field: 'status'
      displayName: 'Status'
      width: 75
    ,
      field: 'batch_id'
      displayName: 'Batch'
      width: 75
    ,
      field: 'started'
      displayName: 'Started'
      type: 'date'
      width: 100
      cellFilter: dateFilter
    ,
      field: 'finished'
      displayName: 'Finished'
      type: 'date'
      width: 75,
      cellFilter: dateFilter
      visible: false
    ,
      field: 'status_changed'
      displayName: 'Changed'
      type: 'date'
      width: 100
      cellFilter: dateFilter
    ,
      field: 'initiator'
      displayName: 'Initiator'
      width: 75
    ,
      field: 'data'
      displayName: 'Data'
      visible: false
  ].concat _.map [
      field: 'subtasks_created'
      displayName: 'Created'
    ,
      field: 'subtasks_preparing'
      displayName: 'Prep'
    ,
      field: 'subtasks_running'
      displayName: 'Running'
    ,
      field: 'subtasks_succeeded'
      displayName: 'Success'
    ,
      field: 'subtasks_failed'
      displayName: 'Failed'
    ,
      field: 'subtasks_soft_failed'
      displayName: 'S Fail'
    ,
      field: 'subtasks_hard_failed'
      displayName: 'H Fail'
    ,
      field: 'subtasks_infrastructure_failed'
      displayName: 'I Fail'
    ,
      field: 'subtasks_canceled'
      displayName: 'Cancel'
    ,
      field: 'subtasks_timeout'
      displayName: 'TimeOut'
    ,
      field: 'subtasks_zombie'
      displayName: 'Zombie'
    ,
      field: 'warn_timeout_minutes'
      displayName: 'Warn TO'
      visible: false
    ,
      field: 'kill_timeout_minutes'
      displayName: 'Kill TO'
      visible: false
    ], (num) ->
      _.extend num, numericDefaults


  $scope.summaryGrid =
    enableColumnMenus: false
    columnDefs: [
      field: 'timeframe'
    ,
      field: 'preparing'
    ,
      field: 'running'
    ,
      field: 'success'
    ,
      field: 'hard fail'
    ,
      field: 'timeout'
    ,
      field: 'canceled'
    ]

  cumSumDef = 
    colGrp: "timeframe" # kindof like a group-by, but cumulative order is based on this column
    colGrpOrder: ['Last Hour', 'Last Day', 'Last 7 Days', 'Last 30 Days'] # define what order of colGrp data should be
    columnForSum: ['preparing', 'running', 'success', 'hard fail', 'timeout', 'canceled'] # define which other cols to sum on

  # generalized cumulative sum
  cumSumCalc = () ->
    return null

  makeEmptyDatum = (cols, init=0) ->
    return _.zipObject(col.field for col in cols, init for col in cols)


  $scope.loadCurrent = () ->
    $scope.jobsBusy = rmapsJobsService.getCurrent()
    .then (jobs) ->
      _.each jobs, (job) ->
        job.started = new Date(job.started)
        job.finished = new Date(job.finished)
        job.status_changed = new Date(job.status_changed)
      $scope.jobsGrid.data = jobs.plain()

    $scope.summaryBusy = rmapsJobsService.getSummary()
    .then (summary) ->
      console.log "#### incoming summary data:"
      console.log summary.plain()
      data = summary.plain()

      groupCol = "timeframe"
      expandCol = "status"
      unflattened = {}
      for d in data
        if not (d[groupCol] of unflattened)
          unflattened[d[groupCol]] = {}
        if not (d[expandCol] of unflattened[d[groupCol]])
          unflattened[d[groupCol]][d[expandCol]] = d.count


      unflattenedTable = []
      empty = makeEmptyDatum($scope.summaryGrid.columnDefs)
      for timeframe, statuses of unflattened
        datum = _.clone empty
        for status, count of statuses
          datum[groupCol] = timeframe
          datum[status] = count
        unflattenedTable.push(datum)


      $scope.summaryGrid.data = unflattenedTable

  $rootScope.registerScopeData () ->
    $scope.loadCurrent()
