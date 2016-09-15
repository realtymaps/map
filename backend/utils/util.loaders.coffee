# this module gets used in memory-sensitive situations, so lazy-load dependencies

createRoute = (routeId, moduleId, backendRoutes, options) ->
  _ = require 'lodash'
  route =
    moduleId: moduleId
    routeId: routeId
    path: if backendRoutes[moduleId]? then _.get(backendRoutes[moduleId], routeId) else undefined
    handle: if _.isFunction options then options else options.handle
    method: options.method || 'get'
    middleware: if _.isFunction(options.middleware) then [options.middleware] else (options.middleware || [])
    order: options.order || 0
  if route.path and not route.handle
    throw new Error "route: #{moduleId}.#{routeId} has no handle"
  if route.handle and not route.path
    throw new Error "route: #{moduleId}.#{routeId} has no path"
  if not route.handle and not route.path
    throw new Error "route: #{moduleId}.#{routeId} has no handle or path"
  route


loadSubmodules = (cwd, searchPath, regex) ->
  path = require 'path'
  fs = require 'fs'
  directoryName = path.join(cwd, searchPath)
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


lazyLoadSubmodules = (cwd, searchPath, regex) ->
  path = require 'path'
  fs = require 'fs'
  directoryName = path.join(cwd, searchPath)
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
      result[submoduleHandle] = () -> require(filePath)
  return result


loadRouteOptions = (directoryName, regex = /^route\.(\w+)\.coffee$/) ->
  _ = require 'lodash'
  normalizedRoutes = []

  create = ->
    route = createRoute routeId, moduleId, require('../../common/config/routes.backend'), options
    normalizedRoutes.push(route)

  modules = loadSubmodules(directoryName, regex)
  for moduleId, routeOptions of modules
    for routeId, options of routeOptions
      unless options.methods?
        create()
        continue

      for key, method of options.methods
        #clone route options to have a new instance of a method
        options = _.merge {}, options, method: method
        create()

  normalizedRoutes


module.exports = {
  loadSubmodules
  lazyLoadSubmodules
  loadRouteOptions
}
