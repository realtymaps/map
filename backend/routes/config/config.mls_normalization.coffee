auth = require '../../utils/util.auth'

module.exports =
  getMlsRules:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
  createMlsRules:
    method: 'post'
    middleware: auth.requireLogin(redirectOnFail: true)
  putMlsRules:
    method: 'put'
    middleware: auth.requireLogin(redirectOnFail: true)
  deleteMlsRules:
    method: 'delete'
    middleware: auth.requireLogin(redirectOnFail: true)
  getListRules:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
  createListRules:
    method: 'post'
    middleware: auth.requireLogin(redirectOnFail: true)
  putListRules:
    method: 'put'
    middleware: auth.requireLogin(redirectOnFail: true)
  deleteListRules:
    method: 'delete'
    middleware: auth.requireLogin(redirectOnFail: true)
  getRule:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
  updateRule:
    method: 'patch'
    middleware: auth.requireLogin(redirectOnFail: true)
  deleteRule:
    method: 'delete'
    middleware: auth.requireLogin(redirectOnFail: true)
