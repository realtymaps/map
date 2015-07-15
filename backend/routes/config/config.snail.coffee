auth = require '../../utils/util.auth'

module.exports =
  quote:
    method: 'post'
    middleware: auth.requireLogin(redirectOnFail: true)
  send:
    method: 'post'
    middleware: auth.requireLogin(redirectOnFail: true)
