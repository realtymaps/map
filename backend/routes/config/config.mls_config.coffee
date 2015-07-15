auth = require '../../utils/util.auth'

module.exports =
  getAll:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
  getById:
    method: 'get'
    middleware: auth.requireLogin(redirectOnFail: true)
  update:
    method: 'put'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['change_mlsconfig']}, logoutOnFail:false)
    ]
  updatePropertyData:
    methods: ['patch', 'put']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['change_mlsconfig_mainpropertydata']}, logoutOnFail:false)
    ]
  updateServerInfo:
    methods: ['patch', 'put']
    middleware: [
      auth.requireLogin(redirectOnFail: true) # privileged
      auth.requirePermissions({all:['change_mlsconfig']}, logoutOnFail:false)
    ]
  create:
    method: 'post'
    middleware: [
      auth.requireLogin(redirectOnFail: true) # privileged
      auth.requirePermissions({all:['add_mlsconfig']}, logoutOnFail:false)
    ]
  createById:
    method: 'post'
    middleware: [
      auth.requireLogin(redirectOnFail: true) # privileged
      auth.requirePermissions({all:['add_mlsconfig']}, logoutOnFail:false)
    ]
  delete:
    method: 'delete'
    middleware: [
      auth.requireLogin(redirectOnFail: true) # privileged
      auth.requirePermissions({all:['delete_mlsconfig']}, logoutOnFail:false)
    ]
