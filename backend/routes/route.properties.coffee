logger = require '../config/logger'
countyHandles = do require './handles/handle.county'
mlsHandles = require './handles/handle.mls'
routes = require '../../common/config/routes'

bindRoutes = require './utils/bindRoutesToHandles'


# logger.debug "routes: #{JSON.stringify routes}"
logger.debug "countyHandles: " + countyHandles
myRoutesHandles = [
  #county
  {route: routes.county.root, handle: countyHandles.getAll}
  {route: routes.county.addresses, handle: countyHandles.getAddresses}
  {route: routes.county.apn, handle: countyHandles.getApn}
  #mls
  {route: routes.mls.root, handle: countyHandles.getAll}
]

module.exports = (app) ->
  bindRoutes app, myRoutesHandles
