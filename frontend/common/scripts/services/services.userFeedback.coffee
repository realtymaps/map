mod = require '../module.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
require '../../../../common/extensions/strings.coffee'

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


[
  'userFeedback'
  'userFeedbackCategory'
  'userFeedbackSubcategory'
].forEach (route) ->

  svcName = "rmaps#{route.toInitCaps(false)}Service"

  mod.service svcName, [ "Restangular", "$log", (Restangular, $log) ->
    $log = $log.spawn(svcName)

    {apiBase} = backendRoutes[route]

    if !apiBase
      $log.error "#{svcName} apiBase is undefined!"

    _init = () ->
      Restangular.all(apiBase)

    get = (filters = {}) ->
      _init().getList(filters)


    {
      get
    }
]
