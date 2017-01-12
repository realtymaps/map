mod = require '../module.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

mod.service 'rmapsUserSessionHistoryService',
($http, $log, $rootScope) ->
  $log = $log.spawn("rmapsUserSessionHistoryService")

  apiBase = backendRoutes.userSession.feedback

  if !apiBase
    $log.error "rmapsUserSessionHistoryService apiBase is undefined!"

  getAll = () ->
    $http.getData(apiBase)

  save = (entity) ->
    $http.post(apiBase, entity)

  {
    getAll
    save
  }


mod.service 'rmapsUserHistoryService', (Restangular, $log) ->
  $log = $log.spawn("rmapsUserHistoryService")

  {apiBase} = backendRoutes.historyUser

  if !apiBase
    $log.error "rmapsUserHistoryService apiBase is undefined!"

  _init = () ->
    Restangular.all(apiBase)

  get = (filters = {}) ->
    _init().getList(filters)


  {
    get
  }
