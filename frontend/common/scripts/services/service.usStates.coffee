mod = require '../module.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
apiBase = backendRoutes.us_states.root

mod.service 'rmapsUsStates', ($log, $http, $q) ->
  $log = $log.spawn("common:rmapsUsStates")

  _stateData = {}
  _stateDataById = {}

  _getStates = () ->
    $http.get(apiBase).then ({data}) ->
      _stateData = data
      for state in _stateData
        _stateDataById[state.id] = state
      _stateData


  ##### PUBLIC
  getById: (id) ->
    if Object.keys(_stateDataById).length == 0
      return _getStates().then () ->
        _stateDataById[id]
    return $q.when(_stateDataById[id])

  getAll: () ->
    if Object.keys(_stateData).length == 0
      return _getStates()
    return $q.when(_stateData)
