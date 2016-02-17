###globals L, angular###
app = require '../app.coffee'
template = require './leafletDraw/leafletDraw.jade'
LeafletDrawApi = require './leafletDraw/api.draw.js'


app.directive 'rmapsLeafletDraw', ($log, leafletData, leafletDrawEvents, $timeout) ->
  $log = $log.spawn('rmapsLeafletDraw')
  scope:
    mapPromise: '='
    options: '=?'

  template: template()
  replace: false
  restrict: 'C'
  # require: ['leaflet']
  link: (scope, element, attrs) ->
    if !leafletData
      throw new Error 'ui-leaflet is not loaded'

    _featureGroup = undefined
    _optionsEditedInDirective = false
    _deferred = undefined

    unless scope.mapPromise
      throw new Error 'mapPromise required'

    scope.mapPromise.then (map) ->

      _create = () ->
        if attrs.id?
          scope.attrsId = attrs.id

        return if _optionsEditedInDirective

        options = scope.options or {}

        if options.control?.promises?
          options.control.promised _deferred.promise

        if _featureGroup
          map.removeLayer _featureGroup

        if !L.Control.Draw?
          $log.error "#{errorHeader} Leaflet.Draw is not loaded as a plugin."
          return

        if !options?.edit? or !options?.edit?.featureGroup?
          _optionsEditedInDirective = true
          angular.extend options,
            edit:
              featureGroup: new L.FeatureGroup()

          $timeout -> _optionsEditedInDirective = false #skip extra digest due to above mod

        _featureGroup = options.edit.featureGroup
        map.addLayer(_featureGroup)
        drawControl = new LeafletDrawApi options

        map.addControl drawControl
        _deferred.resolvedDefer = true
        _deferred.resolve
          control: drawControl
          map:map

        leafletDrawEvents.bindEvents(attrs.id, map, name = null, options, leafletScope, layerName = null, {mapId: attrs.id})
