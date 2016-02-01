app = require '../app.coffee'
###
  By default we are going to assume that all events are enabled. there fore this gate is a blackList.
###

domainName = 'NgLeafletEventGate'
app.service 'rmaps' + domainName, (nemSimpleLogger, rmapsMapFactoryEventEnums) ->
  $log = nemSimpleLogger.spawn("frontend:map:#{domainName}")
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
    _disableEvent(mapId, rmapsMapFactoryEventEnums.map.click)
    _disableEvent(mapId, rmapsMapFactoryEventEnums.marker.click)
    _disableEvent(mapId, rmapsMapFactoryEventEnums.geojson.click)
    _disableEvent(mapId, rmapsMapFactoryEventEnums.window.mouseover)

  enableMapCommonEvents: (mapId) ->
    _enableEvent(mapId, rmapsMapFactoryEventEnums.map.click)
    _enableEvent(mapId, rmapsMapFactoryEventEnums.marker.click)
    _enableEvent(mapId, rmapsMapFactoryEventEnums.geojson.click)
    _enableEvent(mapId, rmapsMapFactoryEventEnums.window.mouseover)
