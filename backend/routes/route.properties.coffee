logger = require '../config/logger'
parcelHandles = require './handles/handle.parcels'
propertyHandles = require './handles/handle.properties'
backendRoutes = require '../../common/config/routes.backend.coffee'


bindRoutes = require '../utils/util.bindRoutesToHandles'


# thinking through to what we need long-term, we need 3 basic properties API calls for the near future:
# - address and parcel geometry data for every parcel on the map (only shown at certain zoom levels)
# - property summary data for all parcels on the map that match filter criteria; this will be used to 1) highlight
#   properties different colors based on status, 2) show the price for highlighted properties with any status other
#   than 'not for sale', and 3) populate the mouseover popup
# - full property detail data (including googlemaps and/or MLS images) for a specific property (by rm_property_id),
#   which will be used for the detail view when clicking on a property


myRoutesHandles = [
  {route: backendRoutes.filterSummary, handle: propertyHandles.filterSummary}
  {route: backendRoutes.parcelBase, handle: parcelHandles.parcelBase}
]

module.exports = (app) ->
  bindRoutes app, myRoutesHandles
  
