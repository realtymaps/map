{auth_user_groups} = require '../services/services.user'
{routeCrud} = require '../utils/crud/util.crud.route.helpers'
auth = require '../utils/util.auth'
{mergeHandles} = require '../utils/util.route.helpers'

module.exports = mergeHandles routeCrud(auth_user_groups),
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_user','change_user']}, logoutOnFail:true)
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_user','change_user','delete_user']}, logoutOnFail:true)
    ]
