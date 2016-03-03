###globals L, angular###
app = require '../../app.coffee'
template = require './leafletDraw.jade'
LeafletDrawApi = require './api.draw.js'

app.directive 'rmapsLeafletDraw', ($log, leafletData, leafletDrawEvents, $timeout, leafletIterators,
rmapsLeafletDrawDirectiveCtrlDefaultsService) ->

  errorHeader = "rmapsLeafletDraw"

  {drawContexts, scopeContext} = rmapsLeafletDrawDirectiveCtrlDefaultsService

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

      _attachEvents = () ->
        return if !scope.events

        leafletIterators.each scope.events, (handle, eventName) ->
          map.on eventName, handle

      _cleanUpEvents = (events) ->
        return if !events

        leafletIterators.each events, (handle, eventName) ->
          map.off eventName

      scope.$watchCollection 'events', (newVal, oldVal) ->
        _cleanUpEvents(oldVal)
        _attachEvents()

      _create = () ->

        return if _optionsEditedInDirective

        options = scope.options or {}

        if options.control?.promises?
          options.control.promised _deferred.promise

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
        drawControl.onAdd map

        drawModeHandles = drawControl._toolbars.draw.getModeHandlers(map)
        editModeHandles = drawControl._toolbars.edit?.getModeHandlers(map)

        for handleName, legacyHandle of drawModeHandles
          do (handleName, legacyHandle) ->
            scope['clicked' + handleName.toInitCaps()] = (event) ->
              _enableHandle legacyHandle, scope

        scope.clickedPen = (event) ->
          #kick off free draw
        scope.clickedText = (event) ->
          #kick off something that puts text on map
        scope.clickedRedo = (event) ->
          #pull out of drawItems cache and put it back on the map
        scope.clickedUndo = (event) ->
          #pull out of drawItems cache and put it back on the map

        scope.clickedEdit = (event) ->
          _enableHandle editModeHandles?.edit, scope
          scope.canSave = true

        scope.clickedTrash = (event) ->
          _enableHandle editModeHandles?.remove, scope
          scope.canSave = true

        _attachEvents()

        scope.disable = () ->
          _currentHandler?.disable()
          scope.enabled = false
          scope.canSave = false

        scope.$watch 'enabled', (newVal) ->
          if newVal == false
            scope.disable()

        scope.save = () ->
          _currentHandler.save()
          scope.canSave = false

        scope.$on '$destroy', ->
          scope.disable()

          if _featureGroup
            map.removeLayer _featureGroup

            _cleanUpEvents()

          drawControl?.onRemove()
          drawControl = null

      _create()
