auth = require '../utils/util.auth'
{handleGetRoute} = require '../utils/util.flamegraph'

module.exports =
  flamegraph:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['access_staff']}, logoutOnFail:true)
    ]
    handle: handleGetRoute
