_ = require 'lodash'
Promise = require "bluebird"
svc = require '../services/service.dataSource'


columns = {}

_getColumns = (fileType, action, dataType, subtask) ->
  svc.exposeKnex()
  .getAll(data_source_id:'blackknight', data_source_type:'county', data_list_type: dataType)
  .knex
  .select('LongName', 'MetadataEntryID')
  .orderBy('MetadataEntryID')
  .then (data) ->
    _.map(data, 'LongName')
  .then (cols) ->
    console.log("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ [#{subtask?.data?.rawTableSuffix}] -- _getColumns(fresh) --: #{cols[0]}, #{cols[1]}, #{cols[2]}")
    columns[fileType][action][dataType] = cols

getColumns = (fileType, action, dataType, subtask) -> Promise.try () ->
  if !columns[fileType][action][dataType]?
    _getColumns(fileType, action, dataType, subtask)
  else
    console.log("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ [#{subtask?.data?.rawTableSuffix}] -- _getColumns(cached) --: #{columns[fileType][action][dataType][0]}, #{columns[fileType][action][dataType][1]}, #{columns[fileType][action][dataType][2]}")
    columns[fileType][action][dataType]


module.exports =
  NUM_ROWS_TO_PAGINATE: 2500
  BLACKKNIGHT_PROCESS_DATES: 'blackknight process dates'
  TAX: 'tax'
  DEED: 'deed'
  MORTGAGE: 'mortgage'
  REFRESH: 'Refresh'
  UPDATE: 'Update'
  LAST_COMPLETE_CHECK: 'last complete check'
  DELETE: 'Delete'
  LOAD: 'Load'
  getColumns: getColumns
  tableIdMap:
    ASMT: 'tax'
    Deed: 'deed'
    SAM: 'mortgage'


columns[module.exports.DELETE] = {}
columns[module.exports.DELETE][module.exports.REFRESH] = {}
columns[module.exports.DELETE][module.exports.REFRESH][module.exports.TAX] = [
  "FIPS Code"
  "Edition"
  "Load Date"
]
columns[module.exports.DELETE][module.exports.REFRESH][module.exports.DEED] = [
  "FIPS Code"
]
columns[module.exports.DELETE][module.exports.REFRESH][module.exports.MORTGAGE] = [
  "FIPS Code"
]

columns[module.exports.DELETE][module.exports.UPDATE] = {}
columns[module.exports.DELETE][module.exports.UPDATE][module.exports.TAX] = [
  "FIPS Code"
  "Assessor’s Parcel Number"
  "Edition"
  "Load Date"
]
columns[module.exports.DELETE][module.exports.UPDATE][module.exports.DEED] = [
  "FIPS Code"
  "BK PID"
]
columns[module.exports.DELETE][module.exports.UPDATE][module.exports.MORTGAGE] = [
  "FIPS Code"
  "BK PID"
]

columns[module.exports.LOAD] = {}
columns[module.exports.LOAD][module.exports.REFRESH] = {}
# load columns are the same whether refresh or update
columns[module.exports.LOAD][module.exports.UPDATE] = columns[module.exports.LOAD][module.exports.REFRESH]

