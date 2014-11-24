logger = require '../config/logger'
countyHandles = do require './handles/handle.county'
parcelHandles = do require './handles/handle.parcels'
mlsHandles = require './handles/handle.mls'
backendRoutes = require '../../common/config/routes.backend.coffee'


bindRoutes = require '../utils/util.bindRoutesToHandles'


# logger.debug "routes: #{JSON.stringify routes}"
myRoutesHandles = [
  {route: backendRoutes.county.root, handle: countyHandles.getAll}
  {route: backendRoutes.mls.root, handle: countyHandles.getAll}
  {route: backendRoutes.parcels.root, handle: parcelHandles.getAll}
  {route: backendRoutes.parcels.polys, handle: parcelHandles.getAllPolys}
]

module.exports = (app) ->
  bindRoutes app, myRoutesHandles
