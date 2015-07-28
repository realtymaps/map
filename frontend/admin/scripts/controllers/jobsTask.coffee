app = require '../app.coffee'
gridController = require '../../../common/scripts/utils/gridController.coffee'

app.controller 'rmapsJobsTaskCtrl', gridController(
  'Task',
  'rmapsJobsService',
  [
      field: 'name'
      displayName: 'Name'
      cellTemplate: '<div class="ui-grid-cell-contents"><a ui-sref="jobsHistory({ task: \'{{COL_FIELD}}\' })">{{COL_FIELD}}</a></div>'
      width: 100
      enableCellEdit: false
    ,
      field: 'description'
      displayName: 'Description'
      width: 300
    ,
      field: 'data'
      displayName: 'Data'
      type: 'object'
      enableCellEdit: true
      editableCellTemplate: require '../../html/views/templates/jsonInput.jade'
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
  ]
)
