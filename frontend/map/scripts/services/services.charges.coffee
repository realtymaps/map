app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
apiBase = backendRoutes.charges

app.service 'rmapsChargesService', ($http, $log) ->
  $log = $log.spawn("payment:rmapsChargesService")

  get: (entity) ->
    $http.get apiBase.getHistory, entity
    .then ({data}) ->
      _.filter data.data, (obj) ->
        obj.amount = obj.amount / 100
        obj.created = new Date(obj.created * 1000).toLocaleDateString() #conv epoch to milliseconds & get local date
        obj.type = if obj.refunded then "Refund" else "Charge"
        obj.instrument = obj.source.last4
