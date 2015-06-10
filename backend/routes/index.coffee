logger = require '../config/logger'
auth = require '../utils/util.auth'
userService = require '../services/service.user'
loaders = require '../utils/util.loaders'
_ = require 'lodash'


routesConfig =

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
    user:
        login:
            method: 'post'
        logout: {}
        identity: {}
        updateState:
            method: 'post'
            middleware: auth.requireLogin(redirectOnFail: true)
    properties:
        filterSummary:
            middleware: [
                auth.requireLogin(redirectOnFail: true)
                userService.captureMapFilterState
            ]
        parcelBase:
            middleware: [
                auth.requireLogin(redirectOnFail: true)
                userService.captureMapState
            ]
        addresses:
            middleware: [
                auth.requireLogin(redirectOnFail: true)
                userService.captureMapState
            ]
        detail:
            middleware: [
                auth.requireLogin(redirectOnFail: true)
                userService.captureMapState
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
    mapbox:
        upload:
            method: 'get'
            middleware: auth.requireLogin(redirectOnFail: true)
    cartodb:
        getByFipsCodeAsFile:
            method: 'get'
        getByFipsCodeAsStream:
            method: 'get'
    parcel:
        getByFipsCode:
            method: 'get'
        getByFipsCodeFormatted:
            method: 'get'
        uploadToParcelsDb:
            method: 'get'
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
