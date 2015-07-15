auth = require '../../utils/util.auth'

module.exports =
  root:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_group','change_group']}, logoutOnFail:true)
    ]
  byId:
    methods: ['get']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_group','change_group','delete_group']}, logoutOnFail:true)
    ]
