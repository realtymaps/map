auth = require '../utils/util.auth'
{company} = require '../services/services.user'
{routeCrud} = require '../utils/crud/util.crud.route.helpers'
{mergeHandles} = require '../utils/util.route.helpers'

module.exports = mergeHandles routeCrud(company),
  #STRICTLY FOR ADMIN, otherwise profiles are used by session
  root:
    middleware: auth.requireLogin(redirectOnFail: true)
  rootPost:
    method: 'post'
    handle: 'root'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_company','change_company']}, logoutOnFail:true)
    ]
  byId:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
    ]
  byIdWPerms:
    methods: ['post', 'put', 'delete']
    handle: 'byId'
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_company','change_company','delete_company']}, logoutOnFail:true)
    ]
