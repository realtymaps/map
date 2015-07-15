auth = require '../../utils/util.auth'

module.exports =
  getDatabaseList:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
  getTableList:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
  getColumnList:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
  getDataDump:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
  getLookupTypes:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
