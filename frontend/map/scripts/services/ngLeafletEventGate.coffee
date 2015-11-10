app = require '../app.coffee'
###
  By default we are going to assume that all events are enabled. there fore this gate is a blackList.
###

domainName = 'NgLeafletEventGate'
app.service 'rmaps' + domainName, (nemSimpleLogger, rmapsMapEventEnums) ->
  $log = nemSimpleLogger.spawn("map:#{domainName}")
  _disabledEvents = {}

  _throwOnEmptyId = (mapId) ->
    unless mapId?
      $log.error "#{domainName}: mapId required!"
      throw new Error "#{domainName}: mapId required!"

  _getMap = (mapId) ->
    _throwOnEmptyId(mapId)
    if !_disabledEvents[mapId]
      _disabledEvents[mapId] = {}
    _disabledEvents[mapId]

  _getEvent = (mapId, eventName) ->
    _getMap(mapId)[eventName]

  _enableEvent = (mapId, eventName) ->
    delete _getMap(mapId)[eventName]

  _disableEvent =  (mapId, eventName) ->
    _getMap(mapId)[eventName] = true

  disableEvent: _disableEvent
  enableEvent: _enableEvent
  getEvent: _getEvent
  isDisabledEvent: _getEvent

  disableMapCommonEvents: (mapId) ->
    _disableEvent(mapId, rmapsMapEventEnums.map.click)
    _disableEvent(mapId, rmapsMapEventEnums.marker.click)
    _disableEvent(mapId, rmapsMapEventEnums.geojson.click)
    _disableEvent(mapId, rmapsMapEventEnums.window.mouseover)

  enableMapCommonEvents: (mapId) ->
    _enableEvent(mapId, rmapsMapEventEnums.map.click)
    _enableEvent(mapId, rmapsMapEventEnums.marker.click)
    _enableEvent(mapId, rmapsMapEventEnums.geojson.click)
    _enableEvent(mapId, rmapsMapEventEnums.window.mouseover)
