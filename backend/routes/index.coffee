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
        #TODO: API_KEY middleware
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

module.exports = (app) ->
    _.forEach _.sortBy(loaders.loadRouteHandles(__dirname, routesConfig), 'order'), (route) ->
        logger.infoRoute "route: #{route.moduleId}.#{route.routeId} intialized (#{route.method})"
        app[route.method](route.path, route.middleware..., route.handle)

    logger.info '\n'
    logger.info "available routes: "
    app._router.stack.filter((r) ->
        r?.route?
    ).forEach (r) ->
        path = r.route.path
        logger.info path
