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
      width: 100,
      cellFilter: dateFilter
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
    rowTemplate: '<div ng-class="{\'summary-current\': row.entity.timeframe==\'Current\'}" ng-click="grid.appScope.fnOne(row)" ng-repeat="col in colContainer.renderedColumns track by col.colDef.name" class="ui-grid-cell" ui-grid-cell></div>'

  # makes a map (object) of keys from list "grouping", values initialized to 'init'
  emptyDatum = (grouping, init=0) ->
    return _.zipObject(g for g in grouping, _.clone(init,true) for g in grouping)

  # builds multidimensional object representation, initialized with a default aggregate value
  # "dimensions" contains lists of possible values per dimension (a list of lists)
  initDataObj = (dimensions, init=0) ->
    while dimensions.length
      dimensionValues = dimensions.pop()
      init = emptyDatum(dimensionValues, init)
    return init

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
      data = summary.plain()
      showTimeframes = [
        'Current',
        'Last Hour',
        'Last Day',
        'Last 7 Days',
        'Last 30 Days'
      ]
      showStatus = [
        'preparing',
        'running',
        'success',
        'hard fail',
        'timeout',
        'canceled'
      ]
      summaryObj = initDataObj([showTimeframes, showStatus])

      # populate summaryObj with flat dataset
      dimension1 = "timeframe"
      dimension2 = "status"
      for d in data when d[dimension1] in showTimeframes and d[dimension2] in showStatus
        summaryObj[d[dimension1]][d[dimension2]] = d.count

      # Not a terribly efficient cummulative sum implementation, but dataset isn't going to be large here.
      # At least order in dataObj shouldn't matter, and will simply return if no need to build sum
      cSum = (dataObj, timeframe, status) ->
        thisCount = parseInt(dataObj[timeframe][status])
        timeframeOrder = ['Last Hour', 'Last Day', 'Last 7 Days', 'Last 30 Days']
        thisTimeframeIndex = timeframeOrder.indexOf(timeframe)
        while thisTimeframeIndex > 0
          thisTimeframeIndex -= 1
          thisCount += parseInt(dataObj[timeframeOrder[thisTimeframeIndex]][status])
        thisCount

      # obj to table conversion
      initialDimension = "timeframe"
      summaryTable = []
      empty = emptyDatum(col.field for col in $scope.summaryGrid.columnDefs)
      for timeframe, statuses of summaryObj
        datum = _.clone empty
        for status, count of statuses
          datum[initialDimension] = timeframe
          datum[status] = cSum(summaryObj, timeframe, status)

        summaryTable.push(datum)

      $scope.summaryGrid.data = summaryTable

  $rootScope.registerScopeData () ->
    $scope.loadCurrent()
