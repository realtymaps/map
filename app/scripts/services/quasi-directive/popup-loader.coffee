#TODO: This really should be a directive in angular-leaflet eventually (nmccready)
app = require '../../app.coffee'
app.service 'popupLoader'.ourNs(),['$templateCache', '$http', '$compile', ($templateCache, $http, $compile) ->
  _map = null

  load: ($scope, map, model, opts = {closeButton: false, offset: new L.Point(0, -5)}, templateUrl = 'map-smallDetails.tpl.html') ->
    _map = map
    return if model?.markerType == 'cluster'
    #redundant but forces out window to not have a close buttons since we always hide on mouseoff
    $http.get(templateUrl, { cache: $templateCache })
    .then (content) ->
      angular.extend opts,
        closeButton: false

      templateScope = $scope.$new()
      templateScope.model = model
      compiled = $compile(content.data)(templateScope)

      lObj = new L.popup(opts)
      .setLatLng
        lat: model.coordinates[1]
        lng: model.coordinates[0]

      .openOn(map)

      lObj.setContent compiled[0]

      lObj

  close:  ->
    return unless _map
    _map.closePopup()
]
