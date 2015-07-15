auth = require '../../utils/util.auth'

module.exports =
  login:
    method: 'post'
  logout: {}
  identity: {}
  updateState:
    method: 'post'
    middleware: auth.requireLogin(redirectOnFail: true)
  currentProfile:
    method: 'post'
    middleware: auth.requireLogin(redirectOnFail: true)
  profiles:
    methods: ['get', 'put']
    middleware: auth.requireLogin(redirectOnFail: true)
