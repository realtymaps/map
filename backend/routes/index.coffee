logger = require '../config/logger'
auth = require '../utils/util.auth'
userSessionService = require '../services/service.userSession'
loaders = require '../utils/util.loaders'
_ = require 'lodash'


routesConfig =

  views:
    rmap:
      method: 'get'
    admin:
      method: 'get'
    mocksResults:
      method: 'get'

  wildcard:
    backend:
      method: 'all'
      order: 9998 # needs to be first
    admin:
      method: 'all'
      order: 9999 # needs to be next to last
    frontend:
      method: 'all'
      order: 10000 # needs to be last
  userSession:
    login:
      method: 'post'
    logout: {}
    identity: {}
    updateState:
      method: 'post'
      middleware: auth.requireLogin(redirectOnFail: true)
    currentProfile:
      method: 'post'
      middleware: auth.requireLogin(redirectOnFail: true)
    profiles:
      methods: ['get', 'post']
      middleware: auth.requireLogin(redirectOnFail: true)
  user:
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
      methods: ['get']
      middleware: [
        auth.requireLogin(redirectOnFail: true)
        auth.requirePermissions({all:['add_user','change_user','delete_user']}, logoutOnFail:true)
      ]
    permissionsById:
      methods: ['get']
      middleware: [
        auth.requireLogin(redirectOnFail: true)
        auth.requirePermissions({all:['add_user','change_user','delete_user']}, logoutOnFail:true)
      ]
    #might want to twerk permissions required
    groups:
      methods: ['get']
      middleware: [
        auth.requireLogin(redirectOnFail: true)
        auth.requirePermissions({all:['add_user','change_user','delete_user']}, logoutOnFail:true)
      ]
    groupsById:
      methods: ['get']
      middleware: [
        auth.requireLogin(redirectOnFail: true)
        auth.requirePermissions({all:['add_user','change_user','delete_user']}, logoutOnFail:true)
      ]
    #might want to twerk permissions required
    profiles:
      methods: ['get']
      middleware: [
        auth.requireLogin(redirectOnFail: true)
        auth.requirePermissions({all:['add_user','change_user','delete_user']}, logoutOnFail:true)
      ]
  user_user_groups:
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
  user_groups:#only see groups, using migrations to keep permissions in sync
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
  user_permissions: #only see permission, using migrations to keep permissions in sync
    root:
      methods: ['get']
      middleware: [
        auth.requireLogin(redirectOnFail: true)
        auth.requirePermissions({all:['add_permission','change_permission']}, logoutOnFail:true)
      ]
    byId:
      methods: ['get']
      middleware: [
        auth.requireLogin(redirectOnFail: true)
        auth.requirePermissions({all:['add_permission','change_permission','delete_permission']}, logoutOnFail:true)
      ]
  user_group_permissions:
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
  user_projects:#STRICTLY FOR ADMIN, otherwise projects are used by session
    root:
      methods: ['get', 'post']
      middleware: [
        auth.requireLogin(redirectOnFail: true)
        auth.requirePermissions({all:['add_project','change_project']}, logoutOnFail:true)
      ]
    byId:
      methods: ['get', 'post', 'put', 'delete']
      middleware: [
        auth.requireLogin(redirectOnFail: true)
        auth.requirePermissions({all:['add_project','change_project','delete_project']}, logoutOnFail:true)
      ]
  user_profiles:#STRICTLY FOR ADMIN, otherwise profiles are used by session
    root:
      methods: ['get', 'post']
      middleware: [
        auth.requireLogin(redirectOnFail: true)
        auth.requirePermissions({all:['add_useraccountprofile','change_useraccountprofile']}, logoutOnFail:true)
      ]
    byId:
      methods: ['get', 'post', 'put', 'delete']
      middleware: [
        auth.requireLogin(redirectOnFail: true)
        auth.requirePermissions({all:['add_useraccountprofile','change_useraccountprofile','delete_useraccountprofile']}, logoutOnFail:true)
      ]
  properties:
    filterSummary:
      middleware: [
        auth.requireLogin(redirectOnFail: true)
        userSessionService.captureMapFilterState
      ]
    parcelBase:
      middleware: [
        auth.requireLogin(redirectOnFail: true)
        userSessionService.captureMapState
      ]
    addresses:
      middleware: [
        auth.requireLogin(redirectOnFail: true)
        userSessionService.captureMapState
      ]
    detail:
      middleware: [
        auth.requireLogin(redirectOnFail: true)
        userSessionService.captureMapState
      ]
  version:
    version: {}
  config:
    mapboxKey:
      method: 'get'
      middleware: auth.requireLogin(redirectOnFail: true)
    cartodb:
      method: 'get'
      middleware: auth.requireLogin(redirectOnFail: true)
  snail:
    quote:
      method: 'post'
      middleware: auth.requireLogin(redirectOnFail: true)
    send:
      method: 'post'
      middleware: auth.requireLogin(redirectOnFail: true)
  hirefire:
    info: {}

  cartodb:
    #note security for this route set is an API_KEY provided to CartoDB
    getByFipsCodeAsFile:
      method: 'get'
    getByFipsCodeAsStream:
      method: 'get'
  parcel:
    getByFipsCode:
      method: 'get'
      middleware: auth.requireLogin(redirectOnFail: true)
    getByFipsCodeFormatted:
      method: 'get'
      middleware: auth.requireLogin(redirectOnFail: true)
    uploadToParcelsDb:
      method: 'get'
      middleware: auth.requireLogin(redirectOnFail: true)
    defineImports:
      method: 'get'
      middleware: auth.requireLogin(redirectOnFail: true)
  mls_config:
    getAll:
      method: 'get'
      middleware: auth.requireLogin(redirectOnFail: true)
    getById:
      method: 'get'
      middleware: auth.requireLogin(redirectOnFail: true)
    update:
      method: 'put'
      middleware: auth.requireLogin(redirectOnFail: true)
    updatePropertyData:
      method: 'patch'
      middleware: auth.requireLogin(redirectOnFail: true)
    updateServerInfo:
      method: 'patch'
      middleware: auth.requireLogin(redirectOnFail: true) # privileged
    create:
      method: 'post'
      middleware: auth.requireLogin(redirectOnFail: true) # privileged
    createById:
      method: 'post'
      middleware: auth.requireLogin(redirectOnFail: true) # privileged
    delete:
      method: 'delete'
      middleware: auth.requireLogin(redirectOnFail: true) # privileged
  mls:
    getDatabaseList:
      method: 'get'
      middleware: auth.requireLogin(redirectOnFail: true)
    getTableList:
      method: 'get'
      middleware: auth.requireLogin(redirectOnFail: true)
    getColumnList:
      method: 'get'
      middleware: auth.requireLogin(redirectOnFail: true)
    getDataDump:
      method: 'get'
      middleware: auth.requireLogin(redirectOnFail: true)
    getLookupTypes:
      method: 'get'
      middleware: auth.requireLogin(redirectOnFail: true)
  mls_normalization:
    getMlsRules:
      method: 'get'
      middleware: auth.requireLogin(redirectOnFail: true)
    createMlsRules:
      method: 'post'
      middleware: auth.requireLogin(redirectOnFail: true)
    putMlsRules:
      method: 'put'
      middleware: auth.requireLogin(redirectOnFail: true)
    deleteMlsRules:
      method: 'delete'
      middleware: auth.requireLogin(redirectOnFail: true)
    getListRules:
      method: 'get'
      middleware: auth.requireLogin(redirectOnFail: true)
    createListRules:
      method: 'post'
      middleware: auth.requireLogin(redirectOnFail: true)
    putListRules:
      method: 'put'
      middleware: auth.requireLogin(redirectOnFail: true)
    deleteListRules:
      method: 'delete'
      middleware: auth.requireLogin(redirectOnFail: true)
    getRule:
      method: 'get'
      middleware: auth.requireLogin(redirectOnFail: true)
    updateRule:
      method: 'patch'
      middleware: auth.requireLogin(redirectOnFail: true)
    deleteRule:
      method: 'delete'
      middleware: auth.requireLogin(redirectOnFail: true)


module.exports = (app) ->
  _.forEach _.sortBy(loaders.loadRouteHandles(__dirname, routesConfig), 'order'), (route) ->
    logger.infoRoute "route: #{route.moduleId}.#{route.routeId} intialized (#{route.method})"
    app[route.method](route.path, route.middleware..., route.handle)

  logger.info '\n'
  logger.info "available routes: "
  paths = {}
  app._router.stack.filter((r) ->
    r?.route?
  ).forEach (r) ->
    methods = paths[r.route.path] || []
    paths[r.route.path] = methods.concat(_.keys(r.route.methods))

  _.forEach paths, (methods, path) ->
    logger.info path, '(' + (if methods.length >= 25 then 'all' else methods.join(',')) + ')'
