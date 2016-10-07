###globals L, angular###
app = require '../../app.coffee'
template = require './leafletDraw.jade'
LeafletDrawApi = require './api.draw.js'

app.directive 'rmapsLeafletDraw', (
$log
$timeout
$q
leafletData
leafletIterators
rmapsLeafletDrawDirectiveCtrlDefaultsService
) ->

  errorHeader = "rmapsLeafletDraw"

  {drawContexts, scopeContext} = rmapsLeafletDrawDirectiveCtrlDefaultsService

  $log = $log.spawn('rmapsLeafletDraw')

  setUpNgShow = ({attrs, scope, map, featureGroup}) ->
    if attrs.hasOwnProperty("ngShow")
      ngShow = (newVal) ->
        if newVal == true
          if !map.hasLayer(featureGroup)
            map.addLayer(featureGroup)
          return

        if newVal == false
          if map.hasLayer(featureGroup)
            map.removeLayer(featureGroup)

      scope.$watch('ngShow', ngShow)
      $timeout ngShow

  scope:
    mappromise: '='
    options: '=?'
    events: '=?'
    enabled: '=?'
    ngShow: '=?'

  template: template()
  replace: false
  restrict: 'C'
  # require: ['leaflet']
  link: (scope, element, attrs) ->
    _featureGroup = _deferred = _currentHandler = undefined
    _optionsEditedInDirective = false

    _scopeContext = scopeContext(scope, attrs)

    angular.extend scope,
      button: _scopeContext 'button'
      span: _scopeContext 'span'
      drawContexts: drawContexts[attrs.id] or drawContexts


    if !leafletData
      throw new Error 'ui-leaflet is not loaded'

    if !scope.mappromise
      throw new Error 'mappromise required'

    scope.mappromise.then (map) ->

      _attachEvents = () ->
        return if !scope.events

        events = {}
        # listen on draw:created to disable once creation is done (hide cancel button)
        ['draw:created', 'draw:drawstop'].forEach (eventName) ->
          origEvent = {}
          origEvent[eventName] = scope.events[eventName]

          #extending a new object as to not cause a digest on scope.events (direct override)
          angular.extend events, scope.events,
            "#{eventName}": (opts) ->
              scope.disable()
              origEvent[eventName](opts)

        leafletIterators.each events, (handle, eventName) ->
          map.on eventName, handle

      _cleanUpEvents = (events) ->
        return if !events

        leafletIterators.each events, (handle, eventName) ->
          map.off eventName

      scope.$watchCollection 'events', (newVal, oldVal) ->
        _cleanUpEvents(oldVal)
        _attachEvents()

      _create = () ->
        _deferred = $q.defer()

        return if _optionsEditedInDirective

        options = scope.options or {}

        if !L.Control.Draw?
          $log.error "#{errorHeader} Leaflet.Draw is not loaded as a plugin."
          return

        if !options?.edit? or !options?.edit?.featureGroup?
          _optionsEditedInDirective = true
          options.edit = featureGroup: new L.FeatureGroup()

          $timeout -> _optionsEditedInDirective = false #skip extra digest due to above mod

        _featureGroup = options.edit.featureGroup

        map.addLayer(_featureGroup)

        setUpNgShow {attrs, scope, featureGroup: _featureGroup, map}

        drawControl = new LeafletDrawApi options
        drawControl.onAdd map

        drawModeHandles = drawControl._toolbars.draw.getModeHandlers(map)
        editModeHandles = drawControl._toolbars.edit?.getModeHandlers(map)

        enableHandle = ({handle, handleName, event, options}) ->
          scope.disable() #never have more than one active handle

          if typeof(handle) == 'string'
            handleName ?= handle
            handle = drawModeHandles[handle] || editModeHandles[handle]

          handle.handler.enable(event, options)
          scope.enabled = true
          scope.activeHandle = handleName
          _currentHandler = handle.handler

        if options.control?
          options.control _deferred.promise

          _deferred.resolve {enableHandle}

        ###eslint-disable###
        for handleName, legacyHandle of drawModeHandles
          do (handleName, legacyHandle) ->
            scope['clicked' + handleName.toInitCaps()] = (event, options) ->
              enableHandle {handle: legacyHandle, handleName, event, options}

        scope.clickedEdit = (event, options) ->
          enableHandle {
            handle: editModeHandles?.edit
            handleName: 'edit'
            event
            options
          }
          scope.canSave = true

        scope.clickedTrash = (event) ->
          enableHandle {
            handle: editModeHandles?.remove
            handleName: 'delete'
            event
            options
          }
          scope.canSave = true

        ###eslint-enable###

        _attachEvents()

        scope.disable = () ->
          if _currentHandler?.type == 'edit' || _currentHandler?.type == 'remove'
            _currentHandler.revertLayers()
          _currentHandler?.disable()
          scope.enabled = false
          scope.canSave = false
          scope.activeHandle = null
          scope.$evalAsync()

        scope.$watch 'enabled', (newVal) ->
          if !newVal
            scope.disable()

        scope.save = () ->
          _currentHandler.save()
          scope.canSave = false

        scope.$on '$destroy', ->
          scope.disable()

          if _featureGroup
            map.removeLayer _featureGroup

            _cleanUpEvents(scope.events)

          drawControl?.onRemove()
          drawControl = null

      _create()
