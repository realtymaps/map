frontendRoutes = require '../../../common/config/routes.frontend.coffee'
app = require '../app.coffee'
qs = require 'qs'
httpStatus = require '../../../common/utils/httpStatus.coffee'

app.factory 'RedirectInterceptor'.ourNs(), [ '$location', '$rootScope',
  ($location, $rootScope) ->
    'response': (response) ->
      if response.data?.doLogin and $location.path() != '/'+frontendRoutes.login
        $rootScope.principal?.unsetIdentity()
        $location.url frontendRoutes.login+'?'+qs.stringify(next: $location.path()+'?'+qs.stringify($location.search()))
      response
]
.config ['$httpProvider', ($httpProvider) ->
  $httpProvider.interceptors.push 'RedirectInterceptor'.ourNs()
]

app.factory 'AlertInterceptor'.ourNs(), [ '$rootScope', 'events'.ourNs(),
  ($rootScope, Events) ->
    handle = (response) ->
      if response.data?.alert?
        if !response.data?.alert
          # alert is a falsy value, that means we're explicitly not supposed to show an alert
          return response
        # yay!  the backend wants us to show an alert!
        $rootScope.$emit Events.alert.spawn, response.data?.alert
      return response
    'response': handle
    'responseError': handle
]
.config ['$httpProvider', ($httpProvider) ->
  $httpProvider.interceptors.push 'AlertInterceptor'.ourNs()
]
