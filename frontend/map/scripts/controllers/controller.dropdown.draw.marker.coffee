_ = require 'lodash'
L = require 'leaflet'
app = require '../app.coffee'
arrowTemplate = require '../../html/includes/map/markers/_arrowMarker.jade'
circleTemplate = require '../../html/includes/map/markers/_circledMarker.jade'

app.constant 'rmapsMarkersIcons', do ->
  flatArrows = _.extend {}, _.flatten( ['blue', 'yellow'].map (color) ->
    "leaflet-arrow-up-marker-#{color}": L.divIcon
      iconAnchor: [20, 20]
      iconSize: [40, 40]
      html: arrowTemplate(classes: ["#{color} icon-arrow-up"])

    "leaflet-arrow-down-marker-#{color}": L.divIcon
      iconAnchor: [20, 20]
      iconSize: [40, 40]
      html: arrowTemplate(classes: ["#{color} icon-arrow-down"])

    "leaflet-arrow-left-marker-#{color}": L.divIcon
      iconAnchor: [20, 20]
      iconSize: [40, 40]
      html: arrowTemplate(classes: ["#{color} icon-arrow-left"])

    "leaflet-arrow-right-marker-#{color}": L.divIcon
      iconAnchor: [20, 20]
      iconSize: [40, 40]
      html: arrowTemplate(classes: ["#{color} icon-arrow-right"])
  )...

  flatCircles = _.extend {}, _.flatten( ['green', 'magenta', 'blue', 'yellow'].map (color) ->
    "leaflet-circled-marker-#{color}": L.divIcon
      iconAnchor: [20, 20]
      iconSize: [40, 40]
      html: circleTemplate(classes: ["icon-circled-marker-#{color}"])
  )...

  _.extend {}, flatArrows, flatCircles



app.controller "rmapsLeafletDrawMarkerDropdownCtrl", (
  $scope
  $log
  rmapsMarkersIcons
) ->
  $log = $log.spawn('rmapsLeafletDrawMarkerDropdownCtrl')

  $scope.dropdown = isOpen: false

  $scope.clickedMarkerExt = (e, type) ->
    icon = rmapsMarkersIcons[type]
    if !icon?
      $log.warn('clickedMarkerExt icon is undefined')

    $scope.clickedMarker(e, {icon})

  return
