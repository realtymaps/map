auth = require '../utils/util.auth'
memdump = require '../utils/util.memdump'

module.exports =
  download:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['access_staff']}, logoutOnFail:true)
    ]
    handle: memdump.getDump
