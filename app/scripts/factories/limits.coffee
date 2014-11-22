###
User service to get current and fetch additional about the user
###
app = require '../app.coffee'
require '../services/httpStatus.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'

module.exports =
  app.factory 'Limits'.ourNs(), [
    '$q', '$http', 'HttpStatus'.ourNs()
    ($q, $http, httpStatus) =>
      # map option from the user info via cookie or service ?
      d = $q.defer()

      promise = $http.get(backendRoutes.limits)
      promise.then (data) ->
        unless httpStatus.isWithinOK data.status
          d.reject new Error 'Bad Response from Server'
        d.resolve data.data
      .catch (e) ->
        d.reject e
      d.promise
  ]
