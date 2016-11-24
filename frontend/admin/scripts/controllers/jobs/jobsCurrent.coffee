app = require '../../app.coffee'
_ = require 'lodash'

app.controller 'rmapsJobsCurrentCtrl',
($window, $scope, $rootScope, rmapsJobsService, uiGridConstants, $state) ->

  numericDefaults =
    aggregationType: uiGridConstants.aggregationTypes.sum
    type: 'number'
    enableFiltering: false
    cellClass: 'numberCell'
    footerCellTemplate: '<div class="numberCell">{{ col.getAggregationValue() }}</div>'

  dateFilter = 'date:"MM/dd HH:mm"'
  timeframeFilterMap =
    "Current": { current: true }
    "Last Hour": { timerange: "1 hour" }
    "Last Day": { timerange: "1 day" }
    "Last 7 Days": { timerange: "7 days" }
    "Last 30 Days": { timerange: "30 days" }

  $scope.jobsGrid =
    enableFiltering: true
    enableColumnMenus: false
    showColumnFooter: true
    enablePinning: true
    columnDefs:[
      field: 'name'
      displayName: 'Task'
      width: 160
      cellTemplate: '<div class="ui-grid-cell-contents"><a ui-sref="jobsHistory({ task: COL_FIELD })">{{COL_FIELD}}</a></div>'
      footerCellTemplate: '<div>Totals</div>'
      pinnedLeft: true
    ,
      field: 'status'
      displayName: 'Status'
      width: 80
    ,
      field: 'batch_id'
      displayName: 'Batch'
      width: 80
    ,
      field: 'started'
      displayName: 'Started'
      type: 'date'
      width: 90
      cellFilter: dateFilter
      sort:
        direction: uiGridConstants.DESC
    ,
      field: 'finished'
      displayName: 'Finished'
      type: 'date'
      width: 90,
      cellFilter: dateFilter
    ,
      field: 'status_changed'
      displayName: 'Changed'
      type: 'date'
      width: 90
      cellFilter: dateFilter
    ,
      field: 'initiator'
      displayName: 'Initiator'
      width: 95
    ,
      field: 'data'
      displayName: 'Data'
      visible: false
    ].concat _.map [
      field: 'subtasks_created'
      displayName: 'Created'
      width: 70
    ,
      field: 'subtasks_queued'
      displayName: "Q'ed"
      width: 64
    ,
      field: 'subtasks_preparing'
      displayName: 'Prep'
      width: 64
    ,
      field: 'subtasks_running'
      displayName: 'Running'
      width: 72
    ,
      field: 'subtasks_succeeded'
      displayName: 'Success'
      width: 70
    ,
      field: 'subtasks_failed'
      displayName: 'Failed'
      width: 64
    ,
      field: 'subtasks_soft_failed'
      displayName: 'S Fail'
      width: 64
    ,
      field: 'subtasks_hard_failed'
      displayName: 'H Fail'
      width: 64
    ,
      field: 'subtasks_infrastructure_failed'
      displayName: 'I Fail'
      width: 64
    ,
      field: 'subtasks_canceled'
      displayName: 'Cancel'
      width: 64
    ,
      field: 'subtasks_timeout'
      displayName: 'TimeOut'
      width: 75
    ,
      field: 'subtasks_zombie'
      displayName: 'Zombie'
      width: 68
    ], (num) ->
      _.defaults num, numericDefaults


  $scope.currentFilters = null
  $scope.summaryGrid =
    enableFiltering: true
    enableColumnMenus: false
    enablePinning: true
    enableRowSelection: true
    enableRowHeaderSelection: false
    multiSelect: false
    modifierKeysToMultiSelect: false
    noUnselect: true
    enableSelectionBatchEvent: false
    onRegisterApi: (gridApi) ->
      gridApi.selection.on.rowSelectionChanged $scope, (row) ->
        if !row.isSelected
          return
        $scope.currentFilters =
          queryFilters: timeframeFilterMap[row.entity.timeframe]
          timeframe: row.entity.timeframe
        $scope.loadCurrent()
      gridApi.core.on.rowsRendered $scope, () ->
        if !$scope.currentFilters?
          gridApi.selection.selectRowByVisibleIndex(0)
        else
          gridApi.selection.selectRow(_.find($scope.summaryGrid.data, timeframe: $scope.currentFilters.timeframe))
    columnDefs: [
      field: 'timeframe'
      pinnedLeft: true
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

  $scope.loadSummary = () ->
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
      dimension1 = 'timeframe'
      dimension2 = 'status'
      for d in data when d[dimension1] in showTimeframes and d[dimension2] in showStatus
        summaryObj[d[dimension1]][d[dimension2]] = d.count

      # Not a terribly efficient cumulative sum implementation, but dataset isn't going to be large here.
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
      initialDimension = 'timeframe'
      summaryTable = []
      empty = emptyDatum(col.field for col in $scope.summaryGrid.columnDefs)
      for timeframe, statuses of summaryObj
        datum = _.clone empty
        for status, count of statuses
          datum[initialDimension] = timeframe
          datum[status] = cSum(summaryObj, timeframe, status)

        summaryTable.push(datum)

      $scope.summaryGrid.data = summaryTable

  $scope.loadCurrent = () ->
    $scope.jobsBusy = rmapsJobsService.getHistory($scope.currentFilters.queryFilters)
    .then (jobs) ->
      _.each jobs, (job) ->
        if job.started?
          job.started = new Date(job.started)
        if job.finished?
          job.finished = new Date(job.finished)
        if job.status_changed?
          job.status_changed = new Date(job.status_changed)
      $scope.jobsGrid.data = jobs.plain()

  $scope.loadSummary()
