app = require '../../app.coffee'

module.exports = app

app.factory 'rmapsPropertyMarkerGroup', (
  $log
  rmapsBounds
) ->

  #
  # Class representing Leaflet markers that are backed by Realty Maps properties
  #
  class RmapsPropertyMarkerGroup
    # Parent MapAccess
    parent: null

    # Type name to be used for the makers
    layerName: null

    # The Leaflet scope context variables provided to the Leaflet directive
    context: null

    # The markers used by Leaflet map
    markers: {}

    # Default marker Icon ... can be overridden
    icon:
      type: 'div'
      className: 'project-dashboard-icon'
      html: '<span class="icon icon-area"></span>'

    constructor: (layerName) ->
      @layerName = layerName

    init: (parentMapAccess, context) ->
      @parent = parentMapAccess
      @context = context

    # Take a list of properties and create the Map Scope markers to render
    addPropertyMarkers: (properties) ->
      if !properties?.length
        return

      _.forEach properties, (property) =>
        if property.geometry_center?.coordinates?
          @markers[property.rm_property_id] = {
            rm_property_id: property.rm_property_id,
            lat: property.geometry_center.coordinates[1],
            lng: property.geometry_center.coordinates[0],
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
          lat: properties[0].geometry_center.coordinates[1],
          lng: properties[0].geometry_center.coordinates[0],
          zoom: 15
        }

      return

    # Add a marker click handler $scope.$on for the current map and ensure
    # that the marker click events are enabled on the Map Scope
    registerClickHandler: ($scope, handler) ->
      @context.enableMarkerEvent('click')

      # Wrap the actual handler in an anonymous handler that will unwrap the arguments
      # and verify that only events for the appropriate Group layer will be handled
      event = "leafletDirectiveMarker.#{@parent.mapId}.click"
      $scope.$on event, (event, args) =>
        {leafletEvent, leafletObject, model, modelName, layerName} = args

        if layerName == @layerName
          # Marker click was in the correct group, call the handler
          handler(event, args, model.rm_property_id)

    # Set the class of a property marker
    setPropertyClass: (propertyId, className, resetOtherMarkers = false) ->
      if resetOtherMarkers
        _.forOwn @markers, (marker) =>
          marker.icon?.className = @icon.className

      @markers[propertyId]?.icon.className = className

  #
  # Return the class definition, which should be instantiated by the controller using the map
  #
  return RmapsPropertyMarkerGroup
