app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsGeoLocations', ($log, $http, $q) ->
  $log = $log.spawn("map:rmapsGeoLocations")

  _stateData = {}

  _stateDataById = {}

  _getStates = () ->
    $http.get(backendRoutes.us_states.root)
    .then ({data}) ->
      _stateData = data
      for state in _stateData
        _stateDataById[state.id] = state
      _stateData


  ##### PUBLIC
  getState: (id) ->
    if Object.keys(_stateDataById).length == 0
      return _getStates().then () ->
        _stateDataById[id]
    return $q.when(_stateDataById[id])

  states: () ->
    if Object.keys(_stateData).length == 0
      return _getStates()
    return $q.when(_stateData)
