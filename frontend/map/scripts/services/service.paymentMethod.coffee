app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
apiBase = backendRoutes.paymentMethod

# "sources" are tokens generated from stripe.js, and encapsulate
#   sensitive data for any kind of account, such as creditcard, bank, etc.
# Thus, this service would handle setting and getting sources
#   regardless of type.
app.service 'rmapsPaymentMethodService', ($http, $log) ->
  $log = $log.spawn("payment:rmapsPaymentMethodService")

  getDefaultSource: () ->
    $http.get apiBase.getDefaultSource
    .then ({data}) ->
      data

  # If appending sources is desired, a new operator (like 'append' or 'add') and flow through backend
  #   may be required.
  replace: (source) ->
    $http.put apiBase.replaceDefaultSource.replace ':source', source
    .then ({data}) ->
      data