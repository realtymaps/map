auth = require '../utils/util.auth'
{group} = require '../services/services.user'
{routeCrud} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'

module.exports = mergeHandles routeCrud(group),
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
