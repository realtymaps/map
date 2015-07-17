auth = require '../utils/util.auth'
{auth_permission} = require '../services/services.user'
{routeCrud} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'

module.exports = mergeHandles routeCrud(auth_permission),
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_permission','change_permission']}, logoutOnFail:true)
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_permission','change_permission','delete_permission']}, logoutOnFail:true)
    ]
