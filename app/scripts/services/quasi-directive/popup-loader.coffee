#TODO: This really should be a directive in angular-leaflet eventually (nmccready)
app = require '../../app.coffee'
app.service 'popupLoader'.ourNs(),['$templateCache', '$http', '$compile', ($templateCache, $http, $compile) ->
  _map = null

  load: ($scope, map, model, opts = {closeButton: false, offset: new L.Point(0, -5)}, templateUrl = 'map-smallDetails.tpl.html') ->
    _map = map
    return if model?.markerType == 'cluster'

    # redundant but forces out window to not have a close buttons since we always hide on mouseoff
    $http.get(templateUrl, { cache: $templateCache })
    .then (content) ->
      angular.extend opts,
        closeButton: false

      # template for the popup box
      templateScope = $scope.$new()
      templateScope.model = model
      compiled = $compile(content.data)(templateScope)
      coords = model.coordinates or model.geom_point_json?.coordinates

      # get center and point container coords
      center = map.latLngToContainerPoint(map.getCenter())
      point = map.latLngToContainerPoint(new L.LatLng(model.lat, model.lng));

      # ascertain near which container corner the marker is in
      quadrant = ''
      quadrant += (if (point.y > center.y) then "b" else "t")
      quadrant += (if (point.x < center.x) then "l" else "r")

      # create offset point per quadrant
      opts.offset = switch
        when quadrant is "tr" then new L.Point(-181, 236)
        when quadrant is "tl" then new L.Point(181, 236)
        when quadrant is "br" then new L.Point(-181, 20)
        else new L.Point(181, 20)

      # generate and apply popup object
      lObj = new L.popup(opts)
      .setLatLng
        lat: coords[1]
        lng: coords[0]
      .openOn(map)
      lObj.setContent compiled[0]
      lObj

  close:  ->
    return unless _map
    _map.closePopup()
]
