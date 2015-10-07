{m2m_user_group} = require '../services/services.user'
{routeCrud} = require '../utils/crud/util.crud.route.helpers'
auth = require '../utils/util.auth'
{mergeHandles} = require '../utils/util.route.helpers'

module.exports = mergeHandles routeCrud(m2m_user_group),
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
