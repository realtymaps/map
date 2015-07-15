auth = require '../../utils/util.auth'

module.exports =
  root:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
