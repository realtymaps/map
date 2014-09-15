###
User service to get current and fetch additional about the user
###
app = require '../app.coffee'
routes = require '../../../common/config/routes.coffee'

module.exports =
  app.factory 'Limits'.ourNs(), [ '$http', ($http) =>
    # map option from the user info via cookie or service ?
    $http.get(routes.limits)
  ]
