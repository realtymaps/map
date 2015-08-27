#TODO: This really should be a directive in angular-leaflet eventually (nmccready)
app = require '../../app.coffee'
_defaultOptions = {closeButton: false, offset: new L.Point(0, -5), autoPan: false}
app.service 'rmapsPopupLoader', ($templateCache, $http, $compile, rmapspopupVariables) ->
  _map = null

  _getOffset = (map, model, offsets = rmapspopupVariables.offsets) ->
    # get center and point container coords
    return if !model?.coordinates?.length
    center = map.latLngToContainerPoint map.getCenter()
    point = map.latLngToContainerPoint new L.LatLng model.coordinates[1], model.coordinates[0]

    # ascertain near which container corner the marker is in
    quadrant = ''
    quadrant += (if (point.y > center.y) then "b" else "t")
    quadrant += (if (point.x < center.x) then "l" else "r")

    # create offset point per quadrant
    return switch
      when quadrant is "tr" then new L.Point offsets.right, offsets.top
      when quadrant is "tl" then new L.Point offsets.left, offsets.top
      when quadrant is "br" then new L.Point offsets.right, offsets.bottom
      else new L.Point offsets.left, offsets.bottom


  load: _.debounce ($scope, map, model, opts = _defaultOptions, templateUrl = './views/templates/map-smallDetails.tpl.jade') ->
    _map = map

    return if model?.markerType == 'cluster'

    # redundant but forces out window to not have a close buttons since we always hide on mouseoff
    $http.get(templateUrl, { cache: $templateCache })
    .then (content) ->
      ###
      AS a side note/ WARNING if the templateUrl is incorrect it will resolve the root page
      And on compile will re-initiate all controllers and cause strange behaviors
      ###
      angular.extend opts,
        closeButton: false

      # template for the popup box
      templateScope = $scope.$new()
      templateScope.model = model
      compiled = $compile(content.data)(templateScope)
      coords = model.coordinates or model.geom_point_json?.coordinates

      # set the offset
      opts.offset = _getOffset map, model

      # generate and apply popup object
      lObj = new L.popup opts
      .setLatLng
        lat: coords[1]
        lng: coords[0]
      .openOn map
      lObj.setContent compiled[0]
      lObj
  , 500


  close:  ->
    return unless _map
    _map.closePopup()
