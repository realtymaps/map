app = require '../app.coffee'

app.service 'rmapsCurrentMapService', () ->
  # This service keeps track of active map instance and id reference.
  # A new id and instance are needed each time a new one is created since it takes time for
  #   a stale reference to $destroy while we're actively using the active instance
  # Note: currently the burden of using this service for acquiring ID and saving as current
  #   instance rests on the map factory constructor

  _mainMapBase = 'mainMap'
  _mainMapIndex = 0
  _currentMainMap = null
  _getId = () ->
    return _mainMapBase + _mainMapIndex
  _incr = () ->
    _mainMapIndex += 1

  service =
    set: (map) ->
      _currentMainMap = map
    get: () ->
      _currentMainMap

    makeNewMapId: () ->
      _incr()
      return _getId()

    mainMapId: () ->
      return _getId()

  service