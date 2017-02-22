app = require '../app.coffee'
###
  By default we are going to assume that all events are enabled. there fore this gate is a blackList.
###

domainName = 'NgLeafletEventGate'
app.service 'rmapsNgLeafletEventGateService', (nemSimpleLogger, rmapsMapEventEnums) ->
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

  getEvent = (mapId, eventName) ->
    _getMap(mapId)[eventName]

  enableEvent = (mapId, eventName) ->
    _getMap(mapId)[eventName] = false

  disableEvent =  (mapId, eventName) ->
    _getMap(mapId)[eventName] = true

  {
    disableEvent
    enableEvent
    getEvent
    isDisabledEvent: getEvent

    disableMapCommonEvents: (mapId) ->
      disableEvent(mapId, rmapsMapEventEnums.map.click)
      disableEvent(mapId, rmapsMapEventEnums.marker.click)
      disableEvent(mapId, rmapsMapEventEnums.geojson.click)
      disableEvent(mapId, rmapsMapEventEnums.window.mouseover)

    enableMapCommonEvents: (mapId) ->
      enableEvent(mapId, rmapsMapEventEnums.map.click)
      enableEvent(mapId, rmapsMapEventEnums.marker.click)
      enableEvent(mapId, rmapsMapEventEnums.geojson.click)
      enableEvent(mapId, rmapsMapEventEnums.window.mouseover)
  }
