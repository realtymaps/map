auth = require '../../utils/util.auth'

module.exports =
  getByFipsCode:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
  getByFipsCodeFormatted:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
  uploadToParcelsDb:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
  defineImports:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
