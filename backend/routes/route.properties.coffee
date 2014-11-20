logger = require '../config/logger'
countyHandles = do require './handles/handle.county'
parcelHandles = do require './handles/handle.parcels'
mlsHandles = require './handles/handle.mls'
routes = require '../../common/config/routes'

bindRoutes = require '../utils/util.bindRoutesToHandles'


# logger.debug "routes: #{JSON.stringify routes}"
myRoutesHandles = [
  {route: routes.county.root, handle: countyHandles.getAll}
  {route: routes.mls.root, handle: countyHandles.getAll}
  {route: routes.parcels.root, handle: parcelHandles.getAll}
  {route: routes.parcels.polys, handle: parcelHandles.getAllPolys}
]

module.exports = (app) ->
  bindRoutes app, myRoutesHandles
