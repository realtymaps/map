auth = require '../../utils/util.auth'

module.exports =
  mapboxKey:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
  cartodb:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
