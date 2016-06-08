auth = require '../utils/util.auth'
{user} = require '../services/services.user'
{RouteCrud, hasManyRouteCrud} = require '../utils/crud/util.crud.route.helpers'
logger = require '../config/logger'
{mergeHandles} = require '../utils/util.route.helpers'

class UserCrud extends RouteCrud
  init: () ->
    @permissionsCrud = hasManyRouteCrud(@svc.permissions, 'permission_id', 'user_id', 'PermissionsHasManyRouteCrud')
    @permissions = @permissionsCrud.root
    @permissionsById = @permissionsCrud.byId

    @groupsCrud = hasManyRouteCrud(@svc.groups, 'group_id', 'user_id', 'GroupsHasManyRouteCrud')#.init(true)#to enable logging
    @groups = @groupsCrud.root
    @groupsById = @groupsCrud.byId

    super()


module.exports = mergeHandles new UserCrud(user),
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
  #might want to twerk permissions required
  permissions:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_user','change_user','delete_user']}, logoutOnFail:true)
    ]
  permissionsById:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_user','change_user','delete_user']}, logoutOnFail:true)
    ]
  #might want to twerk permissions required
  groups:
    methods: ['get', 'post']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_user','change_user','delete_user']}, logoutOnFail:true)
    ]
  groupsById:
    methods: ['get', 'post', 'put', 'delete']
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      auth.requirePermissions({all:['add_user','change_user','delete_user']}, logoutOnFail:true)
    ]
