app = require '../../app.coffee'

module.exports = app

app.factory 'rmapsPropertyMarkers', (
  $log
  rmapsBounds
) ->

  #
  # Class representing Leaflet markers that are backed by Realty Maps properties
  #
  class RmapsPropertyMarkers
    # Type name to be used for the makers
    markerType: null

    # The Leaflet scope context variables provided to the Leaflet directive
    context: null

    # The markers used by Leaflet map
    markers: {}

    # Default marker Icon ... can be overridden
    icon:
      type: 'div'
      className: 'project-dashboard-icon'
      html: '<span class="icon icon-neighbourhood"></span>'

    constructor: (markerType) ->
      @markerType = markerType

    # Take a list of properties and create the Map Scope markers to render
    addPropertyMarkers: (properties) ->
      if !properties?.length
        return

      angular.forEach properties, (property) =>
        if property.geom_point_json?.coordinates?
          @markers[property.rm_property_id] = {
            lat: property.geom_point_json.coordinates[1],
            lng: property.geom_point_json.coordinates[0],
            draggable: false,
            focus: false,
            icon: angular.copy(@icon)
          }

      return

    # Fit the map bounds to an array of properties
    fitToBounds: (properties) ->
      $log.debug("fitToBounds", properties)

      if !properties.length
        return

      if properties.length > 1
        bounds = rmapsBounds.boundsFromPropertyArray(properties)
        @context.bounds = bounds
      else
        @context.center = {
          lat: properties[0].geom_point_json.coordinates[1],
          lng: properties[0].geom_point_json.coordinates[0],
          zoom: 15
        }

      return

    # Set the class of a property marker
    setPropertyClass: (propertyId, className, resetOtherMarkers = false) ->
      if resetOtherMarkers
        _.forOwn @markers, (marker) =>
          marker.icon?.className = @icon.className

      @markers[propertyId]?.icon.className = className

  return RmapsPropertyMarkers
