logger = require '../config/logger'
countyHandles = require './handles/handle.county'
mlsHandles = require './handles/handle.mls'
routes = require '../../common/config/routes'

glue = require './utils/bindRoutesToHandles'

myRoutesHandles = [
  #county
  {route: routes.country.root handle: countyHandles.getAll}
  {route: routes.country.addresses handle: countyHandles.getAddresses}
  {route: routes.country.apn handle: countyHandles.getApn}
  #mls
  {route: routes.mls.root handle: countyHandles.getAll}
]

module.exports = (app) ->
  glue(app,myRoutesHandles)
