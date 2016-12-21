app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsPricingService', (
  $log,
  $http
) ->
  $log = $log.spawn 'mail:rmapsPricingService'

  getMailPricings: () ->
    $http.get backendRoutes.prices.mail, cache: true
    .then ({data}) ->
      data
