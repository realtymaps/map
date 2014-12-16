auth = require '../utils/util.auth'
logger = require '../config/logger'
propertyHandles = require './handles/handle.properties'
backendRoutes = require '../../common/config/routes.backend.coffee'
userService = require '../services/service.user'

bindRoutes = require '../utils/util.bindRoutesToHandles'



handles = [
  { route: backendRoutes.filterSummary, handle: propertyHandles.filterSummary, middleware: [auth.requireLogin(redirectOnFail: true), userService.captureMapFilterState] }
  { route: backendRoutes.parcelBase,    handle: propertyHandles.parcelBase,    middleware: [auth.requireLogin(redirectOnFail: true), userService.captureMapState] }
]

module.exports = (app) ->
  bindRoutes app, handles
  
