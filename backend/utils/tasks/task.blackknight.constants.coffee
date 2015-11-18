_ = require 'lodash'
svc = require '../../services/service.dataSource.coffee'


_getColumns = (list) ->
  svc.getAll(data_source_id:'blackknight', data_source_type:'county', data_list_type: list).select('LongName').then (data) ->
    _.map data, 'LongName'

_taxColumns = () ->
  _getColumns 'tax'

_deedColumns = () ->
  _getColumns 'deed'

_mortgageColumns = () ->
  _getColumns 'mortgage'

columns = {}

module.exports =
  NUM_ROWS_TO_PAGINATE: 500
  BLACKKNIGHT_PROCESS_DATES: 'blackknight process dates'
  TAX: 'ASMT'
  DEED: 'Deed'
  MORTGAGE: 'SAM'
  REFRESH: 'Refresh'
  UPDATE: 'Update'
  LAST_COMPLETE_CHECK: 'last complete check'
  DELETE: 'Delete'
  LOAD: 'Load'
  COLUMNS: columns

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
  "APN"
  "Edition"
  "Load Date"
]
columns[module.exports.DELETE][module.exports.UPDATE][module.exports.DEED] = [
  "FIPS Code"
  "PID"
]
columns[module.exports.DELETE][module.exports.UPDATE][module.exports.MORTGAGE] = [
  "FIPS Code"
  "PID"
]


columns[module.exports.LOAD] = {}
columns[module.exports.LOAD][module.exports.REFRESH] = {}
# load columns are the same whether refresh or update
columns[module.exports.LOAD][module.exports.UPDATE] = columns[module.exports.LOAD][module.exports.REFRESH]

_taxColumns().then (cols) ->
  columns[module.exports.LOAD][module.exports.REFRESH][module.exports.TAX] = cols

_deedColumns().then (cols) ->
  columns[module.exports.LOAD][module.exports.REFRESH][module.exports.DEED] = cols

_mortgageColumns().then (cols) ->
  columns[module.exports.LOAD][module.exports.REFRESH][module.exports.MORTGAGE] = cols
