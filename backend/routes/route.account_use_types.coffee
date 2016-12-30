auth = require '../utils/util.auth'
{accountUseTypes} = require '../services/services.user'
{routeCrud} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'

module.exports = mergeHandles routeCrud(accountUseTypes),
  #STRICTLY FOR ADMIN, otherwise profiles are used by session
  root:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['change_user']}, logoutOnFail:true)
    ]
  byId:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['change_user']}, logoutOnFail:true)
    ]
