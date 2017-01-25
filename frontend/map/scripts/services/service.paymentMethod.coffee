app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
apiBase = backendRoutes.paymentMethod

# "sources" are tokens generated from stripe.js, and encapsulate
#   sensitive data for any kind of account, such as creditcard, bank, etc.
# Thus, this service would handle setting and getting sources
#   regardless of type.
app.service 'rmapsPaymentMethodService', ($http, $log) ->
  $log = $log.spawn("payment:rmapsPaymentMethodService")

  getAll: (config) ->
    $http.getData(apiBase.root, config)

  getDefault: (config) ->
    $http.getData(apiBase.getDefault, config)

  # If appending sources is desired, a new operator (like 'append' or 'add') and flow through backend
  #   may be required.
  replace: (source, config) ->
    $http.putData(apiBase.replaceDefault.replace(':source', source), {}, config)

  add: (source, config) ->
    $http.postData(apiBase.add.replace(':source', source),{}, config)

  setDefault: (source, config) ->
    $http.putData(apiBase.setDefault.replace(':source', source),{}, config)

  remove: (source, config) ->
    $http.deleteData(apiBase.remove.replace(':source', source),{}, config)
