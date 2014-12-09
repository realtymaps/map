frontendRoutes = require '../../../common/config/routes.frontend.coffee'
app = require '../app.coffee'
qs = require 'qs'

module.exports = app.factory 'RedirectInterceptor'.ourNs(), [ '$location', '$rootScope',
  ($location, $rootScope) ->
    'response': (response) ->
      if response.data?.doLogin and $location.path() != frontendRoutes.login
        $rootScope.principal?.setIdentity()
        $location.url frontendRoutes.login+'?'+qs.stringify(next: $location.path()+'?'+qs.stringify($location.search()))
      response
]
.config ['$httpProvider', ($httpProvider) ->
  $httpProvider.interceptors.push 'RedirectInterceptor'.ourNs()
]
