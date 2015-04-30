fs = require 'fs'
path = require 'path'
config = require '../config/config'
logger = require '../config/logger'
backendRoutes = require '../../common/config/routes.backend.coffee'
_ = require 'lodash'


module.exports =
  
  loadRouteHandles: (dirname, routesConfig) ->
    normalizedRoutes = []
    for moduleId,routes of routesConfig
      routeModule = null
      modulePath = path.join(dirname, "route.#{moduleId}.coffee")
      try
        routeModule = require modulePath
      catch err
        msg = "error loading route module '#{moduleId}' from '#{modulePath}':\n#{err.stack}"
        logger.error(msg)
        throw new Error msg
    
      for routeId,options of routes
        route =
          moduleId: moduleId
          routeId: routeId
          path: backendRoutes[moduleId]?[routeId]
          handle: routeModule[routeId]
          method: options.method || 'get'
          middleware: if _.isFunction(options.middleware) then [options.middleware] else (options.middleware || [])
          order: options.order || 0
    
        if route.path and not route.handle
          throw new Error "route: #{moduleId}.#{routeId} has no handle"
        if route.handle and not route.path
          throw new Error "route: #{moduleId}.#{routeId} has no path"
        if not route.handle and not route.path
          throw new Error "route: #{moduleId}.#{routeId} has no handle or path"
    
        normalizedRoutes.push(route)
    normalizedRoutes
    
  loadSubmodules: (directoryName, regex) ->
    result = {}
    fs.readdirSync(directoryName).forEach (file) ->
      submoduleHandle = null
      if regex
        match = regex.exec(file)
        if (match)
          submoduleHandle = match[1]
      else
        submoduleHandle = file
      if submoduleHandle
        filePath = path.join directoryName, file
        result[submoduleHandle] = require(filePath)
    return result
