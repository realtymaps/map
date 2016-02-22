###globals L, angular###
app = require '../app.coffee'
template = require './leafletDraw/leafletDraw.jade'
LeafletDrawApi = require './leafletDraw/api.draw.js'


app.directive 'rmapsLeafletDraw', ($log, leafletData, leafletDrawEvents, $timeout, leafletIterators,
rmapsLeafletDrawDirectiveCtrlDefaultsService) ->

  errorHeader = "rmapsLeafletDraw"

  {getEventName, drawContexts, scopeContext} = rmapsLeafletDrawDirectiveCtrlDefaultsService

  $log = $log.spawn('rmapsLeafletDraw')

  scope:
    mappromise: '='
    options: '=?'
    events: '=?'
    enabled: '=?'

  template: template()
  replace: false
  restrict: 'C'
  # require: ['leaflet']
  link: (scope, element, attrs) ->
    _featureGroup = _deferred = _currentHandler = undefined
    _optionsEditedInDirective = false

    _scopeContext = scopeContext(scope, attrs)

    _enableHandle = (handle) ->
      handle.handler.enable()
      scope.enabled = true
      _currentHandler = handle.handler

    angular.extend scope,
      button: _scopeContext 'button'
      span: _scopeContext 'span'
      drawContexts: drawContexts[attrs.id] or drawContexts


    if !leafletData
      throw new Error 'ui-leaflet is not loaded'

    unless scope.mappromise
      throw new Error 'mappromise required'

    scope.mappromise.then (map) ->

      _create = () ->

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

        drawModeHandles = drawControl._toolbars.draw.getModeHandlers(map)
        editModeHandles = drawControl._toolbars.edit?.getModeHandlers(map)

        handles = {}
        for handleName, legacyHandle of drawModeHandles
          do (handleName, legacyHandle) ->
            handles[getEventName(attrs.id, handleName)] = (event) ->
              _enableHandle legacyHandle, scope

        handles[getEventName(attrs.id, 'pen')] = (event) ->
          #kick off free draw
        handles[getEventName(attrs.id, 'text')] = (event) ->
          #kick off something that puts text on map
        handles[getEventName(attrs.id, 'redo')] = (event) ->
          #pull out of drawItems cache and put it back on the map
        handles[getEventName(attrs.id, 'undo')] = (event) ->
          #pull out of drawItems cache and put it back on the map
        handles[getEventName(attrs.id, 'trash')] = (event) ->
          _enableHandle editModeHandles?.remove, scope

        leafletIterators.each handles, (handle, eventName) ->
          do (eventName, handle) ->
            scope.$on eventName, handle

        if scope.events
          leafletIterators.each scope.events, (handle, eventName) ->
            map.on eventName, handle

        scope.disable = () ->
          _currentHandler?.disable()
          scope.enabled = false

        scope.$watch 'enabled', (newVal) ->
          if newVal == false
            scope.disable()

        scope.$on '$destroy', ->
          scope.disable()
          if scope.events
            leafletIterators.each scope.events, (handle, eventName) ->
              map.off eventName, handle

      _create()
