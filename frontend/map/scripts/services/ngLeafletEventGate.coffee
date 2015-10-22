app = require '../app.coffee'
###
  By default we are going to assume that all events are enabled. there fore this gate is a blackList.
###
app.service 'rmapsNgLeafletEventGate', (nemSimpleLogger) ->
  $log = nemSimpleLogger.spawn("map:NgLeafletEventGate")
  _disabledEvents = {}

  _getMap = (mapId) ->
    if !_disabledEvents[mapId]
      _disabledEvents[mapId] = {}
    _disabledEvents[mapId]

  _getEvent = (mapId, eventName) ->
    _getMap(mapId)[eventName]

  disableEvent: (mapId, eventName) ->
    _getMap(mapId)[eventName] = true

  enableEvent: (mapId, eventName) ->
    delete _getMap(mapId)[eventName]

  getEvent: _getEvent

  isDisabledEvent: _getEvent
