auth = require '../utils/util.auth'
{accountUseTypes} = require '../services/services.user'
EzRouteCrud = require '../utils/crud/util.ezcrud.route.helpers'

accountUseTypesCrud = new EzRouteCrud(accountUseTypes)

handles =
  root:
    method: 'get'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: accountUseTypesCrud.root

  byId:
    method: 'get'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
    handle: accountUseTypesCrud.byId

  create:
    method: 'post'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['change_user']}, logoutOnFail:true)
    ]
    handle: accountUseTypesCrud.root

  edit:
    methods: ['post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['change_user']}, logoutOnFail:true)
    ]
    handle: accountUseTypesCrud.byId

module.exports = handles
